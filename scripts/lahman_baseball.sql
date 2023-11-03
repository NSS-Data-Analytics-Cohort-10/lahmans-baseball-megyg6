-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.

-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

--Initial way to solve for answer (was not too familiar with data/ had not read documentation):
SELECT DISTINCT(DATE_PART('year',span_first)) AS game_years
FROM homegames
ORDER BY game_years DESC;

--Second way to solve for answer(the simplest and fastest):
SELECT DISTINCT(yearid)
FROM teams

--ANSWER: 1871-2016


-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
--The following helped to orient myslef with the tables I was pulling from:
--SELECT *
-- FROM people;
-- -- SELECT*
-- -- FROM appearances;
-- SELECT *
-- FROM teams
--------------------------
--Initial thought processes:
SELECT	p.playerid
		,p.namefirst||' '||p.namelast AS name
		,p.height AS height_inches
		,t.teamid
		,a.g_all AS games_played
		,t.name AS team_name
FROM people as p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams AS t
ON  a.teamid=t.teamid
ORDER BY height ASC
LIMIT 1;
--Second thought process(minimizes run time by adding subquery):
SELECT p.playerid
	,p.namefirst||' '||p.namelast AS player_name
	,p.height AS height_inches
	,a.g_all AS games_played
	,t.name  AS team_name
	,a.yearid AS year_played
FROM people AS p
JOIN appearances AS a
USING (playerid)
JOIN teams as t
USING (teamid)
WHERE height IN
		(SELECT MIN(height)
		FROM people)
LIMIT 1;
--ANSWER:// name: Eddie Gaedel// height: 43in// team: St. Louis Browns// played 1 game in 1971
	
-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
--The following helped to orient myslef with the tables I was pulling from
-- SELECT *
-- FROM people
-- SELECT *
-- FROM salaries
---------------------------------

SELECT p.namefirst||' '||p.namelast AS player_name
		,SUM(sal.salary) AS total_salary
--summed the salary columns, because there are players that played for multiple years
FROM people AS p
JOIN salaries as sal 
USING (playerid)
WHERE playerid IN
			(SELECT DISTINCT (playerid)
			 FROM schools
			 JOIN collegeplaying
			 USING (schoolid)
			 WHERE schoolname LIKE '%Vander%')
--the subquery should filter for players in that played in Vanderbilt Uni.
GROUP BY p.namefirst
		,p.namelast
ORDER BY total_salary DESC;
--order by total salary desc to find highest salary from a Vandi player in the mlb

--ANSWER: 15 players made it to the major leagues. David Price had the highest aggregated salary at 81851296, and Scotti Madison the lowest at 135000


-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
-- SELECT *
-- FROM fielding
   
SELECT
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
	WHEN pos IN ('P','C') THEN 'Battery'
	END AS position 
--case statement to put poa(position) into three categories, aliased as position
	,SUM(po) AS total_putouts
-- SUM all po(putouts) due to group by position, these will be added up by category of position
FROM fielding
WHERE yearid=2016
--filters to only look at year 2016
GROUP BY position
--roll up by position
ORDER BY total_putouts DESC;
--group by statement to in a way seperate and group each category

--ANSWER: Infield: 58934// Battery:	41424//  Outfield: 29560

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--AVG STRIKEOUTS PER GAME BY DECADE:
SELECT CONCAT(LEFT(yearid ::varchar,3),'0') AS decade
		,ROUND(SUM(so::numeric)/SUM(g::numeric/2),2) AS avg_strike_out_per_game
--cast yearid to varchar type(character data varying), start from the left and keep only 1st 3 characters, add 0 at the end to get decade, alias as decade,
--cast strikeouts and games to numeric to allow decimal values, sum both ho and g, due to group by they will be summed by decade
--divide g by 2, they are being counted twice in table
FROM teams								 
WHERE yearid >= 1920
--years from 1920 to present
GROUP BY decade
--'roll up' by decade 
ORDER BY decade;
--order asc 

--AVG HOMERUN PER GAME BY DECADE:
SELECT CONCAT(LEFT(yearid ::varchar,3),'0') AS decade
		,ROUND(SUM(hra::numeric)/SUM(g::numeric/2),2) AS avg_home_run_per_game
FROM teams								 
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

--ANSWER: There is a positive trend when focusing on strike outs, and a constant low trend of homeruns


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

-- SELECT *
-- FROM people
-- SELECT * 
-- FROM batting 


SELECT	p.namefirst||' '||p.namelast AS name
		,sb AS stolen_bases
		,sb+cs AS total_steal_attempts
		,ROUND(sb::numeric/(sb::numeric+cs::numeric)*100,2) AS pct_success
--due to math across rows and not column added sb and cs, aliased as total steal attempts 
--cast sb (stolen bases) and cs (caught stealing) to numeric to allow decimal values and devided sb(stolen bases) by sb+cs (attempted steals) 
FROM batting AS b
JOIN people AS p
USING (playerid)
WHERE yearid=2016
	AND (sb+cs)>=20	
--filtering for year: 2016 and where attempted steals was more than 20
GROUP BY b.cs, b.sb,p.namefirst,p.namelast, p.namegiven
ORDER BY pct_success DESC;

--ANSWER: Chris	Owings/ Christopher Scott	21 out of 23, percent succes 91.30%
	
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

--MAX WINS BY YEAR FOR TEAMS THAT DIDN'T WIN WORLD SERIES:
SELECT yearid
		,MAX(w) AS maxwins_series_losers	
--since grouped by year, max(w) shows the maximum wins by a team that did not win world series
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND wswin='N'
--filter for years 1970-2016 and where team did not win world series
GROUP BY yearid
ORDER BY maxwins_series_losers DESC;
--ANSWER 7A: Maximum number of wins by a series loser happened in 2001 with 116

--MIN WINS BY YEAR FOR TEAM THAT WON WORLD SERIES:
SELECT yearid
		,MIN(w) AS minwins_series_winners
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND wswin='Y'
GROUP BY yearid
ORDER BY minwins_series_winners;
--ANSWER 7B: Minimum number of winns by series winners happened in 1981 with 63. The reson below: 
--The 1981 Baseball Strike caused a strike-shortened season. Teams played between 102 to 110 games, since games were canceled from June 12th to August 10th and not made up to even out the schedule.



WITH series_losers AS (SELECT yearid
					   , MAX(w) AS maxwins_series_losers
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='N'
					   			AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC),
  
series_winners AS (SELECT yearid
				   , MIN(w) AS minwins_series_winners
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='Y'
				   				AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC)				
SELECT 
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers < sw.minwins_series_winners THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,1) AS percent_of_greater_wins_by_series_winners
-- 	,ROUND(SUM(CASE WHEN sl.maxwins_series_losers > sw.minwins_series_winners THEN 1.00 ELSE 0 END)/COUNT(sl.maxwins_series_losers)*100,1) AS percent_of_greater_wins_by_series_losers
-- 	,ROUND(SUM(CASE WHEN sl.maxwins_series_losers = sw.minwins_series_winners THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,1) AS percent_of_same_numeber_of_wins
FROM series_losers as sl
JOIN series_winners as sw
USING (yearid)
--ANSWER 7C: The case that a team with the most wins also won the world series happened 22.22 percent of the time

--25.5 is what Amanda hinted, where did, I go wrong?

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
-- SELECT *
-- FROM homegames
--HIGHEST AVG ATTENDANCE PER GAME IN 2016:
SELECT p.park_name AS park
		,t.name AS team	
		,ROUND(SUM(h.attendance::numeric)/SUM(h.games::numeric),0) AS avg_attendance
FROM homegames AS h
JOIN parks AS p
USING (park)
JOIN teams AS t
ON h.team=t.teamid
WHERE h.games>=10
	AND year=2016
GROUP BY p.park_name
		,t.name	
		,h.games
		,h.attendance
ORDER BY avg_attendance DESC
LIMIT 5;
--ANSWER: Dodger Stadium, Los Angeles Dodgers average attendance: 45720
--Busch Stadium III, St. Louis Browns average attendance: 42525
--Busch Stadium III, St. Louis Perfectos average attendance:42525
--Busch Stadium III, St. Louis Cardinals average attendance:42525
--Rogers Centre, Toronto Blue Jays average attendance:41878

--LOWEST AVG ATTENDANCE PER GAME IN 2016:
SELECT p.park_name AS park	
		,t.name AS team	
		,ROUND(SUM(h.attendance::numeric)/SUM(h.games::numeric),0) AS avg_attendance
FROM homegames AS h
JOIN parks AS p
USING (park)
JOIN teams AS t
ON h.team=t.teamid
WHERE h.games>=10
	AND year=2016
GROUP BY p.park_name	
		,t.name	
		,h.games	
		,h.attendance
ORDER BY avg_attendance
LIMIT 5;

--ANSWER: Tropicana Field, Tampa Bay Rays average attendance: 15879
--Tropicana Field, Tampa Bay Devil Rays average attendance:  15879
--Oakland-Alameda County Coliseum, Oakland Athletics average attendance:  18784
--Progressive Field, Cleveland Indians average attendance: 19650
--Progressive Field, Cleveland Bronchos	average attendance: 19650

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- SELECT *
-- FROM awardsmanagers
-- WHERE playerid='johnsda02'

-- SELECT *
-- FROM awardsmanagers
-- WHERE playerid='leylaji99'


WITH manager_of_year_al AS (SELECT playerid
									,yearid
									,lgid
							FROM awardsmanagers
							WHERE awardid LIKE 'TSN%'
									AND lgid='AL'),
									
manager_of_year_nl AS (SELECT playerid
					   			,yearid
					   			,lgid
					   	FROM awardsmanagers
						WHERE awardid LIKE 'TSN%'
								AND lgid='NL'),
person_info AS (SELECT playerid
						, namefirst||' '||namelast AS name
				FROM people),
manager_info AS (SELECT playerid	
				 		,yearid	
				 		,teamid
					FROM managers),
team_info AS (SELECT teamid
			  		,yearid
			  		,name
			  		,lgid
				FROM teams)

SELECT pi.name, ti.name
FROM manager_of_year_al AS mal
JOIN manager_of_year_nl AS mnl
ON mal.playerid=mnl.playerid
JOIN manager_info AS mi
ON mal.yearid=mi.yearid
AND mal.playerid=mi.playerid
JOIN team_info AS ti
ON mi.teamid=ti.teamid
AND mi.yearid=ti.yearid
JOIN person_info AS pi
ON mal.playerid=pi.playerid

--ANSWER: Davey Johnson: Baltimore Orioles
--Jim Leyland:Detroit Tigers
-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

--MOB CODING with WIlliam, Brandy, Sullivan, Shaterial, Martha, Selamawit
SELECT am1.playerid AS al_id, am1.yearid AS al_year, am2.yearid AS nl_year, p.namefirst||' '||p.namelast as manager_name, 						m.yearid as managing_year, m.teamid as team
FROM awardsmanagers AS am1
INNER JOIN awardsmanagers AS am2
		USING (playerid)
INNER JOIN people AS p
		USING (playerid)
INNER JOIN managers AS m
		USING (playerid)
WHERE am1.awardid = 'TSN Manager of the Year'
	AND am2.awardid = 'TSN Manager of the Year'
		AND ((am1.lgid = 'AL' AND am2.lgid = 'NL') 
		    OR (am1.lgid = 'NL' AND am2.lgid = 'AL'))
		AND (m.yearid = am1.yearid)		







-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


WITH home_run_2016 AS(SELECT playerid 
							,SUM(hr) AS total_homeruns_2016
						FROM batting
						WHERE yearid=2016
 							AND hr>=1
						GROUP BY playerid),

tenyear_players AS (SELECT  playerid
							,namefirst||' '||namelast AS name
							,DATE_PART('year',finalgame::date)-DATE_PART('year',debut::date) AS years_palying
					FROM people 
					WHERE DATE_PART('year',finalgame::date)-DATE_PART('year',debut::date) >=10),

max_homeruns AS (SELECT playerid
	 					 ,MAX(hr) AS max_homeruns_for_players
					FROM batting
					WHERE yearid <>2016
					GROUP BY playerid)

SELECT tp.name, hr.total_homeruns_2016
FROM tenyear_players AS tp
JOIN home_run_2016 AS hr
ON tp.playerid=hr.playerid
JOIN max_homeruns AS mhr
ON tp.playerid=mhr.playerid
WHERE mhr.max_homeruns_for_players <= hr.total_homeruns_2016;

--ANSWER:
--Mike Napoli 34
--Bartolo Colon	1
--Angel Pagan 12
--Rajai Davis 12
--Adam Wainwright 2
--Francisco Liriano 1
--Robinson Cano 39
--Edwin Encarnacion 42


-- **Open-ended questions**
--cor (two rows ans then partition by team) by ellisia for one of open ended questions
-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?