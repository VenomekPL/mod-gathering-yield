#include "ScriptMgr.h"
#include "Config.h"
#include "DBCStores.h"
#include "GameObject.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "SharedDefines.h"

#include <algorithm>
#include <cstdlib>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
    // Fishing trunks and crates stay at vanilla counts.
    bool IsFishingContainer(uint32 itemId)
    {
        switch (itemId)
        {
            case 6351:
            case 6352:
            case 6357:
            case 13874:
            case 20708:
            case 21113:
            case 21150:
            case 21228:
            case 27513:
            case 44475:
                return true;
            default:
                return false;
        }
    }

    uint32 LootMultiplier()
    {
        uint32 mult = sConfigMgr->GetOption<uint32>("GatheringYield.Multiplier", 3);
        return mult ? mult : 1;
    }

    uint32 DailyTokenMultiplier()
    {
        uint32 mult = sConfigMgr->GetOption<uint32>("GatheringYield.DailyTokenMultiplier", 3);
        return mult ? mult : 1;
    }

    bool LockRequiresGathering(uint32 lockId)
    {
        LockEntry const* lock = sLockStore.LookupEntry(lockId);
        if (!lock)
            return false;

        for (uint8 i = 0; i < MAX_LOCK_CASE; ++i)
        {
            if (lock->Type[i] == LOCKTYPE_HERBALISM || lock->Type[i] == LOCKTYPE_MINING
                || lock->Type[i] == LOCKTYPE_FISHING)
                return true;
        }
        return false;
    }

    // Mining and herbalism nodes, fishing (open water and schools), skinning,
    // gas clouds (Extract Gas uses skinning loot), and elemental extraction
    // (mine/herb/engineer creatures, also skinning loot).
    bool IsGatheringLoot(Loot const& loot, LootStore const& store)
    {
        if (&store == &LootTemplates_Skinning || &store == &LootTemplates_Fishing)
            return true;

        if (&store != &LootTemplates_Gameobject || !loot.sourceGameObject)
            return false;

        GameObjectTemplate const* info = loot.sourceGameObject->GetGOInfo();
        if (!info)
            return false;

        if (info->type == GAMEOBJECT_TYPE_FISHINGHOLE)
            return true;

        return info->type == GAMEOBJECT_TYPE_CHEST && LockRequiresGathering(info->GetLockId());
    }

    struct ScaledCount
    {
        uint8 mincount;
        uint8 maxcount;
        uint32 applied;
    };

    std::mutex s_scaleMutex;
    std::unordered_map<LootStoreItem*, ScaledCount> s_scaledCounts;
    // While expanding a mining/herb gem reference, keep gem stack sizes vanilla
    // and multiply the number of rolls instead.
    thread_local int s_suppressCountScale = 0;

    void ApplyCount(LootStoreItem* item, uint8 origMin, uint8 origMax, uint32 mult)
    {
        // Keep the stock minimum. Only the top of the range is multiplied,
        // so a 1–3 node at 10x becomes 1–30, not 10–30.
        uint32 maxcount = std::min<uint32>(uint32(origMax) * mult, 255u);
        if (maxcount < origMin)
            maxcount = origMin;

        item->mincount = origMin;
        item->maxcount = uint8(maxcount);
    }

    void ScaleItemCount(LootStoreItem* item, uint32 mult)
    {
        if (!item || IsFishingContainer(item->itemid))
            return;

        if (!mult)
            mult = 1;

        std::lock_guard<std::mutex> guard(s_scaleMutex);
        auto itr = s_scaledCounts.find(item);
        if (itr == s_scaledCounts.end())
        {
            if (mult <= 1)
                return;

            uint8 origMin = item->mincount;
            uint8 origMax = item->maxcount;
            s_scaledCounts.emplace(item, ScaledCount{ origMin, origMax, mult });
            ApplyCount(item, origMin, origMax, mult);
            return;
        }

        if (itr->second.applied == mult)
            return;

        if (mult <= 1)
        {
            item->mincount = itr->second.mincount;
            item->maxcount = itr->second.maxcount;
        }
        else
            ApplyCount(item, itr->second.mincount, itr->second.maxcount, mult);

        itr->second.applied = mult;
    }

    bool IsCurrencyToken(uint32 itemId)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId);
        return proto && proto->IsCurrencyToken();
    }

    struct TokenBaseline
    {
        uint32 questId;
        uint8 index;
        bool choice;
        uint32 count;
    };

    std::vector<TokenBaseline> s_tokenBaselines;
    bool s_tokenBaselinesReady = false;

    void CaptureTokenBaselines()
    {
        s_tokenBaselines.clear();
        for (auto const& itr : sObjectMgr->GetQuestTemplates())
        {
            Quest const* quest = itr.second;
            if (!quest || !quest->IsDaily())
                continue;

            for (uint8 i = 0; i < QUEST_REWARDS_COUNT; ++i)
            {
                if (quest->RewardItemId[i] && quest->RewardItemIdCount[i] && IsCurrencyToken(quest->RewardItemId[i]))
                    s_tokenBaselines.push_back({ quest->GetQuestId(), i, false, quest->RewardItemIdCount[i] });
            }

            for (uint8 i = 0; i < QUEST_REWARD_CHOICES_COUNT; ++i)
            {
                if (quest->RewardChoiceItemId[i] && quest->RewardChoiceItemCount[i]
                    && IsCurrencyToken(quest->RewardChoiceItemId[i]))
                    s_tokenBaselines.push_back({ quest->GetQuestId(), i, true, quest->RewardChoiceItemCount[i] });
            }
        }
        s_tokenBaselinesReady = true;
    }

    void ApplyDailyTokenRewards()
    {
        if (sObjectMgr->GetQuestTemplates().empty())
            return;

        if (!s_tokenBaselinesReady)
            CaptureTokenBaselines();

        uint32 mult = DailyTokenMultiplier();
        std::unordered_map<uint32, Quest*> touched;

        for (TokenBaseline const& baseline : s_tokenBaselines)
        {
            Quest* quest = const_cast<Quest*>(sObjectMgr->GetQuestTemplate(baseline.questId));
            if (!quest)
                continue;

            uint32 scaled = baseline.count * mult;
            if (baseline.choice)
                quest->RewardChoiceItemCount[baseline.index] = scaled;
            else
                quest->RewardItemIdCount[baseline.index] = scaled;

            touched.emplace(quest->GetQuestId(), quest);
        }

        for (auto const& itr : touched)
            itr.second->InitializeQueryData();
    }
}

class GatheringYield_World : public WorldScript
{
public:
    GatheringYield_World() : WorldScript("GatheringYield_World") { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            ApplyDailyTokenRewards();

        LOG_INFO("server.loading",
            "GatheringYield: loot x{} (mine/herb/fish/skin, gas clouds, elemental extraction); daily tokens x{}",
            LootMultiplier(), DailyTokenMultiplier());
    }

    void OnStartup() override
    {
        ApplyDailyTokenRewards();
        LOG_INFO("server.loading", "GatheringYield: scaled currency tokens on {} daily quest reward slots",
            s_tokenBaselines.size());
    }
};

class GatheringYield_Loot : public GlobalScript
{
public:
    GatheringYield_Loot() : GlobalScript("GatheringYield_Loot") { }

    void OnAfterRefCount(Player const* player, LootStoreItem* item, Loot& loot, bool /*canRate*/, uint16 lootMode,
        uint32& maxcount, LootStore const& store) override
    {
        // Gem tables on veins/herbs were tripled by rolling the reference extra times.
        // Fishing and skinning references were tripled on the item stacks instead.
        if (!item || !item->reference || &store != &LootTemplates_Gameobject || !IsGatheringLoot(loot, store))
            return;

        uint32 mult = LootMultiplier();
        if (mult <= 1)
            return;

        LootTemplate const* referenced = LootTemplates_Reference.GetLootFor(std::abs(item->reference));
        if (!referenced)
            return;

        uint32 rolls = maxcount * mult;
        maxcount = 0;
        if (!rolls)
            return;

        ++s_suppressCountScale;
        for (uint32 i = 0; i < rolls; ++i)
            referenced->Process(loot, store, lootMode, player, 0, false);
        --s_suppressCountScale;
    }

    void OnBeforeDropAddItem(Player const* /*player*/, Loot& loot, bool /*canRate*/, uint16 /*lootMode*/,
        LootStoreItem* item, LootStore const& store) override
    {
        if (s_suppressCountScale || !item || !IsGatheringLoot(loot, store))
            return;

        ScaleItemCount(item, LootMultiplier());
    }
};

void AddGatheringYieldScripts()
{
    new GatheringYield_World();
    new GatheringYield_Loot();
}
