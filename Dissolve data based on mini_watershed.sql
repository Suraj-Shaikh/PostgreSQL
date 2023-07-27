SELECT id, geom, stncode, dvncode, dtncode, thncode, vincode, crncode, stname, dvname, dtname, thname, crname, vlname, selected, is_pocra, mini_water, dtmname, thmname, vilmname, gpnname, subdname, ph_i_updat, gpncode
	FROM admin_data.mh_villages;
	
SELECT  dtncode, dtname, thncode, thname, mini_water, ST_Union(geom) as geom 
FROM admin_data.mh_villages
WHERE dtncode = '517'
GROUP BY dtncode, dtname, thncode, thname, mini_water;

SELECT 
	dtname, 
	thname, 
	mini_water, 
	ST_Union(geom) as geom 
FROM admin_data.mh_villages 
WHERE 
	dtncode='500'
GROUP BY 
		dtname, 
		thname, 
		mini_water;