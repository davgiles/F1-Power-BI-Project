-- Select db
USE f1;

---------------------------------
-- Build drivers table
CREATE TABLE
    drivers (
        driver_id INT PRIMARY KEY,
        driver_ref VARCHAR(50),
        number INT,
        code VARCHAR(3),
        forename VARCHAR(50),
        surname VARCHAR(50),
        dob DATE,
        nationality VARCHAR(50)
    );

BULK INSERT drivers
FROM
    'C:\repos\f1\drivers.csv'
WITH
    (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    );

-- Build driver_standings table
CREATE TABLE
    driver_standings (
        driver_standings_id INT PRIMARY KEY,
        race_id INT,
        driver_id INT,
        points DECIMAL(10, 2),
        position INT,
        position_text VARCHAR(10),
        wins INT,
        FOREIGN KEY (race_id) REFERENCES races (race_id),
        FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
    );

BULK INSERT driver_standings
FROM
    'C:\repos\f1\driver_standings.csv'
WITH
    (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    );

-- Build results table
CREATE TABLE
    results (
        result_id INT PRIMARY KEY,
        race_id INT,
        driver_id INT,
        constructor_id INT,
        grid INT,
        position INT,
        position_text VARCHAR(10),
        position_order INT,
        points DECIMAL(10, 2),
        laps INT,
        time VARCHAR(50),
        milliseconds INT,
        fastestLap INT,
        rank INT,
        fastest_lap_time VARCHAR(10),
        fastest_lap_speed DECIMAL(10, 3),
        FOREIGN KEY (race_id) REFERENCES races (race_id),
        FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
    );

BULK INSERT results
FROM
    'C:\repos\f1\results.csv'
WITH
    (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    );

-- Build lap_times table
CREATE TABLE
    lap_times (
        race_id INT,
        driver_id INT,
        lap INT,
        position INT,
        time VARCHAR(10),
        milliseconds INT,
        PRIMARY KEY (race_id, driver_id, lap),
        FOREIGN KEY (race_id) REFERENCES races (race_id),
        FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
    );

BULK INSERT lap_times
FROM
    'C:\repos\f1\lap_times.csv'
WITH
    (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    );

-- Build races table
CREATE TABLE
    races (
        race_id INT PRIMARY KEY,
        year INT,
        round INT,
        circuit_id INT,
        name VARCHAR(100),
        date DATE,
        time TIME
    );

BULK INSERT races
FROM
    'C:\repos\f1\races.csv'
WITH
    (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    );

-- Build constructors table
CREATE TABLE
    constructors (
        constructor_id INT PRIMARY KEY,
        constructor_ref VARCHAR(50),
        name VARCHAR(50),
        nationality VARCHAR(50),
        url VARCHAR(100)
    );

BULK INSERT races
FROM
    'C:\repos\f1\constructors.csv'
WITH
    (
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 2
    );

---------------------------------
-- Data Overview
SELECT
    *
FROM
    constructors;

SELECT
    *
FROM
    drivers;

SELECT
    *
FROM
    driver_standings;

SELECT
    *
FROM
    results;

SELECT
    *
FROM
    lap_times;

SELECT
    *
FROM
    races
ORDER BY
    year DESC;

SELECT
    *
FROM
    circuits;

---------------------------------
-- Data Manipulation
-- Add fullname column to drivers table that combines forename and surname
ALTER TABLE drivers ADD fullname AS CONCAT (forename, ' ', surname);

---------------------------------
-- Data Analysis Questions:
-- 1. Who has the most total points for each year?
-- 2. Who has the most podium finishes for each year?
-- 3. What are the average fastest lap times and speeds per Grand Prix for each year?
-- 4. Who has the best average point differential for each year?
---------------------------------
-- Query driver stats per Grand Prix
SELECT
    c.name AS constructor,
    d.fullname AS driver_name,
    CASE
        WHEN MONTH (r.DATE) > MONTH (d.dob)
        OR (
            MONTH (r.DATE) = MONTH (d.dob)
            AND DAY (r.DATE) >= DAY (d.dob)
        ) THEN DATEDIFF (YEAR, d.dob, r.DATE)
        ELSE DATEDIFF (YEAR, d.dob, r.DATE) - 1
    END AS driver_age,
    r.name AS grand_prix,
    CONCAT (ci.location, ', ', ci.country) AS location,
    YEAR (r.DATE) AS year,
    re.grid AS start_position,
    re.position_order AS end_position,
    re.points,
    CASE
        WHEN re.position IN (1, 2, 3) THEN 1
        ELSE 0
    END AS pod_finish,
    re.fastest_lap,
    re.rank AS fastest_lap_rank,
    re.fastest_lap_time,
    re.fastest_lap_speed
FROM
    results re
    JOIN constructors c ON re.constructor_id = c.constructor_id
    JOIN drivers d ON re.driver_id = d.driver_id
    JOIN races r ON re.race_id = r.race_id
    JOIN circuits ci ON r.circuit_id = ci.circuit_id
GROUP BY
    c.name,
    d.fullname,
    CASE
        WHEN MONTH (r.DATE) > MONTH (d.dob)
        OR (
            MONTH (r.DATE) = MONTH (d.dob)
            AND DAY (r.DATE) >= DAY (d.dob)
        ) THEN DATEDIFF (YEAR, d.dob, r.DATE)
        ELSE DATEDIFF (YEAR, d.dob, r.DATE) - 1
    END,
    r.name,
    CONCAT (ci.location, ', ', ci.country),
    YEAR (r.DATE),
    re.grid,
    re.position_order,
    re.points,
    CASE
        WHEN re.position IN (1, 2, 3) THEN 1
        ELSE 0
    END,
    re.fastest_lap,
    re.rank,
    re.fastest_lap_time,
    re.fastest_lap_speed
ORDER BY
    YEAR (r.DATE) DESC;