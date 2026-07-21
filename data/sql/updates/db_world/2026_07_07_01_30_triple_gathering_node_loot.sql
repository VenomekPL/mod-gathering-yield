-- Triple yields from mining and herbalism world nodes (MinCount/MaxCount).
-- Apply once only (tracked in updates table). Re-applying multiplies again.
-- Reversible: divide by 3. Reload loot after applying: reload all loot

UPDATE gameobject_loot_template glt
JOIN (
    SELECT DISTINCT Data1 AS lootid
    FROM gameobject_template
    WHERE Data1 > 0
      AND name REGEXP 'Vein|Deposit|bloom|root|Lotus|Kelp|Mushroom|Grass|Herb|Bush|Thistle|Swamp|Sungrass|Silversage|Plaguebloom|Icecap|Terocone|Netherbloom|Felweed|Ragveil|Lichen|Goldclover|Tiger Lily|Talandra|Lichbloom|Icethorn|Frost Lotus|Ooze Covered|Incendicite|Indurium|Saronite|Titanium|Cobalt|Adamantite|Khorium|Truesilver|Mithril|Thorium|Rich |Peacebloom|Earthroot|Fadeleaf|Khadgar|Wintersbite|Dreamfoil|Mountain Silversage|Dragonscale|Golden Sansam|Blindweed|Ghost Mushroom|Gromsblood|Arthas|Wild Steelbloom|Grave Moss|Kingsblood|Liferoot|Briarthorn|Bruiseweed|Silverleaf|Mageroyal|Swiftthistle|Firebloom|Purple Lotus|Blood of Heroes|Solid Chest'
) nodes ON glt.Entry = nodes.lootid
SET glt.MinCount = LEAST(glt.MinCount * 3, 255),
    glt.MaxCount = LEAST(glt.MaxCount * 3, 255);
