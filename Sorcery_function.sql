--Sorcery function

/**/


CREATE FUNCTION sorcery_function (
	sorcery_limit_v integer, 
	sorcery_rarity_v em_rarity,
	format_v em_format, 
	status_v em_status, 
	color_v TEXT,
	sorcery_types_exclude TEXT DEFAULT 'Sorcery',
	sorcery_types_include TEXT DEFAULT NULL,
	sorcery_subtype TEXT[] DEFAULT NULL,
	sorcery_supertype TEXT DEFAULT NULL)

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
	cards.colors::TEXT ILIKE color_v::TEXT AND
	cards.rarity = sorcery_rarity_v::em_rarity AND
	legalities.format = format_v::em_format AND 
	legalities.status = status_v::em_status AND

	((sorcery_type_exclude ILIKE 'Sorcery' AND cards.types::TEXT ILIKE 'Sorcery') OR 
		(sorcery_type_exclude::TEXT IS NULL AND cards.types::TEXT ILIKE sorcery_type_include::TEXT) OR 
		(sorcery_type_exclude::TEXT 'Sorcery' AND cards.types::TEXT ILIKE sorcery_type_include::TEXT)) AND 

	(sorcery_supertype::TEXT IS NULL OR cards.supertypes::TEXT ILIKE sorcery_supertype::TEXT)

ORDER BY (cards."name"))

SELECT * 
FROM A
ORDER BY random()
LIMIT sorcery_limit_v::integer;

END; $T$ LANGUAGE 'plpgsql';



	((sorcery_subtype_exclude IS NULL AND cards.subtypes::TEXT IS NULL) OR 
		(sorcery_subtypeb_exclude::TEXT IS NOT NULL AND cards.subtypes::TEXT ~* ANY (sorcery_subtype_include::TEXT[])) OR 
		(sorcery_subtype_exclude::TEXT IS NULL AND cards.subtypes::TEXT ~* ANY (sorcery_subtype_include::TEXT[]))) AND 

--SELECT * FROM sorcery_function (10, 'rare', 'legacy', 'Legal', 'B');

--SELECT * FROM sorcery_function (10, 'rare', 'legacy', 'Legal', 'B', '%Sorcery%');

--SELECT * FROM sorcery_function (10, 'common', 'legacy', 'Legal', 'B', '%Sorcery%', '%Tribal%');

--SELECT * FROM sorcery_function (10, 'rare', 'legacy', 'Legal', 'B', '%Sorcery%', '%Tribal%', array[['Faerie']]);

--SELECT * FROM sorcery_function (10, 'rare', 'legacy', 'Legal', 'B', 'Sorcery', NULL, array[['Arcane']]);

--SELECT * FROM sorcery_function (10, 'rare', 'legacy', 'Legal', 'B', 'Sorcery', NULL, NULL, 'Legendary');

--DROP FUNCTION sorcery_function (INTEGER, em_rarity, em_format, em_status, TEXT, TEXT, TEXT, TEXT[], TEXT);