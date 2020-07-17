
-- Basic Land function

/**/


CREATE FUNCTION basic_land_function ( 
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


-- Function Testing


-- Default

SELECT * FROM basic_land_function ();

SELECT * FROM basic_land_function (0);

SELECT * FROM basic_land_function (0, 0);

SELECT * FROM basic_land_function (0, 0, 0);

SELECT * FROM basic_land_function (0, 0, 0, 0);

SELECT * FROM basic_land_function (0, 0, 0, 0, 0);

SELECT * FROM basic_land_function (0, 0, 0, 0, 0, 0);

SELECT * FROM basic_land_function (0, 0, 0, 0, 0, 0, 'Include');

-- Include no basic lands, Include snow lands


-- Swamps

SELECT * FROM basic_land_function (10);

SELECT * FROM basic_land_function (10, 0, 0, 0, 0, 0, 'Include');

-- 10 basic swamps, Include snow lands

SELECT * FROM basic_land_function (10, 0, 0, 0, 0, 0, 'Exclude');

-- 10 basic swamps, Exclude snow lands

SELECT * FROM basic_land_function (10, 0, 0, 0, 0, 0, 'Snow Only');

-- 10 basic swamps, Exclude snow lands


-- Forests

SELECT * FROM basic_land_function (0, 10);

SELECT * FROM basic_land_function (0, 10, 0, 0, 0, 0, 'Include');

-- 10 basic forests, Include snow lands

SELECT * FROM basic_land_function (0, 10, 0, 0, 0, 0, 'Exclude');

-- 10 basic forests, Exclude snow lands

SELECT * FROM basic_land_function (0, 10, 0, 0, 0, 0, 'Snow Only');

-- 10 basic forests, Exclude snow lands


-- Islands

SELECT * FROM basic_land_function (0, 0, 10);

SELECT * FROM basic_land_function (0, 0, 10, 0, 0, 0, 'Include');

-- 10 basic islands, Include snow lands

SELECT * FROM basic_land_function (0, 0, 10, 0, 0, 0, 'Exclude');

-- 10 basic islands, Exclude snow lands

SELECT * FROM basic_land_function (0, 0, 10, 0, 0, 0, 'Snow Only');

-- 10 basic islands, Exclude snow lands


-- Mountains 

SELECT * FROM basic_land_function (0, 0, 0, 10);

SELECT * FROM basic_land_function (0, 0, 0, 10, 0, 0, 'Include');

-- 10 basic mountains, Include snow lands

SELECT * FROM basic_land_function (0, 0, 0, 10, 0, 0, 'Exclude');

-- 10 basic mountains, Exclude snow lands

SELECT * FROM basic_land_function (0, 0, 0, 10, 0, 0, 'Snow Only');

-- 10 basic mountains, Exclude snow lands


-- Plains

SELECT * FROM basic_land_function (0, 0, 0, 0, 10);

SELECT * FROM basic_land_function (0, 0, 0, 0, 10, 0, 'Include');

-- 10 basic plains, Include snow lands

SELECT * FROM basic_land_function (0, 0, 0, 0, 10, 0, 'Exclude');

-- 10 basic plains, Exclude snow lands

SELECT * FROM basic_land_function (0, 0, 0, 0, 10, 0, 'Snow Only');

-- 10 basic plains, Exclude snow lands


-- Colorless

SELECT * FROM basic_land_function (0, 0, 0, 0, 0, 10);

SELECT * FROM basic_land_function (0, 0, 0, 0, 0, 10, 'Include');

-- 10 basic colorless, Include snow lands (no colorless snow lands)


-- mix of lands

SELECT * FROM basic_land_function (10, 10, 10, 10, 10, 10);

SELECT * FROM basic_land_function (10, 10, 10, 10, 10, 10, 'Include');

-- 10 of each basic land type, Include snow lands

SELECT * FROM basic_land_function (10, 10, 10, 10, 10, 10, 'Exclude');

-- 10 of each basic land type, Exclude snow lands

SELECT * FROM basic_land_function (10, 10, 10, 10, 10, 0, 'Snow Only');

-- 10 of each basic land type except colorless, Only snow lands




