CREATE OR ALTER VIEW gold.master_table AS
SELECT
	cp.[date] AS [date],
	cp.copper_price AS copper_price,
	b.brent AS brent_price,
	cc.net_position AS net_position,
	dxy.dxy AS dxy,
	sc.shanghai_close AS shanghai_close
FROM silver.copper_price cp
INNER JOIN silver.brent b
ON cp.[date] = b.[date]
INNER JOIN silver.cot_copper cc
ON cp.[date] = cc.[date]
INNER JOIN silver.dxy dxy
ON cp.[date] = dxy.[date]
INNER JOIN silver.shanghai_composite sc
ON cp.[date] = sc.[date]

