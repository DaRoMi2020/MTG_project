--Sorcery function


/**/


CREATE FUNCTION sorceries_function (
	sorceries_limit_v integer, 
	sorceries_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	sorceries_type_exclude TEXT DEFAULT 'Sorcery',
	sorceries_type_include TEXT DEFAULT NULL,
	sorceries_sub_exclude TEXT DEFAULT NULL,
	sorceries_sub_include TEXT[] DEFAULT NULL,
	sorceries_super_exclude TEXT DEFAULT NULL,
	sorceries_super_include TEXT DEFAULT NULL)

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
	(cards.types::TEXT ILIKE sorceries_type_exclude::TEXT AND sorceries_type_include::TEXT IS NULL) OR --default exclude: Exclude tribal
	(sorceries_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Sorcery%' AND cards.types::TEXT ILIKE sorceries_type_include::TEXT)) AND -- only tribal

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

SELECT * FROM sorceries_function (10, 'uncommon', 'legacy', 'Legal', 'G');
-- Exclude tribal type, exclude subtypes not null, exclude supertype not null

SELECT * FROM sorceries_function (10, 'uncommon', 'legacy', 'Legal', 'G', NULL, NULL, 'exclude', array[['Adventure'], ['Arcane']]);
-- Exclude tribal type, include selected subtype and exclude null subtype, exclude supertype not null

SELECT * FROM sorceries_function (10, 'uncommon', 'legacy', 'Legal', 'G', 'exclude', '%Tribal%', 'exclude', array[['Elf']]);
-- Exclude nulls type, exclude null subtype, exclude supertype not null, exclude supertype not null

SELECT * FROM sorceries_function (10, 'uncommon', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane']]);
-- Exclude tribal type by not including correct subtype, include selected subtype and null subtype, exclude supertype not null, exclude supertype not null

SELECT * FROM sorceries_function (10, 'uncommon', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Elf'],['Adventure'], ['Arcane']]);
-- Include all types by including correct tribal subtype, exclude supertype not null, exclude supertype not null

SELECT * FROM sorceries_function (10, 'rare', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane']], 'Exclude', 'Legendary');
-- Exclude tribal type by not including correct subtype, include selected subtype and null subtype, exclude supertype null, exclude supertype not null

SELECT * FROM sorceries_function (1000, 'rare', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane']], NULL, 'Legendary');
-- Exclude tribal type by not including correct subtype, include selected subtype and null subtype, exclude supertype null, exclude supertype not null



-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Sorcery%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Sorcery%'; 

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Sorcery%';

SELECT * FROM sorceries_function (1000, 'rare', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane']], NULL, 'Legendary');