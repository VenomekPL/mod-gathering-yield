# mod-gathering-yield

AzerothCore module that triples mining/herbalism **node** yields and fishing/skinning loot counts (chests/trunks kept at vanilla counts).

## Purpose / scope

| Layer | Role |
|-------|------|
| Module SQL | Multiplies existing `MinCount`/`MaxCount` on gathering loot |
| `GatheringYield.Multiplier` in conf | Documents intended multiplier (SQL baked for **3×**) |
| Core `SkillGain.Gathering = 3` | Companion skill-up rate — set in `worldserver.conf` |

**Warning:** SQL multiplies whatever is already in the DB. Apply once on a clean baseline. A corrective update is included for realms that previously double-applied.

## Configuration

See `conf/gatheringYield.conf.dist`:

| Key | Default | Meaning |
|-----|---------|---------|
| `GatheringYield.Multiplier` | 3 | Documented intended loot multiplier |

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
