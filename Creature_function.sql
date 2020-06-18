CREATE FUNCTION test_creatures (
	color_v TEXT, 
	creatures_rarity_v em_rarity,
	creatures_type_v TEXT,
	creatures_types_v TEXT, 
	format_v em_format, 
	status_v em_status, 
	creatures_limit_v integer)

RETURNS TABLE (c_name_t TEXT,
	c_id_t integer,
	c_color_t TEXT,
	c_rarity_t em_rarity,
	c_type_t TEXT,
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
cards."type",
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
cards."type"::TEXT ILIKE creatures_type_v::TEXT AND
cards.types::TEXT ILIKE creatures_types_v::TEXT AND
legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status
ORDER BY (cards.name))

SELECT * 
FROM A
ORDER BY random()
LIMIT creatures_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';

-----------

SELECT * FROM test_creatures('B','common','%zombie%', 'Creature','legacy','Legal', 10);

DROP FUNCTION test_creatures(text, em_rarity, text, text,  em_format, em_status, integer);