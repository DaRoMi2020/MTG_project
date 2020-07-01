--Artifact function

/**/


CREATE FUNCTION artifacts_function (
	artifacts_limit_v INTEGER, 
	artifacts_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	artifacts_type_exclude TEXT DEFAULT 'Artifact',
	artifacts_type_include TEXT DEFAULT NULL,
	artifacts_sub_exclude TEXT DEFAULT NULL,
	artifacts_sub_include TEXT[] DEFAULT NULL,
	artifacts_super_exclude TEXT DEFAULT NULL,
	artifacts_super_include TEXT DEFAULT NULL)


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


((artifacts_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Artifact%' AND cards.types::TEXT ILIKE artifacts_type_include::TEXT IS NULL) OR --include all artifacts
	(cards.types::TEXT ILIKE artifacts_type_exclude::TEXT AND artifacts_type_include::TEXT IS NULL) OR --default exclude: Exclude tribal
	(artifacts_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Artifact%' AND cards.types::TEXT ILIKE artifacts_type_include::TEXT)) AND --only tribal

((artifacts_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL OR cards.subtypes::TEXT ~* ANY (artifacts_sub_include::TEXT[])) OR --include all choosen including null 
	(artifacts_sub_exclude::TEXT IS NULL AND cards.subtypes::TEXT IS NULL AND artifacts_sub_include::TEXT[] IS NULL) OR --Exclude subtypes not null
	(artifacts_sub_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (artifacts_sub_include::TEXT[]))) AND --exclude nulls

((artifacts_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ILIKE artifacts_super_include::TEXT) OR --include legendary including null
	(artifacts_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND artifacts_super_include::TEXT IS NULL) OR --Exclude supertypes not null
	(artifacts_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ILIKE artifacts_super_include::TEXT)) --include legendary and exclude nulls 

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT artifacts_limit_v::INTEGER;

END; $T$ LANGUAGE 'plpgsql';


--Function testing

DROP FUNCTION artifacts_function(INTEGER, em_rarity, em_format, em_status, TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT);

SELECT * FROM artifacts_function (10, 'uncommon', 'legacy', 'Legal', NULL); 
-- Excludes tribal artifacts, exclude subtypes not null, excludes supertypes not null

SELECT * FROM artifacts_function (10, 'uncommon', 'legacy', 'Legal', NULL, NULL, '%Tribal%'); 
-- Excludes all artifacts but tribal

SELECT * FROM artifacts_function (10, 'uncommon', 'legacy', 'Legal', NULL, NULL, '%Tribal%', NULL, array[['Equipment']]); 
-- Includes only tribal artifacts, includes Normal and Equipment subtype, excludes supertypes not null

SELECT * FROM artifacts_function (10, 'uncommon', 'legacy', 'Legal', NULL, NULL, NULL, NULL, array[['Equipment']], 'Exclude', 'Legendary'); 
-- Excludes tribal type, includes normal and Equipment subtype, includes only legendary supertype 




Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes FROM cards WHERE types ILIKE '%Artifact%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Enchantment%' AND types NOT ILIKE '%Hero%';

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Artifact%' 
AND types NOT ILIKE '%Creature%' AND types NOT ILIKE '%Land%' AND types NOT ILIKE '%Enchantment%' AND types NOT ILIKE '%Hero%';

SELECT DISTINCT ON (supertypes) supertypes, types, subtypes FROM cards WHERE types ILIKE '%Artifact%';

