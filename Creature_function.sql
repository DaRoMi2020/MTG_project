CREATE FUNCTION creatures_function (
	creatures_limit_v integer, 
	creatures_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	colors_v TEXT,
	creatures_types_exclude TEXT DEFAULT 'Creature',
	creatures_types_include TEXT [] DEFAULT NULL)

RETURNS TABLE (c_name_t TEXT,
	card_id integer,
	card_colors TEXT,
	card_rarity em_rarity,
	card_types TEXT,
	card_format em_format,
	card_status em_status
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
legalities.format, 
legalities.status 
FROM cards 
LEFT OUTER JOIN legalities 
ON cards.uuid = legalities.uuid


WHERE 
cards.colors::TEXT ILIKE colors_v::TEXT AND
cards.rarity = creatures_rarity_v::em_rarity AND

((cards.types::TEXT ILIKE creatures_types_exclude::TEXT AND creatures_types_include::TEXT IS NULL) OR
	(cards.types::TEXT ILIKE creatures_types_exclude::TEXT AND cards.types::TEXT ILIKE ANY (creatures_types_include::TEXT[]))) AND 

legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status
ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT creatures_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';

------

--SELECT * FROM creatures_function (10, 'rare', 'legacy', 'Legal', 'B');
