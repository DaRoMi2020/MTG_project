
-- Creatures Function - subtype version

/*The Creature function is the most complicated function due to the diversity of types, subtypes, 
supertypes.*/


CREATE FUNCTION creatures_function (
	creatures_limit_v INTEGER, 
	format_v em_format, 
	status_v em_status,
	creatures_rarity_floor em_rarity DEFAULT 'common',
	creatures_rarity_ceiling em_rarity DEFAULT 'mythic',
	creatures_colors_primary_exclude TEXT DEFAULT NULL,
	creatures_colors_primary_include TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	creatures_colors_secondary TEXT [] DEFAULT NULL,
	creatures_colors_exclude_include TEXT DEFAULT 'Exclude',
	creatures_types_exclude TEXT DEFAULT NULL,
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
	creatures_super_include TEXT [] DEFAULT array[['Legendary'],['Snow']])

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
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND


	cards.rarity = ANY(enum_range(creatures_rarity_floor::em_rarity, creatures_rarity_ceiling::em_rarity)) AND

	((creatures_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL OR cards.colors::TEXT ~* ANY (creatures_colors_primary_include::TEXT[])) OR -- include all choosen including null
		(creatures_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL AND creatures_colors_primary_include::TEXT[] IS NULL) OR -- excludes non-null colors
		(creatures_colors_primary_exclude::TEXT IS NOT NULL AND cards.colors::TEXT IS NOT NULL AND cards.colors::TEXT ~* ANY (creatures_colors_primary_include::TEXT[]))) AND -- exclude null

	((creatures_colors_exclude_include::TEXT ILIKE 'Exclude' AND (creatures_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT !~* ALL (creatures_colors_secondary::TEXT[]))) OR
		(creatures_colors_exclude_include::TEXT ILIKE 'Include' AND (creatures_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT ~* ANY (creatures_colors_secondary::TEXT[])))) AND

	((creatures_types_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Creature%' AND creatures_types_include::TEXT[] IS NULL) OR --include all creatures types depending on subtype options
		(creatures_types_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Creature' AND creatures_types_include::TEXT[] IS NULL) OR -- default excludes non-basic creature types
		(creatures_types_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Creature%' AND cards.types::TEXT  ~* ANY (creatures_types_include::TEXT[]))) AND -- includes basic creature types and added types

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

	((creatures_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ~* ANY (creatures_super_include::TEXT[])) OR --include all choosen including null
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


-- Default

SELECT * FROM creatures_function (1000, 'legacy', 'Legal'); 

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic'); 

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude'); 

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, array[['Legendary'],['Snow']]); 

-- 1000 random cards (not a default option), legacy format (not a default option), legal in format(not a default option), 
-- Rarities between common and mythic rare, includes all colored and null creatures, excludes no colored and null creatures
-- Includes all types, include all subtypes, includes all supertypes


-- Rarity options

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic');

-- Default, Rarities between common and mythic rare

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'uncommon', 'uncommon');

-- Only includes creatures that are uncommon

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'rare');

-- Only includes creatures with rarities that are between common and rare excludes mythic rares


-- Exclusion mode

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

-- Default, includes all colored and null creatures, excludes no colored and null creatures

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black, green, or colorless, might have other colors as secondary colors.

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black or green but not colorless, might have other colors as secondary colors.

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], array[['W'], ['R'], ['U']], 'Exclude');

-- Every card is either a black and/or green but not colorless, excludes white, red, and blue.

-- Inclusion mode

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B']], array[['G']], 'Include');

-- every card must contain black and green, might have other colors as secondary colors.


-- Types options

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 
	NULL, NULL);

-- Default, Includes all types

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	'Exclude', NULL);

-- Excludes non-basic creature types

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	'Include', array[['Enchantment'], ['Artifact'], ['Land']]);

-- Excludes basic creature type


-- Subtypes options

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Default, Include all subtypes

-- Primary (first subtype on card)

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL);

-- Default, Include all Primary subtypes

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, array[['Zombie']]);

-- Includes only Zombie subtype as primary subtype 

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, 'Exclude', array[['Zombie']]);

-- Excludes Zombie subtype as primary subtype 

-- Default

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Secondary (Second subtype on card)

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL);

-- Default, Include all Secondary subtypes

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, array[['Knight']]);

-- Includes only Knight Secondary subtype

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, 'Excludes', array[['Knight']]);

-- Excludes Knight Secondary subtype

-- Tertiary (Third subtype on card), after secondary must have at least the previous subtype imputed

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Default

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, array[['Dinosaur']], NULL, array[['Beast']], NULL, NULL);

-- Cards rarely have three subtypes

-- Quaternary (Forth subtype on card)

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Default

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, array[['Centaur']], NULL, array[['Druid']], NULL, array[['Scout']], NULL, array[['Archer']]);;

-- -- only one card has four subtypes


-- Supertypes Options

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, array[['Legendary'],['Snow']]); 

-- Default, includes all supertypes

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL); 

-- Excludes non-NULL supertypes

SELECT * FROM creatures_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude',
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Exclude', array[['Legendary'],['Snow']]); 

-- Excludes NULL supertypes


----------------------------


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Creature%'; 

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Creature%';

SELECT DISTINCT ON (supertypes) supertypes, types FROM cards WHERE types ILIKE '%Creature%';

