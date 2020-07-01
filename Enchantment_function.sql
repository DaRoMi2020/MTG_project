
--Enchantment function

/**/


CREATE FUNCTION enchantments_function (
	enchantments_limit_v INTEGER, 
	enchantments_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	enchantments_type_exclude TEXT DEFAULT 'Enchantment',
	enchantments_type_include TEXT DEFAULT NULL,
	enchantments_sub_exclude TEXT DEFAULT NULL,
	enchantments_sub_include TEXT[] DEFAULT NULL,
	enchantments_super_exclude TEXT DEFAULT NULL,
	enchantments_super_include TEXT[] DEFAULT NULL)


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
cards.colors::TEXT ILIKE color_v::TEXT AND
cards.rarity = enchantments_rarity_v::em_rarity AND
cards.types::TEXT NOT ILIKE '%Creature%' AND
cards.types::TEXT NOT ILIKE '%Artifact%' AND
cards.types::TEXT NOT ILIKE '%Land%' AND
legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status AND

((enchantments_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Enchantment%' AND cards.types::TEXT ILIKE enchantments_type_include IS NULL) OR --include all enchantments
	(cards.types::TEXT ILIKE enchantments_type_exclude::TEXT AND enchantments_type_include::TEXT IS NULL) OR --default exclude: Exclude tribal
	(enchantments_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Enchantment%' AND cards.types::TEXT ILIKE enchantments_type_include::TEXT)) AND --only tribal

((enchantments_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (enchantments_sub_include::TEXT[])) OR --include all choosen including null 
	(enchantments_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND enchantments_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(enchantments_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (enchantments_sub_include::TEXT[]))) AND --exclude nulls

((enchantments_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ~* ANY (enchantments_super_include::TEXT[])) OR --include all choosen including null
	(enchantments_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND enchantments_super_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(enchantments_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ~* ANY (enchantments_super_include::TEXT[]))) --include all choosen amd exclude nulls 

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT enchantments_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


-- Function testing

-- DROP FUNCTION enchantments_function(INTEGER, em_rarity, em_format, em_status, TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[]);

SELECT * FROM enchantments_function (10, 'uncommon', 'legacy', 'Legal', 'B');
-- Exclude tribal, exclude subtypes not null

SELECT * FROM enchantments_function (10, 'uncommon', 'legacy', 'Legal', 'B', NULL, NULL, NULL, 
array[['Aura'], ['Cartouche'], ['Curse'], ['Saga'], ['Shrine']]); 
-- Includes every enchantment, excludes tribal and tribal subtypes

SELECT * FROM enchantments_function (10, 'uncommon', 'legacy', 'Legal', 'B', NULL, NULL, NULL,
array[['Aura'], ['Cartouche'], ['Curse'], ['Saga'], ['Shrine']], NULL, array[['Legendary']]);
-- Includes every enchantment, excludes tribal and tribal subtypes, include null and legendary supertype

SELECT * FROM enchantments_function (10, 'uncommon', 'legacy', 'Legal', 'B', NULL, NULL, NULL,
array[['Aura'], ['Cartouche'], ['Curse'], ['Saga'], ['Shrine']], 'exclude null supertype', array[['Legendary']]);

-- Includes every enchantment, excludes tribal and tribal subtypes, exclude null supertype and include legendary supertype




SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Enchantment%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Artifact%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Enchantment%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Artifact%';

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Enchantment%';

