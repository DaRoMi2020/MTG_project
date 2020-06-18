CREATE SCHEMA "MTG_SCHEMA";

SET search_path TO "MTG_SCHEMA", public;

****

CREATE TYPE "MTG_SCHEMA".em_typesets AS ENUM ('core', 'expansion', 'masters', 'memorabilia', 'starter', 'archenemy', 'box', 'draft_innovation', 'commander', 'funny', 'duel_deck', 'from_the_vault', 'masterpiece', 'promo', 'premium_deck', 'planechase', 'token', 'vanguard', 'treasure_chest', 'spellbook');

CREATE TABLE "MTG_SCHEMA".sets (
	"index" INTEGER,
	id SERIAL PRIMARY KEY,
	baseSetSize INTEGER,
	block TEXT,
	boosterV3 TEXT,
	code TEXT UNIQUE NOT NULL,
	codeV3 TEXT,
	isFoilOnly BOOLEAN NOT NULL,
	isForeignOnly BOOLEAN NOT NULL,
	isOnlineOnly BOOLEAN NOT NULL,
	isPartialPreview BOOLEAN NOT NULL,
	keyruneCode TEXT,
	mcmId NUMERIC,
	mcmName TEXT,
	meta TEXT,
	mtgoCode TEXT,
	"name" TEXT, 
	parentCode TEXT, 
	releaseDate DATE,
	tcgplayerGroupID NUMERIC,
	TotalSetSize INTEGER,
	"type" "MTG_SCHEMA".em_typesets
	);


 **********


CREATE TYPE "MTG_SCHEMA".em_border AS ENUM ('black', 'white', 'borderless', 'silver', 'gold');

CREATE TYPE "MTG_SCHEMA".em_frame_effect AS ENUM ('nyxtouched', 'miracle', 'legendary', 'devoid', 'draft', 'sunmoondfc', 'extendedart', 'showcase', 'inverted', 'mooneldrazidfc', 'tombstone', 'companion', 'originpwdfc', 'colorshifted', 'compasslanddfc', 'nyxborn');

CREATE TYPE "MTG_SCHEMA".em_frame_version AS ENUM ('2003', '1993', '2015', '1997', 'future');

CREATE TYPE "MTG_SCHEMA".em_layout AS ENUM ('normal', 'aftermath', 'split', 'flip', 'leveler', 'saga', 'vanguard', 'transform', 'adventure', 'meld', 'scheme', 'planar', 'host', 'augment');

CREATE TYPE "MTG_SCHEMA".em_rarity AS ENUM ('rare', 'uncommon', 'common', 'mythic');

CREATE TABLE "MTG_SCHEMA".cards (
	"index" INTEGER,
    id SERIAL PRIMARY KEY,
    artist TEXT,
    asciiName TEXT,
    borderColor "MTG_SCHEMA".em_border,
    colorIdentity TEXT,
    colorIndicator TEXT,
    colors TEXT,
    convertedManaCost REAL,
    duelDeck TEXT,
    edhrecRank numeric,
    faceConvertedManaCost REAL,
    flavorName TEXT,
    flavorText TEXT,
    frameEffect "MTG_SCHEMA".em_frame_effect,
    frameEffects TEXT,
    frameVersion "MTG_SCHEMA".em_frame_version,
    hand TEXT,
    hasFoil BOOLEAN NOT NULL,
    hasNoDeckLimit BOOLEAN NOT NULL,
    hasNonFoil BOOLEAN NOT NULL,
    isAlternative BOOLEAN NOT NULL,
    isArena BOOLEAN NOT NULL,
    isBuyABox BOOLEAN NOT NULL,
    isDateStamped BOOLEAN NOT NULL,
    isFullArt BOOLEAN NOT NULL,
    isMtgo BOOLEAN NOT NULL,
    isOnlineOnly BOOLEAN NOT NULL,
    isOversized BOOLEAN NOT NULL,
    isPaper BOOLEAN NOT NULL, 
    isPromo BOOLEAN NOT NULL, 
    isReprint BOOLEAN NOT NULL, 
    isReserved BOOLEAN NOT NULL, 
    isStarter BOOLEAN NOT NULL, 
    isStorySpotlight BOOLEAN NOT NULL, 
    isTextless BOOLEAN NOT NULL, 
    isTimeshifted BOOLEAN NOT NULL, 
    layout "MTG_SCHEMA".em_layout, 
    leadershipSkills TEXT, 
    life TEXT, 
    loyalty TEXT, 
    manaCost TEXT, 
    mcmId NUMERIC, 
    mcmMetaId NUMERIC, 
    mtgArenaId NUMERIC, 
    mtgoFoilId NUMERIC, 
    mtgoId NUMERIC,
    multiverseId NUMERIC, 
    "name" TEXT, 
    "names" TEXT, 
    number TEXT, 
    originalText TEXT, 
    originalType TEXT, 
    otherFaceIds TEXT, 
    power TEXT, 
    printings TEXT, 
    purchaseUrls TEXT, 
    rarity "MTG_SCHEMA".em_rarity, 
    scryfallId TEXT, 
    scryfallIllustrationId TEXT, 
    scryfallOracleId TEXT, 
    setCode TEXT NOT NULL REFERENCES "MTG_SCHEMA".sets (code) ON DELETE CASCADE, 
    side TEXT, 
    subtypes TEXT, 
    supertypes TEXT, 
    tcgplayerProductId NUMERIC, 
    "text" TEXT, 
    toughness TEXT, 
    "type" TEXT, 
    types TEXT, 
    uuid CHAR(36) UNIQUE NOT NULL, 
    variations TEXT, 
    watermark TEXT);

*****

CREATE TYPE "MTG_SCHEMA".em_border_tokens AS ENUM ('black', 'silver', 'gold');

CREATE TYPE "MTG_SCHEMA".em_layout_tokens AS ENUM ('normal', 'double_faced_token', 'emblem');

CREATE TABLE "MTG_SCHEMA".tokens (
    "index" INTEGER,
    id SERIAL PRIMARY KEY,
    artist TEXT,
    borderColor "MTG_SCHEMA".em_border_tokens,
    colorIdentity TEXT,
    colors TEXT,
    isOnlineOnly BOOLEAN NOT NULL,
    layout "MTG_SCHEMA".em_layout_tokens,
    "name" TEXT,
    "names" TEXT,
    "number" TEXT,
    power TEXT,
    reverseRelated TEXT,
    scryfallId TEXT,
    scryfallIllustrationId TEXT,
    scryfallOracleId TEXT,
    setCode TEXT NOT NULL REFERENCES "MTG_SCHEMA".sets (code) ON DELETE CASCADE,
    side TEXT,
    subtypes TEXT,
    supertypes TEXT,
    "text" TEXT,
    toughness TEXT,
    "type" TEXT,
    types TEXT,
    uuid CHAR(36) NOT NULL,
    watermark TEXT
); 


****

CREATE TYPE "MTG_SCHEMA".em_type AS ENUM ('mtgo', 'mtgoFoil', 'paper', 'paperFoil');

CREATE TABLE "MTG_SCHEMA".prices (
    "index" INTEGER,
    id SERIAL PRIMARY KEY,
    "date" DATE,
    price DECIMAL(8,2),
    "type" "MTG_SCHEMA".em_type,
    uuid CHAR(36) NOT NULL REFERENCES "MTG_SCHEMA".cards(uuid) ON DELETE CASCADE
);



*****

CREATE TABLE "MTG_SCHEMA".rulings (
    "index" INTEGER,
    id SERIAL PRIMARY KEY,
    "date" DATE,
    "text" TEXT,
    uuid CHAR(36) NOT NULL REFERENCES "MTG_SCHEMA".cards(uuid) ON DELETE CASCADE
);


******

CREATE TYPE "MTG_SCHEMA".em_format AS ENUM ('commander', 'duel', 'legacy', 'modern', 'vintage', 'pauper', 'penny', 'historic', 'pioneer', 'brawl', 'future', 'standard', 'oldschool');
    
CREATE TYPE "MTG_SCHEMA".em_status AS ENUM ('Legal', 'Banned', 'Restricted');

CREATE TABLE "MTG_SCHEMA".legalities (
    "index" INTEGER,
    id SERIAL PRIMARY KEY,
    format "MTG_SCHEMA".em_format,
    status "MTG_SCHEMA".em_status,
    uuid CHAR(36) NOT NULL REFERENCES "MTG_SCHEMA".cards(uuid) ON DELETE CASCADE
);

****

CREATE TYPE "MTG_SCHEMA".em_language AS ENUM ('German', 'Spanish', 'French', 'Italian', 'Japanese', 'Portuguese (Brazil)', 'Russian', 'Chinese Simplified', 'Korean', 'Chinese Traditional', 'Sanskrit', 'Hebrew', 'Ancient Greek', 'Latin', 'Arabic', 'English');

CREATE TABLE "MTG_SCHEMA".foreign_data (
    "index" INTEGER,
    id SERIAL PRIMARY KEY,
    flavorText TEXT,
    "language" "MTG_SCHEMA".em_language,
    multiverseId numeric,
    "name" TEXT,
    "text" TEXT,
    "type" TEXT,
    uuid CHAR(36) NOT NULL REFERENCES "MTG_SCHEMA".cards(uuid) ON DELETE CASCADE
);


******

CREATE TYPE "MTG_SCHEMA".em_translations AS ENUM ('Chinese Simplified', 'Chinese Traditional', 'French', 'German', 'Italian', 'Japanese', 'Korean', 'Portuguese (Brazil)', 'Russian', 'Spanish', 'English');

CREATE TABLE "MTG_SCHEMA".set_translations (
    "index" INTEGER,
    id SERIAL PRIMARY KEY,
    "language" "MTG_SCHEMA".em_translations,
    setCode VARCHAR(8) NOT NULL REFERENCES "MTG_SCHEMA".sets(code) ON DELETE CASCADE,
    translation TEXT
);
