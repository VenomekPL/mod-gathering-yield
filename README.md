# mod-gathering-yield

AzerothCore module that multiplies gathering yields and daily-quest currency tokens.

Mining, herbalism, fishing, and skinning use `GatheringYield.Multiplier` (default **3**). That includes:

- ore and herb nodes (including nodes the old name list missed, such as Adder's Tongue)
- open-water fishing and fishing schools
- skinning
- gas clouds (Extract Gas)
- elemental extraction (creatures you mine, herb, or salvage with engineering)

World chests, fishing trunks, and fishing crates stay at vanilla drop counts.

Daily quests, including heroic dungeon dailies, grant `GatheringYield.DailyTokenMultiplier` (default **3**) currency tokens: emblems, seals, cooking awards, jewelcrafting tokens, and other items with the currency-token bag family. Gear choices and weekly quests are unchanged.

## Purpose / scope

| Layer | Role |
|-------|------|
| Module SQL | Restores gathering loot counts to vanilla after the old baked ×3 updates |
| `GatheringYield.Multiplier` | Runtime stack-size multiplier for gathering loot |
| `GatheringYield.DailyTokenMultiplier` | Runtime multiplier for daily/heroic-daily currency tokens |
| Core `SkillGain.Gathering` | Companion skill-up rate — set in `worldserver.conf` |

The database stores vanilla counts. Change the conf values and reload (or restart) to retune. Do not re-apply the old triple SQL on top of this.

## Configuration

See `conf/gatheringYield.conf.dist`:

| Key | Default | Meaning |
|-----|---------|---------|
| `GatheringYield.Multiplier` | 3 | Mining, herbalism, fishing, skinning, gas clouds, elemental extraction |
| `GatheringYield.DailyTokenMultiplier` | 3 | Currency tokens from daily and heroic daily quests |

## Install

```bash
cd modules
git submodule add https://github.com/VenomekPL/mod-gathering-yield.git mod-gathering-yield
```

Companion core setting:

```
SkillGain.Gathering = 3
```

## License

AGPL-3.0
