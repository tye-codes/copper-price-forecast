/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'silver' Tables
===============================================================================
*/

IF OBJECT_ID ('silver.brent', 'U') IS NOT NULL
	DROP TABLE silver.brent;
GO

CREATE TABLE silver.brent (
	date	DATE,
	brent	FLOAT
);
GO

IF OBJECT_ID('silver.copper_price', 'U') IS NOT NULL
	DROP TABLE silver.copper_price;
GO

CREATE TABLE silver.copper_price(
	date			DATE,
	copper_price	FLOAT
);
GO

IF OBJECT_ID('silver.dxy', 'U') IS NOT NULL
	DROP TABLE silver.dxy
GO

CREATE TABLE silver.dxy(
	date	DATE,
	dxy	FLOAT
);
GO

IF OBJECT_ID('silver.shanghai_composite', 'U') IS NOT NULL
	DROP TABLE silver.shanghai_composite;
GO

CREATE TABLE silver.shanghai_composite(
	date			DATE,
	shanghai_close	FLOAT
);
GO

IF OBJECT_ID('silver.cot_copper', 'U') IS NOT NULL
	DROP TABLE silver.cot_copper;
GO

CREATE TABLE silver.cot_copper(
	date			DATE,
	net_position	FLOAT
);