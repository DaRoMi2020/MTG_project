
--Creatures Functions

/*The Creature function is the most complicated function due to the diversity of types, subtypes, 
supertypes.*/


CREATE FUNCTION creatures_function (
	creatures_limit_v INTEGER, 
	creatures_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	creatures_types_exclude TEXT DEFAULT 'Creature',
	creatures_types_include TEXT [] DEFAULT NULL,
	creatures_primary_sub_exclude TEXT DEFAULT NULL,
	creatures_primary_sub_include TEXT [] DEFAULT NULL,
	creatures_secondary_sub_exclude TEXT DEFAULT NULL,
	creatures_secondary_sub_include TEXT [] DEFAULT NULL,
	creatures_tertiary_sub_exclude TEXT DEFAULT NULL,
	creatures_tertiary_sub_include TEXT [] DEFAULT NULL,
	creatures_quaternary_sub_exclude TEXT DEFAULT NULL,
	creatures_quaternary_sub_include TEXT [] DEFAULT NULL,
	creatures_super_exclude TEXT DEFAULT NULL,
	creatures_super_include TEXT[] DEFAULT array[['Legendary'],['Snow']])

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

DECLARE

p_temp_in TEXT[] = 	(WITH A_con AS (
					SELECT concat ('^', UNNEST(creatures_primary_sub_include::TEXT[])))
					SELECT array_agg(concat) p_temp_in
					FROM A_con);

s_temp_in TEXT[] = 	(WITH A_con AS (
					SELECT concat (',', UNNEST(creatures_secondary_sub_include::TEXT[])))
					SELECT array_agg(concat) s_temp_in
					FROM A_con);

t_temp_in TEXT[] = 	(WITH A_con AS (
					SELECT concat (',', UNNEST(creatures_tertiary_sub_include::TEXT[])))
					SELECT array_agg(concat) t_temp_in
					FROM A_con);

q_temp_in TEXT[] = 	(WITH A_con AS (
					SELECT concat (',', UNNEST(creatures_quaternary_sub_include::TEXT[])))
					SELECT array_agg(concat) q_temp_in
					FROM A_con);

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
	cards.rarity = creatures_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

((creatures_types_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Creature%' AND creatures_types_include::TEXT[] IS NULL) OR --include all creatures types depending on subtype options
	(cards.types::TEXT ILIKE creatures_types_exclude::TEXT AND creatures_types_include::TEXT[] IS NULL) OR -- default excludes non-basic creature types
	(creatures_types_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Creature%' AND cards.types::TEXT  ~* ANY (creatures_types_include::TEXT[]))) AND -- includes basic creature types and added types

((creatures_primary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND p_temp_in::TEXT[] IS NULL) OR -- include all creature subtypes
	(creatures_primary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (p_temp_in::TEXT[])) OR -- include selected subtypes
	(creatures_primary_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT !~* ALL (p_temp_in::TEXT[]))) AND -- exclude selected subtypes

((creatures_secondary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND s_temp_in::TEXT[] IS NULL) OR -- include all creature subtypes
	(creatures_secondary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (s_temp_in::TEXT[])) OR -- include selected subtypes
	(creatures_secondary_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT !~* ALL (s_temp_in::TEXT[]))) AND -- exclude selected subtypes

((creatures_tertiary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND t_temp_in::TEXT[] IS NULL) OR -- include all creature subtypes
	(creatures_tertiary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (t_temp_in::TEXT[])) OR -- include selected subtypes
	(creatures_tertiary_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT !~* ALL (t_temp_in::TEXT[]))) AND -- exclude selected subtypes

((creatures_quaternary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND q_temp_in::TEXT[] IS NULL) OR -- include all creature subtypes
	(creatures_quaternary_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (q_temp_in::TEXT[])) OR -- include selected subtypes
	(creatures_quaternary_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT !~* ALL (q_temp_in::TEXT[]))) AND -- exclude selected subtypes

((creatures_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND cards.supertypes::TEXT ~* ANY (creatures_super_include::TEXT[])) OR --include all choosen including null
	(creatures_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND creatures_super_include::TEXT[] IS NULL) OR --Exclude supertypes not null
	(creatures_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ~* ANY (creatures_super_include::TEXT[]))) --include all choosen and exclude nulls 

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT creatures_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

SELECT * FROM creatures_function (1000, 'rare', 'legacy', 'Legal', '%B%'); 

-- Excludes non-basic creature types, includes all subtypes, includes all supertypes 

SELECT * FROM creatures_function (1000, 'rare', 'legacy', 'Legal', '%B%', 'Creature', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Excludes non-basic creature types, includes all subtypes, excludes supertypes not null

SELECT * FROM creatures_function (1000, 'rare', 'legacy', 'Legal', '%B%', NULL);

SELECT * FROM creatures_function (1000, 'rare', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, array[['Legendary'],['Snow']]);

SELECT * FROM creatures_function (1000, 'rare', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,NULL, NULL);

-- Includes all creature types, includes all subtypes, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, array[['Enchantment']]);

-- Excludes Basic creature types and includes only enchantment creature type, includes all enchantment creature subtypes, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, array[['Enchantment']], NULL, array[['Demon']]);

-- Excludes Basic creature types and includes only enchantment creature type, includes only enchantment demon creature subtype, includes all supertypes


SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, array[['Enchantment']], 'Exclude', array[['Demon']]);

-- Excludes Basic creature types and includes only enchantment creature type, excludes enchantment demon creature subtype, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, array[['Zombie']]);

-- Includes all creature types, includes only zombies as primary subtype and all other subtypes after, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, array[['Zombie']], NULL, array[['Knight']]);

-- Includes all creature types, includes only zombies as primary subtype and only Knights as second subtype and all other after, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, array[['Zombie']], 'Exclude', array[['Knight']]);

--  Includes all creature types, includes only zombies as primary subtype and exludes Knights as second subtype and all other after, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, array[['Zombie']], NULL, array[['Dinosaur']], NULL, array[['Beast']]);

-- Includes all creature types, includes only zombies as primary subtype and includes Dinosaur as second subtype and Beast as third and all as fourth, includes all supertypes

SELECT * FROM creatures_function (10, 'uncommon', 'legacy', 'Legal', '%B%', NULL, NULL, NULL, array[['Centaur']], NULL, array[['Druid']], NULL, array[['Scout']], NULL, array[['Archer']]);

-- Includes all creature types, includes only Centaur as primary subtype and includes Druid as secondary subtype and Scout as third and Archer as fourth, includes all supertypes




-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Creature%'; 

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Creature%';

SELECT DISTINCT ON (supertypes) supertypes, types FROM cards WHERE types ILIKE '%Creature%';

