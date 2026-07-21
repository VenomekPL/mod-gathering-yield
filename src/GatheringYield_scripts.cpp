#include "ScriptMgr.h"
#include "Config.h"
#include "Log.h"

class GatheringYield_World : public WorldScript
{
public:
    GatheringYield_World() : WorldScript("GatheringYield_World") { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        // SQL-only module: world updates live under data/sql/. Conf flag is informational.
        bool enabled = sConfigMgr->GetOption<uint32>("GatheringYield.Multiplier", 3) > 0;
        if (enabled)
            LOG_INFO("server.loading", "GatheringYield: module present (SQL updates via module data/sql)");
    }
};

void AddGatheringYieldScripts()
{
    new GatheringYield_World();
}
