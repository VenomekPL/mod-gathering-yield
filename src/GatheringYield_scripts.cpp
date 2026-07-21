#include "ScriptMgr.h"
#include "Config.h"
#include "Log.h"

class GatheringYield_World : public WorldScript
{
public:
    GatheringYield_World() : WorldScript("GatheringYield_World") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        uint32 mult = sConfigMgr->GetOption<uint32>("GatheringYield.Multiplier", 3);
        if (mult)
            LOG_INFO("server.loading", "GatheringYield: module present ({}x yields via SQL)", mult);
    }
};

void AddGatheringYieldScripts()
{
    new GatheringYield_World();
}
