
-- Instant function


/**/


CREATE FUNCTION instants_function (
	instants_limit_v INTEGER,
	format_v em_format, 
	status_v em_status,
	instants_rarity_floor em_rarity DEFAULT 'common',
	instants_rarity_ceiling em_rarity DEFAULT 'mythic',
	instants_colors_primary_exclude TEXT DEFAULT NULL,
	instants_colors_primary_include TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	instants_colors_secondary TEXT [] DEFAULT NULL,
	instants_colors_exclude_include TEXT DEFAULT 'Exclude', 
	instants_type_exclude TEXT DEFAULT NULL,
	instants_type_include TEXT DEFAULT NULL,
	instants_sub_exclude TEXT DEFAULT NULL,
	instants_sub_include TEXT[] DEFAULT array[['Adventure'], ['Angel'], ['Arcane'], ['Eldrazi'], ['Elf'],
	['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Rogue'], ['Shapeshifter'], ['Trap'], ['Treefolk']])

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
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

	cards.rarity = ANY(enum_range(instants_rarity_floor::em_rarity, instants_rarity_ceiling::em_rarity)) AND

	((instants_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL OR cards.colors::TEXT ~* ANY (instants_colors_primary_include::TEXT[])) OR -- include all choosen including null
		(instants_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL AND instants_colors_primary_include::TEXT[] IS NULL) OR -- excludes non-null colors
		(instants_colors_primary_exclude::TEXT IS NOT NULL AND cards.colors::TEXT IS NOT NULL AND cards.colors::TEXT = ANY (instants_colors_primary_include::TEXT[]))) AND -- exclude null

	((instants_colors_exclude_include::TEXT ILIKE 'Exclude' AND (instants_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT !~* ALL (instants_colors_secondary::TEXT[]))) OR
		(instants_colors_exclude_include::TEXT ILIKE 'Include' AND (instants_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT ~* ANY (instants_colors_secondary::TEXT[])))) AND

	((instants_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Instant%' AND cards.types::TEXT ILIKE instants_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
		(instants_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Instant' AND instants_type_include::TEXT IS NULL) OR -- Exclude tribal
		(instants_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Instant%' AND cards.types::TEXT ILIKE instants_type_include::TEXT)) AND -- only tribal

	((instants_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (instants_sub_include::TEXT[])) OR --include all choosen including null 
		(instants_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND instants_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
		(instants_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (instants_sub_include::TEXT[])))--exclude nulls

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT instants_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';

--------------------------------------


-- Function Testing


-------------------

-- Default

SELECT * FROM instants_function (1000, 'legacy', 'Legal');

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic');

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL, 
	NULL, array[['Adventure'], ['Angel'], ['Arcane'], ['Eldrazi'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Rogue'], ['Shapeshifter'], ['Trap'], ['Treefolk']]);

-- 1000 random cards (not a default option), legacy format (not a default option), legal in format(not a default option), 
-- Rarities between common and mythic rare, includes all colored and null instants, excludes no colored and null instants
-- Includes all types, include all subtypes


-- Rarity options

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic');

-- Default

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'uncommon', 'uncommon'); 

-- Only includes instants that are uncommon

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'rare'); 

-- Only includes instants with rarities that are between common and rare excludes mythic rares


-- Color options

-- Exclusion mode

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black, green, or colorless instant, might have other colors as secondary colors.

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black or green but not colorless, does not explicitly exclude any color

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], array[['W'], ['R'], ['U']], 'Exclude');

-- Every card is either a black and/or green but not colorless, excludes white, red, and blue.

-- Inclusion mode

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B']], array[['G']], 'Include');

-- every card must contain black and green other colors possible. 


-- Types options

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

-- includes all instants types

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Exclude', NULL);

-- excludes instant types not null

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Include', '%Tribal%');

-- only includes tribal instants types and subsequent subtypes


-- Subtypes options

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL, 
	NULL, array[['Adventure'], ['Angel'], ['Arcane'], ['Eldrazi'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Rogue'], ['Shapeshifter'], ['Trap'], ['Treefolk']]);

-- include all subtypes (default)

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL, 
	NULL, array[['Adventure'], ['Arcane'], ['Trap']]);

-- includes all null subtypes and selected subtypes

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL, 
	'Exclude', array[['Adventure'], ['Angel'], ['Arcane'], ['Eldrazi'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Rogue'], ['Shapeshifter'], ['Trap'], ['Treefolk']]);

-- Excludes non-null subtypes (also excludes tribal type)

SELECT * FROM instants_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL, NULL, NULL);

-- Excludes null subtypes 


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Instant%' 
AND types NOT ILIKE '%Creature%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Instant%' AND  types NOT ILIKE '%Creature%'; 

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Instant%' AND NOT ILIKE '%Creature%';

SELECT name, types, subtypes, rarity, colors FROM cards WHERE types ILIKE '%Instant%' AND types NOT ILIKE '%Creature%' AND types ILIKE '%Tribal%';
