
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


CREATE FUNCTION planeswalker_function (
	planeswalker_limit_v integer, 
	planeswalker_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
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
	cards.colors::TEXT ILIKE color_v::TEXT AND
	cards.rarity = planeswalker_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

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

SELECT * FROM planeswalker_function (10, 'mythic', 'legacy', 'Legal', 'B');

-- Includes all planeswalkers (default)


SELECT * FROM planeswalker_function (10, 'mythic', 'legacy', 'Legal', 'B', NULL, array[['Liliana'],['Sorin']]);

-- Includes only selected planeswalkers 


SELECT * FROM planeswalker_function (10, 'mythic', 'legacy', 'Legal', 'B', 'exclude', array[['Liliana']]);

-- exclude selected planeswalkers 


-- Query Subtypes

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Planeswalker%';


