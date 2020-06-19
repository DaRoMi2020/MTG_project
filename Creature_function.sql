CREATE FUNCTION creatures_function (
	creatures_limit_v integer, 
	creatures_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	creatures_types_exclude TEXT DEFAULT 'Creature',
	creatures_types_include TEXT [] DEFAULT NULL,
	creatures_primary_sub TEXT [] DEFAULT NULL)



RETURNS TABLE (c_name_t TEXT,
	cards_id integer,
	c_colors_t TEXT ,
	c_rarity_t em_rarity,
	c_types_t TEXT,
	c_subtypes_t TEXT,
	l_id_t integer,
	l_form_t em_format,
	l_stat_t em_status
	)

AS $T$

DECLARE

sub_temp TEXT[] = (WITH A_con AS (
	SELECT concat ('^', UNNEST(creatures_primary_sub::TEXT[]))
		)
SELECT array_agg(concat) sub_temp
FROM A_con);

BEGIN

RETURN QUERY 

WITH A AS (
SELECT DISTINCT ON 
(cards.name) cards.name, 
cards.id, 
cards.colors,
cards.rarity,
cards.types,
cards.subtypes,
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

(sub_temp IS NULL OR cards.subtypes::TEXT ~* ANY (sub_temp::TEXT[])) AND


legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status
ORDER BY (cards.name))

SELECT * 
FROM A
ORDER BY random()
LIMIT creatures_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';

------

--SELECT * FROM creatures_function (10, 'rare', 'legacy', 'Legal', 'B');
