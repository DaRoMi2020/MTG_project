
--Land function

/**/


CREATE FUNCTION land_function ( 
	land_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	swamp_limit integer,
	forest_limit integer,
	island_limit integer,
	mountain_limit integer,
	plains_limit integer
	)

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


--basic lands

(SELECT cards."name", 
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
	cards.rarity = land_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	subtypes ILIKE 'Swamp'
ORDER BY cards
LIMIT swamp_limit::integer)

UNION

(SELECT cards."name", 
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
	cards.rarity = land_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	subtypes ILIKE 'Forest'
ORDER BY cards
LIMIT forest_limit::integer)

UNION

(SELECT cards."name", 
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
	cards.rarity = land_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	subtypes ILIKE 'Island'
ORDER BY cards
LIMIT island_limit::integer)

UNION

(SELECT cards."name", 
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
	cards.rarity = land_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	subtypes ILIKE 'Mountain'
ORDER BY cards
LIMIT mountain_limit::integer)

UNION

(SELECT cards."name", 
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
	cards.rarity = land_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	subtypes ILIKE 'Plains'
ORDER BY cards
LIMIT plains_limit::integer);


END; $T$ LANGUAGE 'plpgsql';


--SELECT * FROM land_function ('common', 'legacy', 'Legal', 5, 5, 5, 5, 5)