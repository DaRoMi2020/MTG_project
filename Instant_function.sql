
--Instant function

/**/


CREATE FUNCTION instant_function (
	instant_limit_v integer, 
	instant_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	instant_types_exclude TEXT DEFAULT 'Instant',
	instant_types_include TEXT DEFAULT NULL,
	instant_subtype TEXT[] DEFAULT NULL)

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
	cards.rarity = instant_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	((cards.types::TEXT ILIKE instant_types_exclude::TEXT AND instant_types_include::TEXT IS NULL) OR
		(cards.types::TEXT ILIKE instant_types_exclude::TEXT AND cards.types::TEXT ILIKE instant_types_include::TEXT)) AND
	(instant_subtype::TEXT[] IS NULL OR cards.subtypes ~* ANY (instant_subtype::TEXT[]))

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT instant_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';

--Testing function

--SELECT * FROM instant_function (10, 'common', 'legacy', 'Legal', 'B');

--SELECT * FROM instant_function (10, 'common', 'legacy', 'Legal', 'B', '%Instant%', '%Tribal%');

--SELECT * FROM instant_function (10, 'common', 'legacy', 'Legal', 'B', '%Instant%', '%Tribal%', array[['Faerie']]);

--SELECT * FROM instant_function (10, 'common', 'legacy', 'Legal', 'B', 'Instant', NULL, array[['Arcane']]);

--DROP FUNCTION instant_function (INTEGER, em_rarity, em_format, em_status, TEXT, TEXT, TEXT, TEXT[]);