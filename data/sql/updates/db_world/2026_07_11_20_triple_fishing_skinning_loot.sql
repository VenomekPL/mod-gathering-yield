-- Triple fishing (open water + schools) and skinning yields (MinCount/MaxCount).
-- Trunks keep vanilla drop counts; trunk contents (item_loot_template) are unchanged.
-- Reverts accidental gathering triple on a few fishing pool loot entries first.
-- Reversible: divide affected rows by 3 (except trunks). Reload loot after apply.

-- Undo gathering-node triple that hit fishing pools / shared loot (restore vanilla counts).
UPDATE gameobject_loot_template glt
SET glt.MinCount = GREATEST(1, FLOOR(glt.MinCount / 3)),
    glt.MaxCount = GREATEST(1, FLOOR(glt.MaxCount / 3))
WHERE glt.Entry IN (17534, 17675)
  AND glt.Item NOT IN (20708, 21113, 21150, 21228);

UPDATE gameobject_loot_template
SET MinCount = GREATEST(1, FLOOR(MinCount / 3)),
    MaxCount = GREATEST(1, FLOOR(MaxCount / 3))
WHERE Entry = 1415;

-- Restore trunk drop counts on fishing pools (leave as vanilla).
UPDATE gameobject_loot_template glt
JOIN gameobject_template got ON got.Data1 = glt.Entry AND got.type = 25
SET glt.MinCount = 1,
    glt.MaxCount = 1
WHERE glt.Item IN (20708, 21113, 21150, 21228)
  AND (glt.MinCount <> 1 OR glt.MaxCount <> 1);

-- Open water fishing: reference tables used only by fishing_loot_template.
UPDATE reference_loot_template rlt
SET rlt.MinCount = LEAST(rlt.MinCount * 3, 255),
    rlt.MaxCount = LEAST(rlt.MaxCount * 3, 255)
WHERE rlt.Entry IN (
    SELECT DISTINCT Reference FROM fishing_loot_template WHERE Reference > 0
)
  AND rlt.Item NOT IN (20708, 21113, 21150, 21228);

-- Open water fishing: direct item rows (no reference).
UPDATE fishing_loot_template flt
SET flt.MinCount = LEAST(flt.MinCount * 3, 255),
    flt.MaxCount = LEAST(flt.MaxCount * 3, 255)
WHERE flt.Item > 0
  AND flt.Reference = 0
  AND flt.Item NOT IN (20708, 21113, 21150, 21228);

-- Fishing schools / pools (gameobject type 25). Skip entries already at vanilla*3 from revert above.
UPDATE gameobject_loot_template glt
JOIN gameobject_template got ON got.Data1 = glt.Entry AND got.type = 25
SET glt.MinCount = LEAST(glt.MinCount * 3, 255),
    glt.MaxCount = LEAST(glt.MaxCount * 3, 255)
WHERE glt.Item NOT IN (20708, 21113, 21150, 21228)
  AND glt.Entry NOT IN (17534, 17675, 1415);

-- Skinning: direct loot rows.
UPDATE skinning_loot_template slt
SET slt.MinCount = LEAST(slt.MinCount * 3, 255),
    slt.MaxCount = LEAST(slt.MaxCount * 3, 255)
WHERE slt.Reference = 0
  AND slt.Item > 0;

-- Skinning: referenced loot tables (skinning-only references).
UPDATE reference_loot_template rlt
SET rlt.MinCount = LEAST(rlt.MinCount * 3, 255),
    rlt.MaxCount = LEAST(rlt.MaxCount * 3, 255)
WHERE rlt.Entry IN (
    SELECT DISTINCT Reference FROM skinning_loot_template WHERE Reference > 0
);
