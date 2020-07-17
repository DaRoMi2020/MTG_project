
-- Enchantment function

/**/


CREATE FUNCTION enchantments_function (
	enchantments_limit_v INTEGER, 
	format_v em_format, 
	status_v em_status,
	enchantments_rarity_floor em_rarity DEFAULT 'common',
	enchantments_rarity_ceiling em_rarity DEFAULT 'mythic',
	enchantments_colors_primary_exclude TEXT DEFAULT NULL,
	enchantments_colors_primary_include TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	enchantments_colors_secondary TEXT [] DEFAULT NULL,
	enchantments_colors_exclude_include TEXT DEFAULT 'Exclude', 
	enchantments_type_exclude TEXT DEFAULT NULL,
	enchantments_type_include TEXT DEFAULT NULL,
	enchantments_sub_exclude TEXT DEFAULT NULL,
	enchantments_sub_include TEXT[] DEFAULT array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'],
	['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']],
	enchantments_super_exclude TEXT DEFAULT NULL,
	enchantments_super_include TEXT[] DEFAULT array[['Legendary'],['Snow'], ['World']])


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
SELECT DISTINCT ON 
	(cards."name") cards."name", 
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

	cards.rarity = ANY(enum_range(enchantments_rarity_floor::em_rarity, enchantments_rarity_ceiling::em_rarity)) AND

	((enchantments_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL OR cards.colors::TEXT ~* ANY (enchantments_colors_primary_include::TEXT[])) OR -- include all choosen including null
		(enchantments_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL AND enchantments_colors_primary_include::TEXT[] IS NULL) OR -- excludes non-null colors
		(enchantments_colors_primary_exclude::TEXT IS NOT NULL AND cards.colors::TEXT IS NOT NULL AND cards.colors::TEXT ~* ANY (enchantments_colors_primary_include::TEXT[]))) AND -- exclude null

	((enchantments_colors_exclude_include::TEXT ILIKE 'Exclude' AND (enchantments_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT !~* ALL (enchantments_colors_secondary::TEXT[]))) OR
		(enchantments_colors_exclude_include::TEXT ILIKE 'Include' AND (enchantments_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT ~* ANY (enchantments_colors_secondary::TEXT[])))) AND

	cards.types::TEXT NOT ILIKE '%Creature%' AND
	cards.types::TEXT NOT ILIKE '%Artifact%' AND
	cards.types::TEXT NOT ILIKE '%Land%' AND

	((enchantments_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Enchantment%' AND cards.types::TEXT ILIKE enchantments_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
		(enchantments_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Enchantment' AND enchantments_type_include::TEXT IS NULL) OR -- Exclude tribal
		(enchantments_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Enchantment%' AND cards.types::TEXT ILIKE enchantments_type_include::TEXT)) AND -- only tribal

	((enchantments_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (enchantments_sub_include::TEXT[])) OR --include all choosen including null 
		(enchantments_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND enchantments_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
		(enchantments_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (enchantments_sub_include::TEXT[]))) AND --exclude nulls

	((enchantments_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ~* ANY (enchantments_super_include::TEXT[])) OR --include all choosen including null
		(enchantments_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND enchantments_super_include::TEXT[] IS NULL) OR --Exclude subtypes not null
		(enchantments_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ~* ANY (enchantments_super_include::TEXT[]))) --include all choosen and exclude nulls 

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT enchantments_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

-- Default

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal');

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic');

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']]);

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']],
	NULL, array[['Legendary'],['Snow'], ['World']]);

-- 1000 random cards (not a default option), legacy format (not a default option), legal in format(not a default option), 
-- Rarities between common and mythic rare, includes all colored and null enchantments, excludes no colored and null enchantments
-- Includes all types, include all subtypes, includes all supertypes


-- Rarity options

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic');

-- Default 

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'uncommon', 'uncommon');

-- Only includes enchantments that are uncommon

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'rare');

-- Only includes enchantments with rarities that are between common and rare excludes mythic rares


-- Exclusion mode

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

-- Default

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black, green, or colorless, might have other colors as secondary colors.

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black or green but not colorless, might have other colors as secondary colors.

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], array[['W'], ['R'], ['U']], 'Exclude');

-- Every card is either a black and/or green but not colorless, excludes white, red, and blue.

-- Inclusion mode

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B']], array[['G']], 'Include');

-- every card must contain black and green, might have other colors as secondary colors.


-- Types options

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

-- Include all enchantment types

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Exclude', NULL);

-- Exclude tribal enchantment type

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Include', '%Tribal%');

-- Include only tribal enchantment type


-- Subtypes

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']]);

-- Default

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Saga'], ['Shrine']]);

-- Includes all null subtypes and selected subtypes

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, NULL);

-- Excludes non-null subtypes (also excludes tribal type)

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	'Exclude', array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']]);

--Excludes null subtypes


--Supertypes options

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']],
	NULL, array[['Legendary'],['Snow'], ['World']]);

-- Default

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']],
	NULL, NULL);

-- Excludes non-null supertypes

SELECT * FROM enchantments_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Aura'], ['Elemental'], ['Elf'], ['Faerie'], ['Giant'], ['Goblin'], ['Kithkin'], ['Merfolk'], ['Saga'], ['Shrine']],
	'Include', array[['Legendary'],['Snow'], ['World']]);

-- Excludes null supertypes


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Enchantment%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Artifact%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Enchantment%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Artifact%';

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Enchantment%';

SELECT name, types, subtypes, rarity, colors FROM cards WHERE types ILIKE '%Enchantment%' AND types ILIKE '%Tribal%';
