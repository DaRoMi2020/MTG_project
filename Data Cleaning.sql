--Data Cleaning

/*The rows for The Planeswalker 'The Wanderder' have a NULL value in their subtype attribute,
unlike all other Planeswalker cards. Rather than write a script in a function to handle the null it simpler to
replace .*/

BEGIN;
	SAVEPOINT planeswalkerfix_1;
	UPDATE cards SET subtypes = 'The Wanderer' WHERE "name" ILIKE 'The Wanderer';
COMMIT;

