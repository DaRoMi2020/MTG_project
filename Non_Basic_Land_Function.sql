
-- Non-Basic Land 


CREATE FUNCTION non_basic_land_function(
	non_basic_land_limit_v INTEGER, 
	non_basic_land_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status,
	non_basic_color_identity_exclude TEXT DEFAULT NULL,
	non_basic_color_identity_include TEXT [] DEFAULT array[['B'], ['G'], ['R'], ['U'], ['W']],
	non_basic_land_super_exclude TEXT DEFAULT NULL,
	non_basic_land_super_include TEXT [] DEFAULT array[['Legendary'],['Snow']])



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
	((non_basic_color_identity_exclude::TEXT IS NULL AND cards.coloridentity::TEXT IS NULL OR cards.coloridentity::TEXT = ANY (non_basic_color_identity_include::TEXT[])) OR -- include all choosen including null
		(non_basic_color_identity_exclude::TEXT IS NULL AND cards.coloridentity::TEXT IS NULL AND cards.coloridentity::TEXT[] IS NULL) OR -- excludes non-null color identities
		(non_basic_color_identity_exclude::TEXT IS NOT NULL AND cards.coloridentity::TEXT IS NOT NULL AND cards.coloridentity::TEXT ~* ANY (non_basic_color_identity_include::TEXT[]))) AND-- exclude nulls
	cards.types::TEXT NOT ILIKE '%Creature%' AND
	cards.types::TEXT ILIKE '%Land%' AND
	cards.supertypes::TEXT NOT ILIKE '%Basic%' AND
	((non_basic_land_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL OR cards.supertypes::TEXT ~* ANY (non_basic_land_super_include::TEXT[])) OR --include all choosen including null
		(non_basic_land_super_exclude::TEXT IS NULL AND cards.supertypes::TEXT IS NULL AND non_basic_land_super_include::TEXT[] IS NULL) OR --Exclude supertypes not null
		(non_basic_land_super_exclude::TEXT IS NOT NULL AND cards.supertypes::TEXT IS NOT NULL AND cards.supertypes::TEXT ~* ANY (non_basic_land_super_include::TEXT[]))) --include all choosen and exclude nulls 


ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT non_basic_land_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';

SELECT DISTINCT ON (subtypes) subtypes, supertypes, types FROM cards WHERE types ILIKE '%Land%' AND supertypes NOT ILIKE '%Basic%';

SELECT * FROM non_basic_land_function(10, 'rare', 'legacy', 'Legal');

SELECT DISTINCT ON (types) types FROM cards WHERE types ILIKE '%Land%' ;

SELECT DISTINCT ON (subtypes) subtypes, types FROM cards WHERE types ILIKE '%Land%' ;


SELECT DISTINCT ON (coloridentity) coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT ~* ALL (array[['B'], ['G'], ['U'], ['W'], ['R'], [NULL]]);

SELECT DISTINCT ON (coloridentity) coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT ~* ANY (array['B', 'G', 'U', 'W', 'R', NULL]);

SELECT DISTINCT ON (coloridentity) coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT ~* ANY (array['{"B"}', '{"G"}', '{"U"}', '{"W"}', '{"R"}', '{NULL}']);

SELECT DISTINCT ON (coloridentity) coloridentity, types FROM cards WHERE types ILIKE 'Land' AND coloridentity::TEXT = ANY ('{"B"}', NULL);



