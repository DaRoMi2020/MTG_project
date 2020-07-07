
--Instant function


/**/


CREATE FUNCTION instants_function (
	instants_limit_v INTEGER, 
	instants_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	instants_type_exclude TEXT DEFAULT NULL,
	instants_type_include TEXT DEFAULT NULL,
	instants_sub_exclude TEXT DEFAULT NULL,
	instants_sub_include TEXT[] DEFAULT array [['Adventure'], ['Angel'], ['Arcane'], ['Eldrazi'], ['Elf'],
	['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Rogue'], ['Shapeshifter'], ['Trap'], ['Treefolk']])

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
	cards.rarity = instants_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

((instants_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Instant%' AND cards.types::TEXT ILIKE instants_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
	(instants_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Instant' AND instants_type_include::TEXT IS NULL) OR -- Exclude tribal
	(instants_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Instant%' AND cards.types::TEXT ILIKE instants_type_include::TEXT)) AND -- only tribal

((instants_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (instants_sub_include::TEXT[])) OR --include all choosen including null 
	(instants_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND instants_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(instants_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (instants_sub_include::TEXT[])))--exclude nulls

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT instants_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

SELECT * FROM instants_function (1000, 'common', 'legacy', 'Legal', 'W');

SELECT * FROM instants_function (10, 'uncommon', 'legacy', 'Legal', 'W', NULL, NULL, NULL, array [['Adventure'], ['Angel'], ['Arcane'], ['Eldrazi'], ['Elf'],
	['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Rogue'], ['Shapeshifter'], ['Trap'], ['Treefolk']];

-- Include all instant types, include all subtypes (default)

SELECT * FROM instants_function (1000, 'uncommon', 'legacy', 'Legal', 'W', NULL, NULL, NULL, NULL);

-- Excludes tribal type based on exluding subtype, excludes all subtypes

SELECT * FROM instants_function (10, 'common', 'legacy', 'Legal', 'W', NULL, '%Tribal%');

-- Includes only tribal, includes only tribal subtypes

SELECT * FROM instants_function (10, 'common', 'legacy', 'Legal', 'W', NULL, NULL, 'Include', array[['Shapeshifter'], ['Kithkin']]);

-- Includes only tribal type based on including certain tribal types, only includes certain tribal types


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Instant%' 
AND types NOT ILIKE '%Creature%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Instant%' AND  types NOT ILIKE '%Creature%'; 

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Instant%' AND NOT ILIKE '%Creature%';

SELECT name, types, subtypes, rarity, colors FROM cards WHERE types ILIKE '%Instant%' AND types NOT ILIKE '%Creature%' AND types ILIKE '%Tribal%';
