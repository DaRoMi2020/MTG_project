-- Sorceries function


/**/


CREATE FUNCTION sorceries_function (
	sorceries_limit_v integer,
	format_v em_format, 
	status_v em_status,
	sorceries_rarity_floor em_rarity DEFAULT 'common',
	sorceries_rarity_ceiling em_rarity DEFAULT 'mythic',
	sorceries_colors_primary_exclude TEXT DEFAULT NULL,
	sorceries_colors_primary_include TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	sorceries_colors_secondary TEXT [] DEFAULT NULL,
	sorceries_colors_exclude_include TEXT DEFAULT 'Exclude',
	sorceries_type_exclude TEXT DEFAULT NULL,
	sorceries_type_include TEXT DEFAULT NULL,
	sorceries_sub_exclude TEXT DEFAULT NULL,
	sorceries_sub_include TEXT[] DEFAULT array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], 
	['Goblin'], ['Merfolk'], ['Rogue']],
	sorceries_super_exclude TEXT DEFAULT NULL,
	sorceries_super_include TEXT DEFAULT 'Legendary')

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

	cards.rarity = ANY(enum_range(sorceries_rarity_floor::em_rarity, sorceries_rarity_ceiling::em_rarity)) AND

	((sorceries_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL OR cards.colors::TEXT ~* ANY (sorceries_colors_primary_include::TEXT[])) OR -- include all choosen including null
		(sorceries_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL AND sorceries_colors_primary_include::TEXT[] IS NULL) OR -- excludes non-null colors
		(sorceries_colors_primary_exclude::TEXT IS NOT NULL AND cards.colors::TEXT IS NOT NULL AND cards.colors::TEXT ~* ANY (sorceries_colors_primary_include::TEXT[]))) AND -- exclude null

	((sorceries_colors_exclude_include::TEXT ILIKE 'Exclude' AND (sorceries_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT !~* ALL (sorceries_colors_secondary::TEXT[]))) OR
		(sorceries_colors_exclude_include::TEXT ILIKE 'Include' AND (sorceries_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT ~* ANY (sorceries_colors_secondary::TEXT[])))) AND

	((sorceries_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Sorcery%' AND cards.types::TEXT ILIKE sorceries_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
		(sorceries_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Sorcery' AND sorceries_type_include::TEXT IS NULL) OR -- Exclude tribal
		(sorceries_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Sorcery%' AND cards.types::TEXT ILIKE sorceries_type_include::TEXT)) AND -- only tribal

	((sorceries_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (sorceries_sub_include::TEXT[])) OR --include all choosen including null 
		(sorceries_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND sorceries_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
		(sorceries_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (sorceries_sub_include::TEXT[]))) AND --exclude nulls

	((sorceries_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ILIKE sorceries_super_include::TEXT) OR --include legendary including null
		(sorceries_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND sorceries_super_include::TEXT IS NULL) OR --Exclude supertypes not null
		(sorceries_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ILIKE sorceries_super_include::TEXT)) --include legendary and exclude nulls

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT sorceries_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

-- Default

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal');

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic');

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']]);

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']], NULL, 'Legendary');

-- 1000 random cards (not a default option), legacy format (not a default option), legal in format(not a default option), 
-- Rarities between common and mythic rare, includes all colored and null sorceries, excludes no colored and null sorceries
-- Includes all types, include all subtypes, includes all supertypes


-- Rarity options

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic');

-- Default 

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'uncommon', 'uncommon');

-- Only includes enchantments that are uncommon

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'rare');

-- Only includes enchantments with rarities that are between common and rare excludes mythic rares


-- Exclusion mode

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

-- Default

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black, green, or colorless, might have other colors as secondary colors.

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black or green but not colorless, might have other colors as secondary colors.

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], array[['W'], ['R'], ['U']], 'Exclude');

-- Every card is either a black and/or green but not colorless, excludes white, red, and blue.

-- Inclusion mode

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B']], array[['G']], 'Include');

-- every card must contain black and green, might have other colors as secondary colors.


-- Types options

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

-- Include all sorcery types

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Exclude', NULL);

-- Exclude tribal sorcery type

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Include', '%Tribal%');

-- Include only tribal sorcery type


-- Subtypes

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']]);

-- Default

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane']]);

-- Includes all null subtypes and selected subtypes

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, NULL);

-- Excludes non-null subtypes (also excludes tribal type)

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	'Exclude', array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']]);

--Excludes null subtypes


--Supertypes Options

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']], NULL, 'Legendary');

-- Default

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']], NULL, NULL);

-- Excludes non-null supertypes

SELECT * FROM sorceries_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Adventure'], ['Arcane'], ['Eldrazi'], ['Elemental'], ['Elf'], ['Giant'], ['Goblin'], ['Merfolk'], ['Rogue']], 'Include', 'Legendary');

-- Excludes null supertypes



-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Sorcery%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Sorcery%'; 

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Sorcery%';

SELECT * FROM sorceries_function (1000, 'rare', 'legacy', 'Legal', 'G', NULL, NULL, NULL, array[['Adventure'], ['Arcane']], NULL, 'Legendary');