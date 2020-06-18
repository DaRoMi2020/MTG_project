CREATE FUNCTION creatures_function (
	creatures_limit_v integer, 
	creatures_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	creatures_types_exclude TEXT DEFAULT 'Creature',
	creatures_types_include TEXT [] DEFAULT NULL)

RETURNS TABLE (c_name_t TEXT,
	c_id_t integer,
	c_color_t TEXT,
	c_rarity_t em_rarity,
	c_types_t TEXT,
	l_id_t integer,
	l_form_t em_format,
	l_stat_t em_status
	)

AS $T$

BEGIN

RETURN QUERY 

WITH A AS (
SELECT DISTINCT ON 
(cards.name) cards.name, 
cards.id, 
cards.colors,
cards.rarity,
cards.types,
legalities.id, 
legalities.format, 
legalities.status 
FROM cards 
LEFT OUTER JOIN legalities 
ON cards.uuid = legalities.uuid


WHERE 
cards.colors::TEXT ILIKE color_v::TEXT AND
cards.rarity = creatures_rarity_v::em_rarity AND

((cards.types::TEXT ILIKE creatures_types_exclude::TEXT AND creatures_types_include::TEXT IS NULL) OR
	(cards.types::TEXT ILIKE creatures_types_exclude::TEXT AND cards.types::TEXT ILIKE ANY (creatures_types_include::TEXT[]))) AND 

legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status
ORDER BY (cards.name))

SELECT * 
FROM A
ORDER BY random()
LIMIT creatures_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';
