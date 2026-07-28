# mod-gathering-yield

AzerothCore module that triples mining/herbalism **node** yields and fishing/skinning loot counts.

World chests, fishing trunks, and fishing crates stay at vanilla drop counts (only fish/skin/node yields are ×3).

## Purpose / scope

| Layer | Role |
|-------|------|
| Module SQL | Multiplies existing `MinCount`/`MaxCount` on gathering loot |
| `GatheringYield.Multiplier` in conf | Documents intended multiplier (SQL baked for **3×**) |
| Core `SkillGain.Gathering = 3` | Companion skill-up rate — set in `worldserver.conf` |

**Warning:** SQL multiplies whatever is already in the DB. Apply once on a clean baseline. Corrective updates are included for realms that previously double-applied node loot, or that accidentally ×3'd Solid/Adamantite/Mithril chest contents and fishing crate drop counts (fixed in `2026_07_28_00_revert_chest_crate_x3.sql`).

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
