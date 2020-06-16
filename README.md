# MTG_project

Author

Dan Milman

Magic the Gathering Project

The purpose of this project is to create a function, utilizing user entered parameters, that will generate a random Magic The Gathering deck in a .txt file output. The data is sourced from https://mtgjson.com/ which describes itself as "open-source project that catalogs all Magic: The Gathering cards in a portable format." For now the entire function is written in PostgreSQL 12 with no UI planned. This is a practice project for my own educational purposes with no commercial intent. Comments and messages are much appreciated.

Current state of the Project

At the moment I am working to write simple user defined functions that return a query for each type of card that will combine into a deck. For example, different there will be seperate functions for enchantments, creatures, instants, etc. These functions take user entered parameters from a master function that then calls them and does a union join to complete the query. 