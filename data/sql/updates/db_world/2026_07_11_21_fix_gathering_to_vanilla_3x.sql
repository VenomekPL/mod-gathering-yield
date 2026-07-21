-- Correct mining/herbalism node yields to exactly 3× vanilla (not 9×).
-- The gathering triple script was applied twice on this realm (MinCount/MaxCount ×3 twice).
-- Rows already at 3× (MinCount < 9) are left unchanged (e.g. Peacebloom 3–9).
-- Reversible: multiply by 3. Reload loot after apply.

UPDATE gameobject_loot_template glt
JOIN (
    SELECT DISTINCT Data1 AS lootid
    FROM gameobject_template
    WHERE Data1 > 0
      AND name REGEXP 'Vein|Deposit|bloom|root|Lotus|Kelp|Mushroom|Grass|Herb|Bush|Thistle|Swamp|Sungrass|Silversage|Plaguebloom|Icecap|Terocone|Netherbloom|Felweed|Ragveil|Lichen|Goldclover|Tiger Lily|Talandra|Lichbloom|Icethorn|Frost Lotus|Ooze Covered|Incendicite|Indurium|Saronite|Titanium|Cobalt|Adamantite|Khorium|Truesilver|Mithril|Thorium|Rich |Peacebloom|Earthroot|Fadeleaf|Khadgar|Wintersbite|Dreamfoil|Mountain Silversage|Dragonscale|Golden Sansam|Blindweed|Ghost Mushroom|Gromsblood|Arthas|Wild Steelbloom|Grave Moss|Kingsblood|Liferoot|Briarthorn|Bruiseweed|Silverleaf|Mageroyal|Swiftthistle|Firebloom|Purple Lotus|Blood of Heroes|Solid Chest'
) nodes ON glt.Entry = nodes.lootid
SET glt.MinCount = GREATEST(1, FLOOR(glt.MinCount / 3)),
    glt.MaxCount = GREATEST(1, FLOOR(glt.MaxCount / 3))
WHERE glt.MinCount >= 9;

-- Pure Saronite was capped at 255 during double-triple; restore exact 3× vanilla ore (22–38 → 66–114).
UPDATE gameobject_loot_template
SET MinCount = 66,
    MaxCount = 114
WHERE Entry = 27244
  AND Item = 36912;
