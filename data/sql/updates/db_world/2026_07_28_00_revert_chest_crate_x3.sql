-- Revert accidental ×3 MinCount/MaxCount on world chests and fishing crates.
-- Caused by gathering-node REGEXP matching chest names (Solid/Adamantite/Mithril)
-- and fishing triple SQL excluding trunks but not crates.
-- Intentional mining/herb/fish/skin ×3 yields are left unchanged.
-- Idempotent for already-vanilla rows (only touches MinCount/MaxCount >= 3 and divisible by 3).
-- Reload loot after apply: .reload all

-- ---------------------------------------------------------------------------
-- 1) World chests: restore contents to vanilla (divide by 3)
-- ---------------------------------------------------------------------------
UPDATE gameobject_loot_template glt
JOIN (
    SELECT DISTINCT Data1 AS lootid
    FROM gameobject_template
    WHERE Data1 > 0
      AND name REGEXP
          'Solid Chest|Large Solid Chest|Adamantite Bound Chest|Bound Adamantite Chest|Solid Adamantite Chest|Large Mithril Bound Chest|Box of Mushrooms'
) chests ON glt.Entry = chests.lootid
SET glt.MinCount = GREATEST(1, FLOOR(glt.MinCount / 3)),
    glt.MaxCount = GREATEST(1, FLOOR(glt.MaxCount / 3))
WHERE glt.MinCount >= 3
  AND glt.MaxCount >= 3
  AND glt.MinCount % 3 = 0
  AND glt.MaxCount % 3 = 0;

-- ---------------------------------------------------------------------------
-- 2) Fishing crates: restore drop counts to vanilla (divide by 3)
--    Crate item IDs: 6351, 6352, 6357, 13874, 27513, 44475
-- ---------------------------------------------------------------------------
UPDATE reference_loot_template
SET MinCount = GREATEST(1, FLOOR(MinCount / 3)),
    MaxCount = GREATEST(1, FLOOR(MaxCount / 3))
WHERE Item IN (6351, 6352, 6357, 13874, 27513, 44475)
  AND MinCount >= 3
  AND MaxCount >= 3
  AND MinCount % 3 = 0
  AND MaxCount % 3 = 0;

UPDATE fishing_loot_template
SET MinCount = GREATEST(1, FLOOR(MinCount / 3)),
    MaxCount = GREATEST(1, FLOOR(MaxCount / 3))
WHERE Item IN (6351, 6352, 6357, 13874, 27513, 44475)
  AND MinCount >= 3
  AND MaxCount >= 3
  AND MinCount % 3 = 0
  AND MaxCount % 3 = 0;

UPDATE gameobject_loot_template glt
JOIN gameobject_template got ON got.Data1 = glt.Entry AND got.type = 25
SET glt.MinCount = GREATEST(1, FLOOR(glt.MinCount / 3)),
    glt.MaxCount = GREATEST(1, FLOOR(glt.MaxCount / 3))
WHERE glt.Item IN (6351, 6352, 6357, 13874, 27513, 44475)
  AND glt.MinCount >= 3
  AND glt.MaxCount >= 3
  AND glt.MinCount % 3 = 0
  AND glt.MaxCount % 3 = 0;
