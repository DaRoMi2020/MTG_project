--Data Cleaning

/*Before cleaning The Planeswalker 'The Wanderder' had a NULL value in their subtype value
unlike all other Planeswalker cards. Rather than write a script to deal with this it was 
easier to fix as long as I followed the data rules.*/

BEGIN;
	SAVEPOINT planeswalkerfix_1;
	UPDATE cards SET subtypes = 'The Wanderer' WHERE "name" ILIKE 'The Wanderer';
COMMIT;

