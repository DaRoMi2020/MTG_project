

-- Multi-Colored Land Function


CREATE FUNCTION multi_color_land_function(
	multi_color_land_limit_v INTEGER,
	format_v em_format, 
	status_v em_status,
	mcl_identity_primary TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	mcl_identity_secondary TEXT [] DEFAULT NULL, 
	mcl_identity_exclude_include TEXT DEFAULT 'Exclude')



RETURNS TABLE (card_name TEXT,
	card_id integer,
	card_colors TEXT,
	card_rarity em_rarity,
	cards_layout em_layout,
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
	cards.coloridentity,
	cards.rarity,
	cards.layout,
	cards.types,
	cards.subtypes,
	cards.supertypes,
	legalities.format, 
	legalities.status 
	FROM cards 
LEFT OUTER JOIN legalities 
ON cards.uuid = legalities.uuid
WHERE 
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	cards.layout != 'transform' AND
	cards.types::TEXT NOT ILIKE '%Creature%' AND
	cards.types::TEXT ILIKE '%Land%' AND
	coloridentity::TEXT <> ALL (array[['B'], ['G'], ['U'], ['W'], ['R']]) AND
	(mcl_identity_primary::TEXT[] ISNULL OR coloridentity::TEXT ~* ANY (mcl_identity_primary::TEXT[])) AND
	((mcl_identity_exclude_include::TEXT ILIKE 'Exclude' AND (mcl_identity_secondary::TEXT[] ISNULL OR coloridentity::TEXT !~* ALL (mcl_identity_secondary::TEXT[]))) OR
		(mcl_identity_exclude_include::TEXT ILIKE 'Include' AND (mcl_identity_secondary::TEXT[] ISNULL OR coloridentity::TEXT ~* ALL (mcl_identity_secondary::TEXT[]))))

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT multi_color_land_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

-- Exclusion mode

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal');

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', NULL);

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', NULL, NULL);

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G'], ['U'], ['W'], ['R']]);

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G'], ['U'], ['W'], ['R']], NULL);

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

--Includes all multi-colored mana production, no exclusion. Default.

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B']]);

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B']], NULL);

-- Every single land must have Black mana produciton, no exclusion

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']]);

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']], NULL);

-- Every single land must have Black or Green mana produciton but not both only, no exclusion

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']], array[['R']]);

-- Every single land must have Black or Green mana produciton but not both only, excludes red mana production

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']], array[['R'], ['W'], ['U']]);

-- Every single land must have Black AND Green mana produciton only, excludes red, white, and blue mana production

-----------------

-- Inclusion mode


SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', NULL, NULL, 'Include');

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Include');

-- Same as default of exclude mode, include variable has no effect

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B']], NULL, 'Include');

-- Every single land must have Black mana produciton, no required inclusion based on additional variable

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']], NULL, 'Include');

-- Every single land must have Black or Green mana produciton but not both only, no required inclusion based on additional variable

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']], array[['R']], 'Include');

-- Every single land must have Black or Green mana produciton but not both only, every single land must include Red mana

SELECT * FROM multi_color_land_function(1000, 'legacy', 'Legal', array[['B'], ['G']], array[['R'], ['W'], ['U']], 'Include');

-- Selects a 5 color land



-- Queries

SELECT DISTINCT ON (subtypes) subtypes, supertypes, coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT <> ALL (array[['B'], ['G'], ['U'], ['W'], ['R']]);

SELECT  subtypes, supertypes, coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT ~ ANY (array[['B'], ['G'], ['U'], ['W'], ['R']]);

SELECT DISTINCT ON (coloridentity) coloridentity, subtypes, types FROM cards WHERE types ILIKE 'Land' AND types  NOT ILIKE '%Creature%';

SELECT DISTINCT ON (supertypes) supertypes, subtypes, coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT <> ALL (array[['B'], ['G'], ['U'], ['W'], ['R']]);
