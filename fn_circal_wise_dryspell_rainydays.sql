CREATE OR REPLACE FUNCTION maharain.fn_circle_dryspell_rainydays(start_year INT, end_year INT)
RETURNS VOID AS $$
DECLARE 
  loop_year INT;
BEGIN
  FOR loop_year IN start_year..end_year LOOP
    -- Create a permanent result table for the current year's results
    EXECUTE format('CREATE TABLE IF NOT EXISTS maharain.result_%1$s (
        circle_aws TEXT,
        latitude NUMERIC,
        longitude NUMERIC,
        dryspell_%1$s INT,
        raindays_%1$s INT
      )', loop_year);

    EXECUTE format(
      'INSERT INTO maharain.result_%1$s (circle_aws, latitude, longitude, dryspell_%1$s, raindays_%1$s)
      SELECT 
        DISTINCT rc.circle_aws, 
        rc.latitude, 
        rc.longitude,
        ds.dryspell_%1$s,
        rs.raindays_%1$s
      FROM 
        maharain.circle_dryspell_25_%1$s rc
      LEFT JOIN 
        (SELECT 
          circle_aws, 
          latitude, 
          longitude, 
          COUNT(row_count) AS dryspell_%1$s
        FROM 
          maharain.circle_dryspell_25_%1$s
        WHERE 
          class_name IN (''Long dry spell(Above - 25 days'',''Medium dry spell(14-19 days)'')
        GROUP BY circle_aws, latitude, longitude
        ORDER BY circle_aws) AS ds
        ON rc.circle_aws = ds.circle_aws
      LEFT JOIN 
        (SELECT 
          circle_aws, 
          latitude, 
          longitude, 
          COUNT(row_count) AS raindays_%1$s
        FROM 
          maharain.circle_dryspell_25_%1$s
        WHERE 
          class_name IN (''rainspell'')
        GROUP BY circle_aws, latitude, longitude
        ORDER BY circle_aws) AS rs
        ON rc.circle_aws = rs.circle_aws
        ORDER BY rc.circle_aws
    ', loop_year);

    -- Print the data for the current year's results
    RAISE NOTICE 'Results for Year %', loop_year;
    EXECUTE format('SELECT * FROM maharain.result_%1$s', loop_year);
  END LOOP;
END;
$$ LANGUAGE plpgsql;
