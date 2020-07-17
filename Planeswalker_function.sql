
--Planeswalker function

/* Due to the nature and completeness of the Planeswalker data in the type, subtype, and 
supertype columns the Planeswalker function is the simplest function among all the functions.
Unlike all other card types, Planeswalkers are a singular and united type. There are no 'Artifact' 
Planeswalkers like there are for lands, creatures, etc. Another unusual attribute of Planeswalkers 
is that their subtypes are mutually exclusive. Choosing any particular subtype or tribe of 
Planeswalker will not select another tribe of Planeswalker that you might not want in your random 
deck. Compare this to creatures where if you were to input a single creature subtype/tribe 'Zombie' 
you would get 'Zombie, Knight'. It takes the logic within the creature function to get mutual exclusivity. 
Regarding the Planeswalkers' supertype, given that they are all legendary permanents, all the function needs 
to do is pass along the column without interaction. */


CREATE FUNCTION planeswalkers_function (
	planeswalker_limit_v integer, 
	format_v em_format, 
	status_v em_status,
	planeswalkers_rarity_floor em_rarity DEFAULT 'common',
	planeswalkers_rarity_ceiling em_rarity DEFAULT 'mythic',
	planeswalkers_colors_primary_exclude TEXT DEFAULT NULL,
	planeswalkers_colors_primary_include TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	planeswalkers_colors_secondary TEXT [] DEFAULT NULL,
	planeswalkers_colors_exclude_include TEXT DEFAULT 'Exclude',
	planeswalkers_sub_exclude TEXT DEFAULT NULL,
	planeswalkers_sub_include TEXT [] DEFAULT NULL)

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
	cards.types::TEXT ILIKE 'Planeswalker' AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

	cards.rarity = ANY(enum_range(planeswalkers_rarity_floor::em_rarity, planeswalkers_rarity_ceiling::em_rarity)) AND

	((planeswalkers_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL OR cards.colors::TEXT ~* ANY (planeswalkers_colors_primary_include::TEXT[])) OR -- include all choosen including null
		(planeswalkers_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL AND planeswalkers_colors_primary_include::TEXT[] IS NULL) OR -- excludes non-null colors
		(planeswalkers_colors_primary_exclude::TEXT IS NOT NULL AND cards.colors::TEXT IS NOT NULL AND cards.colors::TEXT ~* ANY (planeswalkers_colors_primary_include::TEXT[]))) AND -- exclude null

	((planeswalkers_colors_exclude_include::TEXT ILIKE 'Exclude' AND (planeswalkers_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT !~* ALL (planeswalkers_colors_secondary::TEXT[]))) OR
		(planeswalkers_colors_exclude_include::TEXT ILIKE 'Include' AND (planeswalkers_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT ~* ANY (planeswalkers_colors_secondary::TEXT[])))) AND

	((planeswalkers_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND planeswalkers_sub_include::TEXT[] IS NULL) OR -- include all creature subtypes
		(planeswalkers_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (planeswalkers_sub_include::TEXT[])) OR -- include selected subtypes
		(planeswalkers_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT !~* ALL (planeswalkers_sub_include::TEXT[]))) -- exclude selected subtypes

/* Logic allows for input of array of desired Planeswalkers while excluding unwanted Planeswalkers 
or includes all Planeswalkers when subtypes is NULL*/

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT planeswalker_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--Function testing


-- Default

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal');

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic');

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

-- 1000 random cards (not a default option), legacy format (not a default option), legal in format(not a default option), 
-- Rarities between common and mythic rare, includes all colored and null planeswalkers, excludes no colored and null planeswalkers
-- Include all subtypes


-- Rarity options

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic');

-- Default

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'uncommon', 'uncommon'); 

-- Only includes planeswalkers that are uncommon

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'rare'); 

-- Only includes planeswalkers with rarities that are between common and rare excludes mythic rares


-- Color options

-- Exclusion mode

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black, green, or colorless instant, might have other colors as secondary colors.

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black or green but not colorless, does not explicitly exclude any color

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], array[['W'], ['R'], ['U']], 'Exclude');

-- Every card is either a black and/or green but not colorless, excludes white, red, and blue.

-- Inclusion mode

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B']], array[['G']], 'Include');

-- every card must contain black and green other colors possible. 


-- Subtypes 

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

-- include all subtypes (default)

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, array[['Liliana'],['Sorin']]);

-- includes all null subtypes and selected subtypes

SELECT * FROM planeswalkers_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Exclude', array[['Liliana'],['Sorin']]);

-- Excludes imputed subtypes (also excludes tribal type)


-- Query Subtypes
SELECT DISTINCT ON (name) name, subtypes, types, supertypes FROM cards WHERE types ILIKE '%Planeswalker%';


SELECT DISTINCT ON (supertypes) supertypes, types FROM cards WHERE types ILIKE '%Planeswalker%';

