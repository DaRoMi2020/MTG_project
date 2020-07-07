
--Enchantment function

/**/


CREATE FUNCTION enchantments_function (
	enchantments_limit_v INTEGER, 
	enchantments_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	enchantments_type_exclude TEXT DEFAULT NULL,
	enchantments_type_include TEXT DEFAULT NULL,
	enchantments_sub_exclude TEXT DEFAULT NULL,
	enchantments_sub_include TEXT[] DEFAULT array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'],
	['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']],
	enchantments_super_exclude TEXT DEFAULT NULL,
	enchantments_super_include TEXT[] DEFAULT array[['Legendary'],['Snow'], ['World']])


RETURNS TABLE (card_name TEXT,
	card_id INTEGER,
	card_colors TEXT,
	card_rarity em_rarity,
	card_types TEXT,
	card_subtypes TEXT,
	card_supertypes TEXT,
	card_format em_format,
	card_format_status em_status
	)

AS $T$

BEGIN

RETURN QUERY 

WITH A AS (
SELECT DISTINCT ON 
(cards."name") cards."name", 
cards.id, 
cards.colors,
cards.rarity,
cards.types,
cards.subtypes,
cards.supertypes,
legalities.format, 
legalities.status 
FROM cards 
LEFT OUTER JOIN legalities 
ON cards.uuid = legalities.uuid

WHERE 
((cards.colors::TEXT ILIKE color_v::TEXT) OR (cards.colors::TEXT IS NULL AND color_v::TEXT IS NULL)) AND
cards.rarity = enchantments_rarity_v::em_rarity AND
cards.types::TEXT NOT ILIKE '%Creature%' AND
cards.types::TEXT NOT ILIKE '%Artifact%' AND
cards.types::TEXT NOT ILIKE '%Land%' AND
legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status AND

((enchantments_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Enchantment%' AND cards.types::TEXT ILIKE enchantments_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
	(enchantments_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Enchantment' AND enchantments_type_include::TEXT IS NULL) OR -- Exclude tribal
	(enchantments_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Enchantment%' AND cards.types::TEXT ILIKE enchantments_type_include::TEXT)) AND -- only tribal

((enchantments_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (enchantments_sub_include::TEXT[])) OR --include all choosen including null 
	(enchantments_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND enchantments_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(enchantments_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (enchantments_sub_include::TEXT[]))) AND --exclude nulls

((enchantments_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ~* ANY (enchantments_super_include::TEXT[])) OR --include all choosen including null
	(enchantments_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND enchantments_super_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(enchantments_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ~* ANY (enchantments_super_include::TEXT[]))) --include all choosen and exclude nulls 

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT enchantments_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

SELECT * FROM enchantments_function (1000, 'uncommon', 'legacy', 'Legal', 'B');

SELECT * FROM enchantments_function (1000, 'uncommon', 'legacy', 'Legal', 'B', NULL, NULL, NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'],
	['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']], NULL, array[['Legendary'],['Snow'], ['World']]);

-- includes all enchantment types, includes all subtypes, includes all supertypes (default)

SELECT * FROM enchantments_function (1000, 'uncommon', 'legacy', 'Legal', 'B', NULL, '%Tribal%');

-- includes only tribal enchantments, including only tribal subtypes, includes all supertypes 

SELECT * FROM enchantments_function (1000, 'rare', 'legacy', 'Legal', 'B', NULL, NULL, NULL, NULL, NULL, array[['Legendary']]);

-- Excludes tribal type based on excluding subtype, excludes all subtypes, includes null and legendary supertypes 

SELECT * FROM enchantments_function (1000, 'rare', 'legacy', 'Legal', 'B', NULL, NULL, NULL, NULL, NULL, NULL);

-- Excludes tribal type based on excluding subtype, excludes all subtypes, excludes non-null supertypes 

SELECT * FROM enchantments_function (1000, 'rare', 'legacy', 'Legal', 'B', NULL, NULL, NULL, NULL, 'include', array[['Legendary']]);

-- Excludes tribal type based on excluding subtype, excludes all subtypes, includes only legendary supertypes 



-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Enchantment%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Artifact%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Enchantment%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Artifact%';

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Enchantment%';

SELECT name, types, subtypes, rarity, colors FROM cards WHERE types ILIKE '%Enchantment%' AND types ILIKE '%Tribal%';
