-- Restore gathering loot counts to vanilla so GatheringYield.Multiplier (default 3)
-- is the only scale. Earlier module SQL multiplied MinCount/MaxCount by 3 in the database.
-- This divides those rows back. Runtime code applies the configured multiplier.
-- Idempotent guard: only rows still divisible by 3 and at least 3 are touched.
-- Fishing trunks/crates are left alone. Reload loot after apply.

-- Mining / herbalism nodes (same name set as the original triple) and fishing schools.
UPDATE gameobject_loot_template glt
JOIN (
    SELECT DISTINCT Data1 AS lootid
    FROM gameobject_template
    WHERE Data1 > 0
      AND (
          (
              type = 3
              AND name NOT REGEXP 'Chest|Box of Mushrooms'
              AND name REGEXP 'Vein|Deposit|bloom|root|Lotus|Kelp|Mushroom|Grass|Herb|Bush|Thistle|Swamp|Sungrass|Silversage|Plaguebloom|Icecap|Terocone|Netherbloom|Felweed|Ragveil|Lichen|Goldclover|Tiger Lily|Talandra|Lichbloom|Icethorn|Frost Lotus|Ooze Covered|Incendicite|Indurium|Saronite|Titanium|Cobalt|Adamantite|Khorium|Truesilver|Mithril|Thorium|Rich |Peacebloom|Earthroot|Fadeleaf|Khadgar|Wintersbite|Dreamfoil|Mountain Silversage|Dragonscale|Golden Sansam|Blindweed|Ghost Mushroom|Gromsblood|Arthas|Wild Steelbloom|Grave Moss|Kingsblood|Liferoot|Briarthorn|Bruiseweed|Silverleaf|Mageroyal|Swiftthistle|Firebloom|Purple Lotus|Blood of Heroes'
          )
          OR type = 25
      )
) nodes ON glt.Entry = nodes.lootid
SET glt.MinCount = glt.MinCount / 3,
    glt.MaxCount = glt.MaxCount / 3
WHERE glt.MinCount >= 3
  AND glt.MaxCount >= 3
  AND glt.MinCount % 3 = 0
  AND glt.MaxCount % 3 = 0
  AND glt.Item NOT IN (20708, 21113, 21150, 21228, 6351, 6352, 6357, 13874, 27513, 44475);

-- Open-water fishing item stacks.
UPDATE fishing_loot_template
SET MinCount = MinCount / 3,
    MaxCount = MaxCount / 3
WHERE Reference = 0
  AND Item > 0
  AND MinCount >= 3
  AND MaxCount >= 3
  AND MinCount % 3 = 0
  AND MaxCount % 3 = 0
  AND Item NOT IN (20708, 21113, 21150, 21228, 6351, 6352, 6357, 13874, 27513, 44475);

-- Skinning, including gas clouds (80200-80206) and elemental extraction tables.
UPDATE skinning_loot_template
SET MinCount = MinCount / 3,
    MaxCount = MaxCount / 3
WHERE Reference = 0
  AND Item > 0
  AND MinCount >= 3
  AND MaxCount >= 3
  AND MinCount % 3 = 0
  AND MaxCount % 3 = 0;

-- Referenced stacks used only by fishing or skinning.
UPDATE reference_loot_template rlt
JOIN (
    SELECT DISTINCT Reference AS refId
    FROM fishing_loot_template
    WHERE Reference > 0
    UNION
    SELECT DISTINCT Reference
    FROM skinning_loot_template
    WHERE Reference > 0
) refs ON rlt.Entry = refs.refId
SET rlt.MinCount = rlt.MinCount / 3,
    rlt.MaxCount = rlt.MaxCount / 3
WHERE rlt.MinCount >= 3
  AND rlt.MaxCount >= 3
  AND rlt.MinCount % 3 = 0
  AND rlt.MaxCount % 3 = 0
  AND rlt.Item NOT IN (20708, 21113, 21150, 21228, 6351, 6352, 6357, 13874, 27513, 44475);
