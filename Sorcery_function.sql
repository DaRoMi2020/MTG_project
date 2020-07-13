--Sorcery function


/**/


CREATE FUNCTION sorceries_function (
	sorceries_limit_v integer, 
	sorceries_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	sorceries_type_exclude TEXT DEFAULT NULL,
	sorceries_type_include TEXT DEFAULT NULL,
	sorceries_sub_exclude TEXT DEFAULT NULL,
	sorceries_sub_include TEXT[] DEFAULT array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], 
	['Goblin'], ['Merfolk'], ['Rogue']],
	sorceries_super_exclude TEXT DEFAULT NULL,
	sorceries_super_include TEXT DEFAULT 'Legendary')

RETURNS TABLE (card_name TEXT,
	card_id integer,
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
SELECT DISTINCT ON (cards."name") cards."name", 
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
	cards.rarity = sorceries_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

((sorceries_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Sorcery%' AND cards.types::TEXT ILIKE sorceries_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
	(sorceries_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Sorcery' AND sorceries_type_include::TEXT IS NULL) OR -- Exclude tribal
	(sorceries_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Sorcery%' AND cards.types::TEXT ILIKE sorceries_type_include::TEXT)) AND -- only tribal

((sorceries_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (sorceries_sub_include::TEXT[])) OR --include all choosen including null 
	(sorceries_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND sorceries_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(sorceries_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (sorceries_sub_include::TEXT[]))) AND --exclude nulls

((sorceries_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ILIKE sorceries_super_include::TEXT) OR --include legendary including null
	(sorceries_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND sorceries_super_include::TEXT IS NULL) OR --Exclude supertypes not null
	(sorceries_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ILIKE sorceries_super_include::TEXT)) --include legendary and exclude nulls

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT sorceries_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

SELECT * FROM sorceries_function (1000, 'uncommon', 'legacy', 'Legal', 'G'); 

SELECT * FROM sorceries_function (1000, 'uncommon', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], 
	['Goblin'], ['Merfolk'], ['Rogue']], NULL, 'Legendary');

-- includes all sorcery types, includes all subtypes, includes all supertypes (default)

SELECT * FROM sorceries_function (1000, 'uncommon', 'legacy', 'Legal', 'B', NULL, '%Tribal%');

-- includes only tribal enchantments, including only tribal subtypes, includes all supertypes 


SELECT * FROM sorceries_function (1000, 'uncommon', 'legacy', 'Legal', 'B', NULL, NULL, 'include', array[['Goblin']]);

-- Includes tribal type only based on including tribal subtype, including tribal subtype, includes supertypes 


SELECT * FROM sorceries_function (1000, 'rare', 'legacy', 'Legal', 'B', NULL, NULL, NULL, NULL, NULL, NULL);

-- excludes tribal type only based on excludes tribal subtype, excludes all non-null subtype, excludes non-null supertype

SELECT * FROM sorceries_function (1000, 'rare', 'legacy', 'Legal', 'B', NULL, NULL, NULL, NULL, 'include', 'Legendary');

-- Excludes tribal type based on excluding subtype, excludes all subtypes, includes only legendary supertypes 


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Sorcery%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Sorcery%'; 

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Sorcery%';

SELECT * FROM sorceries_function (1000, 'rare', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane']], NULL, 'Legendary');