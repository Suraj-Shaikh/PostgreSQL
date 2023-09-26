CREATE TABLE maharain.circle_dryspell_25_2019
	AS(
		WITH RECURSIVE dry_spell_cte 
			AS (
				SELECT
					c_district_name, c_tehsil_name, station, latitude, longitude,rain_date, 
					rain_mm,circle_name,station,circle_aws,
					CASE
						WHEN rain_mm < 2.5 THEN 1
						ELSE 0
						END AS is_dry_spell,
					CASE
						WHEN rain_mm < 2.5 THEN 1
						ELSE 0
						END AS current_spell_length,
					ROW_NUMBER() OVER (PARTITION BY circle_aws::varchar ORDER BY rain_date) AS rn
				FROM
					maharain.rainfall_2019
				WHERE  
					rain_date >= '2019-06-01'::date AND rain_date <= '2019-10-31'::date
			 ),
				--recursive CTE named recursive_cte
	recursive_cte 
		AS (
			SELECT
				c_district_name, c_tehsil_name, circle_name, circle_aws,
				latitude, longitude,rain_date, rain_mm,
				is_dry_spell,
				current_spell_length,
				rn
			FROM
				dry_spell_cte
			WHERE
				rn = 1
				UNION ALL
				SELECT
					dsc.c_district_name, dsc.c_tehsil_name,dsc.circle_name,dsc.circle_aws, dsc.latitude, dsc.longitude,dsc.rain_date, 
					dsc.rain_mm,
					CASE
						WHEN dsc.rain_mm < 2.5 THEN 1
						ELSE 0
						END AS is_dry_spell,
					CASE
						WHEN dsc.rain_mm < 2.5 THEN rcte.current_spell_length + 1
						ELSE 0
						END AS current_spell_length,
						dsc.rn
				FROM
					dry_spell_cte dsc
				INNER JOIN recursive_cte rcte ON dsc.circle_aws = rcte.circle_aws AND dsc.rn = rcte.rn + 1
				),
					-- SELECT * FROM recursive_cte
	grouped_data 
		AS (
			SELECT
				c_district_name, c_tehsil_name, circle_name,circle_aws,
				latitude, longitude,
				is_dry_spell,
				MIN(rain_date) AS start_date,
				MAX(rain_date) AS end_date,
				COUNT(*) AS row_count
			FROM 
				(
					SELECT
						c_district_name, c_tehsil_name, circle_name,circle_aws,
						latitude, longitude,
						--  is_dry_spell,
						rain_date,
						CAST
							(is_dry_spell AS integer) AS is_dry_spell, -- Cast to integer
						ROW_NUMBER() OVER (ORDER BY circle_aws, rain_date) -
						ROW_NUMBER() OVER (PARTITION BY circle_aws, is_dry_spell ORDER BY rain_date) AS grp
					FROM
						  recursive_cte
				) temp
					  GROUP BY
						c_district_name, c_tehsil_name, circle_name,circle_aws,
						  latitude, longitude,is_dry_spell, grp
		)

-- 					SELECT * FROM  grouped_data
-- 					ORDER BY circle_aws,start_date
					
		SELECT
			c_district_name, c_tehsil_name, circle_name,circle_aws,
			latitude, longitude, is_dry_spell,
			start_date,
			end_date,
				TO_CHAR(start_date::date, 'DD-MM-YYYY')|| ' to ' ||TO_CHAR(end_date::date, 'DD-MM-YYYY') AS dry_spell_date,
			row_count,
				CASE
					WHEN row_count >= 2 AND row_count <= 6 AND is_dry_spell = 1 THEN 'Very short dry spell(2-6 days)'
					WHEN row_count >= 7 AND row_count <= 13 AND is_dry_spell = 1 THEN 'Short dry spell(7-13 days)'
					WHEN row_count >= 14 AND row_count <= 20 AND is_dry_spell = 1 THEN 'Medium dry spell(14-19 days)'
					WHEN row_count >= 25 AND is_dry_spell = 1 THEN 'Long dry spell(Above - 25 days)'
					ELSE 'rainspell'
				END AS class_name

		FROM
			grouped_data
			ORDER BY
				class_name,
				circle_aws, 
				end_date,
				row_count
	)
					