
-- Non-Basic Land 

CREATE FUNCTION non_basic_land_function(
	non_basic_land_limit_v INTEGER, 
	non_basic_land_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status,
	non_basic_land_types_exclude TEXT DEFAULT NULL,
	non_basic_land_types_include TEXT DEFAULT NULL,
	non_basic_land_super_exclude TEXT DEFAULT NULL,
	non_basic_land_super_include TEXT [] DEFAULT ARRAY[['Legendary'],['Snow']],
	non_basic_color_identity_exclude TEXT DEFAULT NULL,
	non_basic_color_identity_include TEXT [] DEFAULT ARRAY[['B'], ['G'], ['R'], ['U'], ['W']])



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
	cards.coloridentity,
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
	cards.rarity = non_basic_land_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND
	cards.types::TEXT NOT ILIKE '%Creature%' AND

((non_basic_land_types_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE '%Land%' AND non_basic_land_types_include::TEXT IS NULL) OR --include all creatures types depending on subtype options
	(non_basic_land_types_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE 'Land' AND non_basic_land_types_include::TEXT IS NULL) OR -- default excludes non-basic creature types
	(non_basic_land_types_exclude::TEXT IS NOT NULL AND cards.types::TEXT ILIKE '%Land%' AND cards.types::TEXT  ILIKE non_basic_land_types_include::TEXT)) AND -- includes basic creature types and added types

	((non_basic_land_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ~* ANY (non_basic_land_super_include::TEXT[]) AND cards.supertypes::TEXT !~* ANY (array[['Basic'], ['Basic,Snow']])) OR --include all choosen including null
		(non_basic_land_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND non_basic_land_super_include::TEXT[] IS NULL) OR --Exclude supertypes not null
		(non_basic_land_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ~* ANY (non_basic_land_super_include::TEXT[]) AND cards.supertypes::TEXT !~* ANY (array[['Basic'], ['Basic,Snow']]))) AND --include all choosen and exclude nulls 

	((non_basic_color_identity_exclude::TEXT IS NULL AND cards.coloridentity::TEXT IS NULL OR cards.coloridentity::TEXT = ANY (non_basic_color_identity_include::TEXT [])) OR -- include all choosen including null
		(non_basic_color_identity_exclude::TEXT IS NULL AND cards.coloridentity::TEXT IS NULL AND non_basic_color_identity_include::TEXT[] IS NULL) OR -- excludes non-null color identities
		(non_basic_color_identity_exclude::TEXT IS NOT NULL AND cards.coloridentity::TEXT IS NOT NULL AND cards.coloridentity::TEXT = ANY (non_basic_color_identity_include::TEXT []))) -- exclude null

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT non_basic_land_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';


--------------------------------------


-- Function Testing

SELECT * FROM non_basic_land_function(1000, 'common', 'legacy', 'Legal');

SELECT * FROM non_basic_land_function(1000, 'rare', 'legacy', 'Legal', NULL, NULL);

SELECT * FROM non_basic_land_function(1000, 'rare', 'legacy', 'Legal', NULL, NULL, NULL,  ARRAY[['Legendary'],['Snow']]);

SELECT * FROM non_basic_land_function(1000, 'rare', 'legacy', 'Legal', NULL, NULL, NULL,  ARRAY[['Legendary'],['Snow']], NULL, ARRAY[['B'], ['G'], ['R'], ['U'], ['W']]);

-- Includes all non-Basic lands types, includes all supertypes, includes colored mana production, default

SELECT * FROM non_basic_land_function(1000, 'common', 'legacy', 'Legal', 'Exclude', '%Artifact%');

-- Includes only artifact non-Basic land type, excludes all non-null supertypes based on data, includes colored mana production

SELECT * FROM non_basic_land_function(1000, 'rare', 'legacy', 'Legal', NULL, NULL, NULL, NULL);

-- Includes all non-Basic lands types, excludes non-nulls supertypes, includes colored mana production

SELECT * FROM non_basic_land_function(1000, 'rare', 'legacy', 'Legal', NULL, NULL, 'Exclude', ARRAY[['Legendary'],['Snow']]);

-- Includes all non-Basic lands types, excludes nulls supertypes, includes colored mana production

SELECT * FROM non_basic_land_function(1000, 'uncommon', 'legacy', 'Legal', NULL, NULL, NULL,  ARRAY[['Legendary'],['Snow']], NULL, NULL);

-- Includes all non-Basic lands types, includes all supertypes, excludes colored mana production

SELECT * FROM non_basic_land_function(1000, 'uncommon', 'legacy', 'Legal', NULL, NULL, NULL,  ARRAY[['Legendary'],['Snow']], 'Exclude', ARRAY[['B'], ['G'], ['R'], ['U'], ['W']]);

-- Includes all non-Basic lands types, includes all supertypes, excludes colorless mana production


-----------------------------------


-- Query Type, Subtypes, Supertypes

SELECT DISTINCT ON (types) types, subtypes, supertypes FROM cards  WHERE types ILIKE '%Land%';

SELECT DISTINCT ON (subtypes) subtypes, supertypes, types FROM cards WHERE types ILIKE '%Land%';

SELECT DISTINCT ON (supertypes) supertypes, subtypes, types FROM cards WHERE types ILIKE '%Land%' AND supertypes NOT ILIKE '%Basic%';


