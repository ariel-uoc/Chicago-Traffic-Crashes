USE traffic_crash; 

-- -----------------------------------------------------
-- Crash Table Queries 
-- -----------------------------------------------------

# Create view to visualize cause and crash count 
DROP VIEW If EXISTS cause_count; 
CREATE VIEW cause_count AS
    SELECT 
		pc.prim_contributory_id,
        pc.prim_contributory_cause,
        COUNT(c.prim_contributory_id) AS count
    FROM
        crash c
            INNER JOIN
        PRIM_CONTRIBUTORY pc ON c.prim_contributory_id = pc.prim_contributory_id
    GROUP BY c.prim_contributory_id
    ORDER BY count DESC; 
# Aside from cases when the primary cause cannot be determined, man-made errors are the main causes of crashes.

# WEATHER-RELATED QUERIES
# Query weather condition and the number of traffic crashes 
SELECT 
    weather_condition, 
    COUNT(*)
FROM
    crash
GROUP BY weather_condition
ORDER BY COUNT(*) DESC; 
# Most crashes happen under clear weather, so weather can't be the blame in most cases. 

# Query weather and crash count from crashes whose primary contributor is weather 
SELECT 
    c.weather_condition, 
    COUNT(*) AS crashCount
FROM
    cause_count cc
        INNER JOIN
    crash c ON cc.prim_contributory_id = c.prim_contributory_id
WHERE
    cc.prim_contributory_cause = 'WEATHER'
GROUP BY weather_condition
ORDER BY crashCount DESC; 
# Shows that when weather is the primary contributor, snow and rain lead to most accidents.

# Query the road surface condition and crash count when the primary contributor is weather
SELECT 
	c.roadway_surface_cond, 
    count(*) 
FROM
    cause_count cc
        INNER JOIN
    crash c ON cc.prim_contributory_id = c.prim_contributory_id
WHERE
    cc.prim_contributory_cause = 'WEATHER'
GROUP BY c.roadway_surface_cond
ORDER BY count(*) DESC; 
# Suggests that road surface with snow and rain has positive correlation with traffic crash when the primary contributor is weather.

# Query the lighting condition and crash count when the primary contributor is weather 
SELECT 
    c.lighting_condition, 
    COUNT(*) as crash_count
FROM
    cause_count cc
        INNER JOIN
    crash c ON cc.prim_contributory_id = c.prim_contributory_id
WHERE
    cc.prim_contributory_cause = 'WEATHER'
GROUP BY c.lighting_condition
ORDER BY crash_count DESC; 
# Shows no correlation between lighting condition and crash. Most crashes happen in daylight. 

# Query damage and crash count 
SELECT 
    damage, COUNT(*)
FROM
    crash
GROUP BY damage; 
# Most crashes result in damage exceeding $1,500. 

# Query the street and the number of crashes that took place 
SELECT 
	street_name, 
    count(*) 
FROM
    crash
GROUP BY street_name
ORDER BY count(*) DESC; 
# Top 3 streets with the most accidents ocurring are Western Ave, Pulaski Road and Cicero Ave. 

# TIMING-RELATED QUERIES
# Query the hour of the day and the number of crashes that took place 
SELECT 
	crash_hour, 
    count(*) 
FROM
    crash
GROUP BY crash_hour
ORDER BY count(*) DESC; 
# Most accidents take place in the afternoon peak hours (3-5pm). 

# Query the day of week and the number of crashes that took place 
SELECT 
	crash_day_of_week, 
    count(*) 
FROM
    crash
GROUP BY crash_day_of_week
ORDER BY count(*) DESC; 
# Most accidents take place on the weekend. 

# Query the month and the number of crashes that took place 
SELECT 
	crash_month, 
    count(*) 
FROM
    crash
GROUP BY crash_month
ORDER BY count(*) DESC; 
# Most accidents happen in the summer months. But a significant number also happen in the spring and winter. 
# (Note : our data only covers up to end of October.) 

# Query the condition of traffic control devices and the number of crashes
SELECT 
	traffic_control_device,
    count(*) AS crashCount
FROM
    crash
GROUP BY traffic_control_device
ORDER BY crashCount DESC;
# Most crashes occur where there are no control devices. 

-- -----------------------------------------------------
-- Vehicle Table Queries 
-- -----------------------------------------------------
SELECT * FROM traffic_crash.vehicle;

# Query the vehicle make and the number of vehicles
SELECT 
    MAKE, 
    COUNT(*) AS number
FROM
    vehicle
GROUP BY MAKE
ORDER BY number DESC;
# Result: top5 makes(>10000): CHEVROLET,TOYOTA,FORD,NISSAN,HONDA

# Query vehicle defect and numbers 
SELECT 
    VEHICLE_DEFECT, 
    COUNT(*) AS number
FROM
    vehicle
GROUP BY VEHICLE_DEFECT
ORDER BY number DESC;
# Most vehicles have no defect. The most common known defect is brake issues. 

#  Table that queries vehicle defect and crash count from crashes whose primary contributor is vehicle condition
SELECT 
    v.vehicle_defect, 
    COUNT(*) AS crashCount
FROM
    vehicle v
        INNER JOIN
    crash c ON v.RD_NO = c.RD_NO
        INNER JOIN
    cause_count cc ON cc.prim_contributory_id = c.prim_contributory_id
WHERE
    cc.prim_contributory_cause = 'EQUIPMENT - VEHICLE CONDITION'
GROUP BY vehicle_defect
ORDER BY crashCount DESC; 
# Even when the primary contributor is vehicle condition, most vehicles have no or unknown defect. Brake issues is the most common type of known vehicle defect. 

# Query the use and the number of vehicle involved in crashes 
SELECT 
    VEHICLE_USE, 
    COUNT(*) AS number
FROM
    vehicle
GROUP BY VEHICLE_USE
ORDER BY number DESC;
# Most vehicle involved in crashes are for personal use. 

-- -----------------------------------------------------
-- People Table Queries 
-- -----------------------------------------------------

# Query the demographics of drivers involved in fatal accidents
SELECT 
    RD_NO,
    STATE,
    SEX,
    AGE
FROM
    people p
WHERE
    PERSON_TYPE = 'DRIVER'
        AND INJURY_CLASSIFICATION = 'FATAL'
        AND RD_NO IS NOT NULL;
# Interesting finding: all drivers are IL licensed and most are male.

# Query to count crashes based on crash_hour when injury is sustained 
SELECT 
    CRASH_HOUR, 
    COUNT(*) AS people_count
FROM
    people p
        LEFT JOIN
    crash c ON p.RD_NO = c.RD_NO
WHERE
    PERSON_TYPE = 'DRIVER'
        AND INJURY_CLASSIFICATION IN ('FATAL' , 'INCAPACITATING INJURY',
        'REPORTED, NOT EVIDENT',
        'NONINCAPACITATING INJURY')
GROUP BY CRASH_HOUR
ORDER BY people_count DESC;
# Most accidents from which injury is sustained take place in the afternoon.

# Query driver's sex and number of drivers involved in accidents 
SELECT 
    sex, 
    COUNT(*)
FROM
    people
WHERE
    PERSON_TYPE = 'DRIVER'
GROUP BY sex
ORDER BY COUNT(*) DESC;

# Query the age of drivers and the number of drivers involved in crashes 
SELECT 
    age, 
    COUNT(*)
FROM
    people
WHERE
    PERSON_TYPE = 'DRIVER'
GROUP BY age
ORDER BY COUNT(*) DESC;
# Aside from cases when driver's age is unknown, drivers involved between the ages of 24 and 28 are most 

# Query sex of drivers and the number of accidents caused by manmade errors 
SELECT 
	p.SEX,
	COUNT(c.RD_NO) AS manmade_crash_count
FROM
	cause_count cc
		INNER JOIN
	crash c ON cc.prim_contributory_id = c.prim_contributory_id
		INNER JOIN 
	people p ON c.RD_NO = p.RD_NO 
WHERE
	prim_contributory_cause IN ('FAILING TO YIELD RIGHT-OF-WAY', 
		'FOLLOWING TOO CLOSELY',
		'IMPROPER OVERTAKING/PASSING',
		'FAILING TO REDUCE SPEED TO AVOID CRASH',
		'IMPROPER BACKING',
		'IMPROPER LANE USAGE',
		'IMPROPER TURNING/NO SIGNAL',
		'DRIVING SKILLS/KNOWLEDGE/EXPERIENCE',
		'DISREGARDING TRAFFIC SIGNALS',
		'OPERATING VEHICLE IN ERRATIC, RECKLESS, CARELESS, NEGLIGENT OR AGGRESSIVE MANNER',
		'DISREGARDING STOP SIGN',
		'UNDER THE INFLUENCE OF ALCOHOL/DRUGS (USE WHEN ARREST IS EFFECTED)',
		'DRIVING ON WRONG SIDE/WRONG WAY',
		'EXCEEDING SAFE SPEED FOR CONDITIONS',
		'EXCEEDING AUTHORIZED SPEED LIMIT',
		'DISREGARDING OTHER TRAFFIC SIGNS',
		'DISREGARDING ROAD MARKINGS',
		'CELL PHONE USE OTHER THAN TEXTING',
		'HAD BEEN DRINKING (USE WHEN ARREST IS NOT MADE)',
		'DISTRACTION - OTHER ELECTRONIC DEVICE (NAVIGATION DEVICE, DVD PLAYER, ETC.)',
		'TEXTING',
		'DISREGARDING YIELD SIGN')
	AND person_type = "DRIVER"
GROUP BY p.SEX
ORDER BY manmade_crash_count DESC
LIMIT 2;  
# There are more male drivers involved in accidents than female drivers. 

# Query driver's license state, vehicle's license plate state and number of vehicles involved in crash when the driver is from out-of-state
SELECT 
	p.drivers_license_state,
    v.LIC_PLATE_STATE,
    count(*)
FROM
	people p
    RIGHT JOIN
    vehicle v on p.RD_NO = v.RD_NO
WHERE 
	p.drivers_license_state != 'IL' 
GROUP BY p.drivers_license_state,
			v.LIC_PLATE_STATE
ORDER BY count(*) DESC;
# Drivers from Indiana and Wisconsin are the common out-of-state drivers involved in road accidents in Chicago.

