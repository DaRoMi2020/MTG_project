
--Land function

/**/


CREATE FUNCTION snow_basic_land_function ( 
	swamp_limit INTEGER DEFAULT 0,
	forest_limit INTEGER DEFAULT 0,
	island_limit INTEGER DEFAULT 0,
	mountain_limit INTEGER DEFAULT 0,
	plains_limit INTEGER DEFAULT 0,
	colorless_limit INTEGER DEFAULT 0,
	snow_lands TEXT DEFAULT 'Include'
	)

RETURNS TABLE (card_name TEXT,
	card_id INTEGER,
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
	subtypes ILIKE 'Swamp' AND
	((snow_lands::TEXT ILIKE 'Include' AND supertypes ILIKE '%Basic%') OR
		(snow_lands::TEXT ILIKE 'Exclude' AND supertypes ILIKE '%Basic%' AND supertypes NOT ILIKE '%Snow%') OR
		(snow_lands::TEXT ILIKE 'Snow Only' AND supertypes ILIKE '%Snow%'))
ORDER BY cards
LIMIT swamp_limit::INTEGER)

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
	subtypes ILIKE 'Forest' AND
	((snow_lands::TEXT ILIKE 'Include' AND supertypes ILIKE '%Basic%') OR
		(snow_lands::TEXT ILIKE 'Exclude' AND supertypes ILIKE '%Basic%' AND supertypes NOT ILIKE '%Snow%') OR
		(snow_lands::TEXT ILIKE 'Snow Only' AND supertypes ILIKE '%Snow%'))
ORDER BY cards
LIMIT forest_limit::INTEGER)

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
	subtypes ILIKE 'Island' AND
	((snow_lands::TEXT ILIKE 'Include' AND supertypes ILIKE '%Basic%') OR
		(snow_lands::TEXT ILIKE 'Exclude' AND supertypes ILIKE '%Basic%' AND supertypes NOT ILIKE '%Snow%') OR
		(snow_lands::TEXT ILIKE 'Snow Only' AND supertypes ILIKE '%Snow%'))
ORDER BY cards
LIMIT island_limit::INTEGER)

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
	subtypes ILIKE 'Mountain' AND
	((snow_lands::TEXT ILIKE 'Include' AND supertypes ILIKE '%Basic%') OR
		(snow_lands::TEXT ILIKE 'Exclude' AND supertypes ILIKE '%Basic%' AND supertypes NOT ILIKE '%Snow%') OR
		(snow_lands::TEXT ILIKE 'Snow Only' AND supertypes ILIKE '%Snow%'))
ORDER BY cards
LIMIT mountain_limit::INTEGER)

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
	subtypes ILIKE 'Plains' AND
	((snow_lands::TEXT ILIKE 'Include' AND supertypes ILIKE '%Basic%') OR
		(snow_lands::TEXT ILIKE 'Exclude' AND supertypes ILIKE '%Basic%' AND supertypes NOT ILIKE '%Snow%') OR
		(snow_lands::TEXT ILIKE 'Snow Only' AND supertypes ILIKE '%Snow%'))
ORDER BY cards
LIMIT plains_limit::INTEGER)

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
	subtypes IS NULL AND
	supertypes ILIKE '%Basic%'
ORDER BY cards
LIMIT colorless_limit::INTEGER);


END; $T$ LANGUAGE 'plpgsql';


--SELECT * FROM snow_basic_land_function (500, 500, 500, 500, 500);