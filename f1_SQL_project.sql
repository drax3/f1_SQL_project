-- driver - qualifying - constructor - venues 

-- driver

-- most championship winner
SELECT 
	number,
    code,
    forename,
    count(*) AS driver_championships
FROM (
	SELECT *
	FROM driver_championship_standings
	GROUP BY year
) AS champions
GROUP BY forename
ORDER BY driver_championships DESC;

-- most race wins in career 
SELECT  
	d.forename, 
    count(*) AS wins
FROM results r
JOIN drivers d
	USING(driverId)
WHERE r.position = 1
GROUP BY r.driverId
ORDER BY wins DESC;


-- most race wins in a season top 15
-- improvement 1. add constructors name
SELECT 
	rs.year,
    r.driverId, 
    r.constructorId,
    r.number,
    d.driverRef,
    d.forename, 
    count(*) AS wins
FROM results r
JOIN races rs
	USING(raceId)
JOIN drivers d
	USING(driverId)
WHERE position = 1
GROUP BY d.driverId, rs.year
ORDER BY wins DESC
LIMIT 15;

-- most wins of non champion driver
SELECT 
    r.constructorId,
    r.number,
    d.driverRef,
    d.forename, 
    count(*) AS wins
FROM results r
JOIN races rs
	USING(raceId)
JOIN drivers d
	USING(driverId)
WHERE position = 1
AND d.forename NOT IN (SELECT forename FROM champion_names)
GROUP BY d.forename
ORDER BY wins DESC
LIMIT 10;

-- most career points
SELECT 
	number, 
    code, 
	forename, 
    sum(points) AS career_points
FROM driver_championship_standings
GROUP BY forename
HAVING career_points <> 0
ORDER BY career_points DESC;

-- drivers without career points
-- add no of races they participated
SELECT
	number, 
    code, 
	forename, 
    sum(points) AS career_points
FROM driver_championship_standings
GROUP BY forename
HAVING career_points = 0
ORDER BY career_points DESC;

-- drivers with most out of points finish

-- drivers without points
SELECT *
FROM drivers 
WHERE forename NOT IN (
SELECT forename 
FROM (
SELECT number, code, forename, sum(points) as career_points
FROM driver_championship_standings
GROUP BY forename
HAVING career_points <> 0
ORDER BY career_points DESC
) careen_points_table
);

-- most race participatioin
SELECT  
	-- r.driverId,
    d.forename,
    d.surname,
    count(*) AS races
FROM results r
JOIN drivers d
	USING(driverId)
-- where r.grid <> 0
GROUP BY driverId
ORDER BY races DESC;

-- pole and win in the same race
SELECT
	d.forename,
    d.surname,
    count(*) start_win 
FROM results rslt
JOIN drivers d
	USING(driverId)
WHERE rslt.grid = 1 AND rslt.position = 1
GROUP BY rslt.driverId
ORDER BY start_win DESC
LIMIT 10;

-- not finished due to particular reasons
SELECT 
	d.forename,
    d.surname,
    rslt.driverId, 
    rslt.statusId,
    s.status,
    count(*) AS not_count
FROM results rslt
JOIN drivers d
	USING(driverId)
JOIN status s
	USING(statusId)
WHERE rslt.statusId IN (139, 100,72,60,20)
GROUP BY rslt.driverId, rslt.statusId
ORDER BY s.status, not_count DESC;


-- qualifying ------------------------------------------------------------------------------------
-- most pole sitter
SELECT
	d.forename,
    d.surname,
    count(*) starts 
FROM results rslt 
JOIN drivers d
	USING(driverId)
WHERE grid = 1
GROUP BY rslt.driverId
ORDER BY starts DESC
LIMIT 10;

-- pole sitter in a season
SELECT 
	rs.year,
	d.forename,
    d.surname,
    count(*) starts 
FROM results rslt 
JOIN drivers d
	USING(driverId)
JOIN races rs
	USING(raceId)
WHERE grid = 1
GROUP BY rslt.driverId, rs.year
ORDER BY starts DESC
LIMIT 10;

-- most top 3 apperance in qualifying
SELECT
	d.forename,
    d.surname,
    count(*) AS count
FROM qualifying q
JOIN drivers d
	USING(driverId)
WHERE position IN (1,2,3)
GROUP BY driverId
ORDER BY count DESC
LIMIT 10;


-- venue -------------------------------------------------------
-- most wins at venue 
SELECT 
	rslt.driverId,
    d.forename,
    d.surname,
    rs.circuitId,
    rs.name,
    count(*) AS count
FROM results rslt
JOIN races rs
	USING(raceId)
JOIN drivers d
	USING(driverId)
WHERE rslt.position = 1
GROUP BY rslt.driverId, rs.circuitId
HAVING count >= 5
ORDER BY count DESC; 

-- most races hosted by a venue
SELECT 
	name, 
    count(*) AS races 
FROM races
GROUP BY circuitId
HAVING races >= 50
ORDER BY races DESC;

-- constructor --------------------------------------------------

-- constructor with most chapmioships
SELECT 
	name, 
	count(*) AS const_champ
FROM
(SELECT * 
FROM final_constructor_standings
GROUP BY year
) AS const_win
GROUP BY name
ORDER BY const_champ DESC;

-- most wins of constructor in a year
SELECT * 
FROM constructor_wins
GROUP BY year
ORDER BY wins DESC;


--  constuctor with most career wins
SELECT 
	name, 
    constructorId, 
    sum(wins) AS total_wins
FROM constructor_wins
GROUP BY constructorId
ORDER BY total_wins DESC
LIMIT 10;

-- constructor with most points in a season
SELECT * 
FROM final_constructor_standings 
GROUP BY year
ORDER BY points DESC;

-- maximum points scored by each constructore
SELECT * 
FROM 
(
SELECT * 
FROM final_constructor_standings 
GROUP BY year 
ORDER BY name, points DESC
) AS tab
GROUP BY name 
ORDER BY points DESC;

-- constructor won without most wins in a season
SELECT * FROM final_constructor_standings TAB1
JOIN (SELECT * FROM constructor_wins GROUP BY year) AS tab
	USING(YEAR)
GROUP BY year
HAVING TAB1.constructorId <> tab.constructorId;


-- constructor with most career points
SELECT name, sum(points) AS total_points
FROM final_constructor_standings
GROUP BY constructorId
ORDER BY total_points DESC
LIMIT 10;


-- when champion driver does not belong to champion constructor
SELECT *
FROM
(SELECT * FROM driver_championship_standings GROUP BY year) AS dri
JOIN 
(SELECT * FROM final_constructor_standings GROUP BY year) AS const
	USING(year)
WHERE dri.constructorId <> const.constructorId;


-- ---------------------------------------------------------------------------------
-- this part contains additional helpful views and queries for the main queries
-- ----------------------------------------------------------------------------------

-- all champion names
create or replace view champion_names as
select distinct forename
from driver_championship_standings
group by year;


-- all race winner names
create or replace view race_winner_names as
select 
	distinct forename
from results r
join drivers d
	using(driverId)
where position = 1
order by forename;

-- final race points in every season
select * from driver_championship_standings ;
CREATE OR REPLACE VIEW driver_championship_standings AS 
select 
	rs.year,
    d.number, 
    d.code, 
    d.forename,
    SUM(rlt.points) as points,
    rlt.constructorId
from results rlt
join drivers d
	using(driverId)
join races rs
	using(raceId)
-- where rs.year = 2021
group by driverId, rs.year
order by rs.year desc, points desc;


-- constructor points after every 
select * from final_constructor_standings;
create or replace view final_constructor_standings as
select 
	rs.year, 
    c.name,
    cr.constructorId, 
    sum(points) as points
from constructor_results cr
join races rs
	using(raceId)
join constructors c
	USING(constructorId)
group by cr.constructorId, rs.year
order by rs.year desc, points desc;

-- constructor wins
select * from constructor_wins ;
create or replace view constructor_wins as
select 
	rs.year,
    c.name,
    rslt.constructorId,
    count(*) as wins
from results rslt 
join races rs
	using(raceId)
join constructors c
	using(constructorId)
where rslt.position = 1
group by rs.year, rslt.constructorId
order by rs.year desc, wins desc;


-- last round of every race
select raceId, year, max(round ) as last_round
from races
group by year 
order by year;

