
CREATE FUNCTION enchantment_function (
	enchantments_limit_v integer, 
	enchantments_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	enchantments_sub_exclude TEXT DEFAULT NULL,
	enchantments_sub_include TEXT DEFAULT NULL,
	enchantments_super_exclude TEXT DEFAULT NULL,
	enchantments_super_include TEXT DEFAULT NULL)


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
SELECT DISTINCT ON 
(cards.name) cards.name, 
cards.id, 
cards.colors,
cards.rarity,
cards.types,
cards.subtypes,
cards.supertypes
legalities.format, 
legalities.status 
FROM cards 
LEFT OUTER JOIN legalities 
ON cards.uuid = legalities.uuid

WHERE 
cards.colors::TEXT ILIKE color_v::TEXT AND
cards.rarity = enchantments_rarity_v::em_rarity AND
cards.types::TEXT NOT ILIKE '%Land%' AND
cards.types::TEXT NOT ILIKE '%Creature%' AND
legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status AND
((enchantments_sub_exclude IS NULL AND cards.subtypes::TEXT IS NULL) OR 
	(enchantments_sub_exclude IS NOT NULL AND cards.subtypes::TEXT ILIKE enchantments_sub_include) OR 
	(enchantments_sub_exclude IS NULL AND cards.subtypes::TEXT ILIKE enchantments_sub_include)) AND
((enchantments_super_exclude IS NULL AND cards.supertypes::TEXT IS NULL) OR 
	(enchantments_super_exclude IS NOT NULL AND cards.supertypes::TEXT ILIKE enchantments_super_include) OR 
	(enchantments_super_exclude IS NULL AND cards.supertypes::TEXT ILIKE enchantments_super_include))



ORDER BY (cards.name))

SELECT * 
FROM A
ORDER BY random()
LIMIT enchantments_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--function testing

--

--

--

--

--

--

