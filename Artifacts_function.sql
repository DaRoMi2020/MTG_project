Artifact function

/**/


CREATE FUNCTION artifacts_function (
	artifacts_limit_v INTEGER, 
	artifacts_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
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
((cards.colors::TEXT ILIKE color_v::TEXT) OR (cards.colors::TEXT IS NULL AND color_v::TEXT IS NULL))  AND
cards.rarity = artifacts_rarity_v::em_rarity AND
cards.types::TEXT NOT ILIKE '%Creature%' AND
cards.types::TEXT NOT ILIKE '%Enchantment%' AND
cards.types::TEXT NOT ILIKE '%Land%' AND
cards.types::TEXT NOT ILIKE '%Hero%' AND
legalities.format = format_v::em_format AND 
legalities.status = status_v::em_status AND


((artifacts_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Artifact%' AND cards.types::TEXT ILIKE artifacts_type_include::TEXT IS NULL) OR -- Include or exclude tribal depending on subtype selection, 
	(artifacts_type_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Artifact' AND artifacts_type_include::TEXT IS NULL) OR -- Exclude tribal
	(artifacts_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Artifact%' AND cards.types::TEXT ILIKE artifacts_type_include::TEXT)) AND -- only tribal

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

SELECT * FROM artifacts_function (1000, 'uncommon', 'legacy', 'Legal', NULL); 

SELECT * FROM artifacts_function (1000, 'uncommon', 'legacy', 'Legal', NULL, NULL, NULL, NULL, array[['Equipment'],['Food'], ['Fortification'], ['Vehicle']], NULL, array[['Legendary'],['Snow']]);

-- Includes all artifacts, includes all subtypes, includes all supertypes (default)

SELECT * FROM artifacts_function (1000, 'uncommon', 'legacy', 'Legal', NULL, 'exclude'); 

-- Excludes tribal, includes all subtypes, includes all supertypes 

SELECT * FROM artifacts_function (1000, 'uncommon', 'legacy', 'Legal', NULL, NULL, '%Tribal%'); 

-- Include only tribal artifact, includes only tribal subtypes, includes all supertypes 

SELECT * FROM artifacts_function (1000, 'uncommon', 'legacy', 'Legal', NULL, NULL, NULL, 'include', array[['Equipment']]); 

-- Includes all artifacts, includes only equipment, includes all supertypes 

SELECT * FROM artifacts_function (1000, 'uncommon', 'legacy', 'Legal', NULL, NULL, NULL, NULL, NULL, NULL, NULL); 

-- Excludes tribal type based on excluding subtype, excludes all subtypes, excludes all non-null supertypes 


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Artifact%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Enchantment%' AND types NOT ILIKE '%Hero%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Artifact%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Enchantment%' AND types NOT ILIKE '%Hero%';

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Artifact%';

