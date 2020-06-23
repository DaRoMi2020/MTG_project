
--Planeswalker function

/*The planeswalker function is simpler than the other functions due to the unqiue 
nature and completeness of the planeswalker data in the type, subtype, and 
supertype columns. Unlike all other card types, planeswalkers are a singular and united 
type. There are no 'Artifact' planeswalkers like there are for lands, creatures, etc. 
Another thing unusual about planeswalkers is that their subtypes are mutually exclusive. 
Choosing any particular subtype or tribe of planeswalker will not select another tribe of 
planeswalker that you might not want with any influence from a function. Compare this to 
creatures where if you were to input a single creature 'Zombie' you would get 'Zombie, Knight' 
and takes the logic in logic in the creature function to get mutual exclusivity. Regarding the 
Planeswalkers' supertype, given that they are all legendary permanents all the function needs 
to do is pass along the column without interaction. */


CREATE FUNCTION planeswalker_function (
	planeswalker_limit_v integer, 
	planeswalker_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	planeswalker_subtypes TEXT [] DEFAULT NULL,
	planeswalker_types TEXT DEFAULT 'Planeswalker')

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
	cards.rarity = planeswalker_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	((cards.types::TEXT ILIKE planeswalker_types::TEXT AND cards.subtypes::TEXT ~* ANY (planeswalker_subtypes::TEXT[]))
		OR (cards.types::TEXT ILIKE planeswalker_types::TEXT AND planeswalker_subtypes::TEXT IS NULL))

/* Logic allows for input of array of desired planeswalkers while excluding unwanted planeswalkers 
or includes all planeswalkers when subtypes is NULL*/

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT planeswalker_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--function testing

--SELECT * FROM planeswalker_function (10, 'mythic', 'legacy', 'Legal', 'B', array[['Liliana'],['Sorin']]);

--SELECT * FROM planeswalker_function (10, 'mythic', 'legacy', 'Legal', 'B', array[['Liliana']]);

--SELECT * FROM planeswalker_function (10, 'mythic', 'legacy', 'Legal', 'B');

--DROP FUNCTION planeswalker_function(INTEGER,em_rarity, em_format, em_status, TEXT, TEXT[], TEXT);




