-- Artifact function

/**/


CREATE FUNCTION artifacts_function (
	artifacts_limit_v INTEGER,
	format_v em_format, 
	status_v em_status, 
	artifacts_rarity_floor em_rarity DEFAULT 'common',
	artifacts_rarity_ceiling em_rarity DEFAULT 'mythic',
	artifacts_colors_primary_exclude TEXT DEFAULT NULL,
	artifacts_colors_primary_include TEXT [] DEFAULT array[['B'], ['G'], ['U'], ['W'], ['R']],
	artifacts_colors_secondary TEXT [] DEFAULT NULL,
	artifacts_colors_exclude_include TEXT DEFAULT 'Exclude',
	artifacts_type_exclude TEXT DEFAULT NULL,
	artifacts_type_include TEXT DEFAULT NULL,
	artifacts_sub_exclude TEXT DEFAULT NULL,
	artifacts_sub_include TEXT [] DEFAULT array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']],
	artifacts_super_exclude TEXT DEFAULT NULL,
	artifacts_super_include TEXT [] DEFAULT array[['Legendary'],['Snow']])


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

	cards.rarity = ANY(enum_range(artifacts_rarity_floor::em_rarity, artifacts_rarity_ceiling::em_rarity)) AND

	((artifacts_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL OR cards.colors::TEXT ~* ANY (artifacts_colors_primary_include::TEXT[])) OR -- include all choosen including null
		(artifacts_colors_primary_exclude::TEXT IS NULL AND cards.colors::TEXT IS NULL AND artifacts_colors_primary_include::TEXT[] IS NULL) OR -- excludes non-null colors
		(artifacts_colors_primary_exclude::TEXT IS NOT NULL AND cards.colors::TEXT IS NOT NULL AND cards.colors::TEXT ~* ANY (artifacts_colors_primary_include::TEXT[]))) AND -- exclude null

	((artifacts_colors_exclude_include::TEXT ILIKE 'Exclude' AND (artifacts_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT !~* ALL (artifacts_colors_secondary::TEXT[]))) OR
		(artifacts_colors_exclude_include::TEXT ILIKE 'Include' AND (artifacts_colors_secondary::TEXT[] IS NULL OR cards.colors::TEXT ~* ANY (artifacts_colors_secondary::TEXT[])))) AND

	cards.types::TEXT NOT ILIKE '%Creature%' AND
	cards.types::TEXT NOT ILIKE '%Enchantment%' AND
	cards.types::TEXT NOT ILIKE '%Land%' AND

	((artifacts_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Artifact%' AND cards.types::TEXT ILIKE artifacts_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
		(artifacts_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Artifact' AND artifacts_type_include::TEXT IS NULL) OR -- Exclude tribal
		(artifacts_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Artifact%' AND cards.types::TEXT ILIKE artifacts_type_include::TEXT)) AND -- only tribal

	((artifacts_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (artifacts_sub_include::TEXT[])) OR --include all choosen including null 
		(artifacts_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND artifacts_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
		(artifacts_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (artifacts_sub_include::TEXT[]))) AND --exclude nulls

	((artifacts_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT  ~* ANY (artifacts_super_include::TEXT[])) OR --include legendary including null
		(artifacts_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND artifacts_super_include::TEXT[] IS NULL) OR --Exclude supertypes not null
		(artifacts_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT  ~* ANY (artifacts_super_include::TEXT[]))) --include legendary and exclude nulls 

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT artifacts_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


-- Function testing


-- Function Testing

-- Default

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal');

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic');

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']]);

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']], NULL, array[['Legendary'],['Snow']]);

-- 1000 random cards (not a default option), legacy format (not a default option), legal in format(not a default option), 
-- Rarities between common and mythic rare, includes all colored and null artifacts, excludes no colored and null artifacts
-- Includes all types, include all subtypes, includes all supertypes


-- Rarity options

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic');

-- Default 

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'uncommon', 'uncommon');

-- Only includes artifacts that are uncommon

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'rare');

-- Only includes artifacts with rarities that are between common and rare excludes mythic rares


-- Exclusion mode

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude');

-- Default

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black, green, or colorless, might have other colors as secondary colors.

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], NULL, 'Exclude');

-- Every card is either a black or green but not colorless, might have other colors as secondary colors.

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', 'Exclude Nulls', array[['B'], ['G']], array[['W'], ['R'], ['U']], 'Exclude');

-- Every card is either a black and/or green but not colorless, excludes white, red, and blue.

-- Inclusion mode

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B']], array[['W']], 'Include');

-- every card must contain black and white, might have other colors as secondary colors.


-- Types Options

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL);

-- Include all artifact types

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Exclude', NULL);

-- Exclude tribal artifact type

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', 'Include', '%Tribal%');

-- Include only tribal atrifact type

-- Subtypes

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']]);

-- Default

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment']]);

-- Includes all null subtypes and selected subtypes

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, NULL);

-- Excludes non-null subtypes (also excludes tribal type)

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	'Exclude', array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']]);

--Excludes null subtypes


--Supertypes

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']], NULL, array[['Legendary'],['Snow']]);

-- Default

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']], NULL, NULL);

-- Excludes non-null supertypes

SELECT * FROM artifacts_function (1000, 'legacy', 'Legal', 'common', 'mythic', NULL, array[['B'], ['G'], ['U'], ['W'], ['R']], NULL, 'Exclude', NULL, NULL,
	NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']], 'Include', array[['Legendary'],['Snow']]);

-- Excludes null supertypes



-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Artifact%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Enchantment%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Artifact%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Enchantment%';

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Artifact%';

