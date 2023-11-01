-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - A data dictionary is included with the files for this project.

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.

-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

SELECT DISTINCT(DATE_PART('year',span_first)) AS game_years
FROM homegames
ORDER BY game_years DESC;
--ANSWER: 1871-2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
--The following helped to orient myslef with the tables I was pulling from
--SELECT *
-- FROM people;
-- -- SELECT*
-- -- FROM appearances;
-- SELECT *
-- FROM teams
--------------------------
SELECT	p.playerid
		,p.namegiven
		,p.namefirst||' '||p.namelast AS play_name
		,p.height
		,t.teamid
		,a.g_all
		,t.name
FROM people as p
LEFT JOIN appearances AS a
USING (playerid)
LEFT JOIN teams AS t
USING (teamid)
ORDER BY height ASC
LIMIT 1;
-- ANSWER:// given name: Edward Carl// name: Eddie Gaedel// height: 43in// team: St. Louis Browns// played 1 game
--top query was my first thought processes, 2nd was one where subquery was added in where clause, which caused it to minimize (not by much) the time it took to run the query: 
SELECT p.playerid
	,p.namegiven
	,p.namefirst||' '||p.namelast AS player_name
	,p.height
	,a.g_all
	,t.name
	,t.teamid
FROM people AS p
JOIN appearances AS a
USING (playerid)
JOIN teams as t
USING (teamid)
WHERE height IN
		(SELECT MIN(height)
		FROM people)
LIMIT 1;
--same result as the 1st query: ANSWER:// given name: Edward Carl// name: Eddie Gaedel// height: 43in// team: St. Louis Browns// played 1 game
	
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

--ANSWER: 15 players made it to the major leagues. David price had the highest aggregated salary at 81851296, and Scotti Madison the lowest at 135000


-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
-- SELECT *
-- FROM fielding
   
SELECT
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
	WHEN pos IN ('P','C') THEN 'Battery'
	END AS position 
--case statement to put pos into three categories
	,SUM(po) AS total_putouts
-- SUM to add up each one of the groups
FROM fielding
WHERE yearid=2016
--filters to only look at year 2016
GROUP BY position
ORDER BY total_putouts DESC;
--group by statement to in a way seperate and group each category
--ANSWER: Infield: 58934// Battery:	41424//  Outfield: 29560

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
--need to find another way to find decade
--CONCAT(LEFT(CAST(yearid AS varchar),3),'0s') AS decade (contributed by Teresa, and this makes more sense) will come back to revise this question

SELECT yearid/10*10 AS decade, ROUND(SUM(so)/SUM(g),2) AS avg_strike_out_per_game
FROM teams								 
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;
--the one above works if i am using float, which is where amanda hinted the question was going

SELECT yearid/10*10 AS decade, ROUND(AVG(so)/AVG(g/2),2) AS avg_strike_out_per_game
FROM teams								 
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;
--need to figure out which one is right for strike out 
--moving on to homeruns which will also need some explaination 
--casting tpe to numeric..
--and find a better way to chnage date to decade
--need to come back

SELECT yearid/10*10 AS decade, ROUND(AVG(hra)/AVG(g/2),2) AS avg_home_run_per_game
FROM teams								 
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;
--below is propably the right srtucture, but I need to do castings and fix the g total since the games are being counted twice
SELECT yearid/10*10 AS decade, ROUND(SUM(hra)/SUM(g),2) AS avg_home_run_per_game
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


SELECT b.playerid,p.namefirst||' '||p.namelast AS name, p.namegiven, sb AS stolen_bases, sb+cs AS total_steal_attempts, 
ROUND(sb::numeric/(sb::numeric+cs::numeric)*100,2) AS pct_success
FROM batting AS b
JOIN people AS p
USING (playerid)
WHERE yearid=2016
	AND (sb+cs)>=20	
GROUP BY b.playerid,b.cs, b.sb,p.namefirst,p.namelast, p.namegiven
ORDER BY pct_success DESC;

--need to see if grouping /select has too much, coming back for revisions at a later time
--why is the pct not calculating? coming back to this UPDATE: needed to cast as numeric for it to calculate pertcentage
--might concat name to one column later 

--ANSWER: Chris	Owings/ Christopher Scott	21 out of 23, percent succes 91.30%
	
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

--might use cte to make two table for this question 
--below gives only the min wins for series winners and max win for series losers for each year
SELECT yearid
		,MAX(w) AS maxwins_series_losers	
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND wswin='N'
GROUP BY yearid
ORDER BY maxwins_series_losers DESC
--ANSWER 7A: Maximum number of wins by a series loser happened in 2001 with 116
		
SELECT yearid
		,MIN(w) AS minwins_series_winners
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
		AND wswin='Y'
GROUP BY yearid
ORDER BY minwins_series_winners
--ANSWER 7B: Minimum number of winns by series winners happened in 1981 with 63. The reson below: 
--The 1981 Baseball Strike caused a strike-shortened season. Teams played between 102 to 110 games, since games were canceled from June 12th to August 10th and not made up to even out the schedule.

WITH series_losers AS (SELECT yearid, MAX(w) AS maxwins_series_losers	
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='N'
					   			AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC),

series_winners AS (SELECT yearid, MIN(w) AS minwins_series_winners
					FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
								AND wswin='Y'
				   				AND yearid <> 1981
					GROUP BY yearid
					ORDER BY yearid DESC)				
SELECT 
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers < sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,2) AS percent_of_greater_wins_of_series_winners,
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers > sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sl.maxwins_series_losers)*100,2) AS percent_of_greater_wins_of_series_losers,
	ROUND(SUM(CASE WHEN sl.maxwins_series_losers = sw.minwins_series_winners 							THEN 1.00 ELSE 0 END)/COUNT(sw.minwins_series_winners)*100,2) AS percent_of_tie_between_losers_winners
FROM series_losers as sl
JOIN series_winners as sw
USING (yearid)
--ANSWER 7C: The case that a team with the most wins also won the world series happened 22.22 percent of the time



-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
-- SELECT *
-- FROM homegames

SELECT p.park_name AS park, t.name AS team, ROUND(h.attendance::numeric/h.games::numeric,0) AS avg_attendance
FROM homegames AS h
JOIN parks AS p
USING (park)
JOIN teams AS t
ON h.team=t.teamid
WHERE h.games>=10
	AND h.attendance <>0
	AND year=2016
GROUP BY p.park_name, t.name,h.games, h.attendance
ORDER BY avg_attendance DESC
LIMIT 5;
--ANSWER: Dodger Stadium, Los Angeles Dodgers average attendance: 45720
--Busch Stadium III, St. Louis Browns average attendance: 42525
--Busch Stadium III, St. Louis Perfectos average attendance:42525
--Busch Stadium III, St. Louis Cardinals average attendance:42525
--Rogers Centre, Toronto Blue Jays average attendance:41878

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
-- 							GROUP BY yearid, playerid),
WITH manager_of_year_al AS (SELECT playerid, yearid
							FROM awardsmanagers
							WHERE awardid='TSN Manager of the Year'
							AND lgid='AL'),
manager_of_year_nl AS (SELECT playerid, yearid
						FROM awardsmanagers
						WHERE awardid='TSN Manager of the Year'
						AND lgid='NL'),
person_info AS (SELECT playerid, namefirst||' '||namelast AS name, namegiven
				FROM people),
manager_info AS (SELECT playerid, yearid, teamid
					FROM managershalf),

team_info AS (SELECT teamid, yearid, name
				FROM teams)
SELECT p_info.name, p_info.namegiven, t_info.name, m_info.teamid
FROM manager_of_year_al AS m_al
FULL JOIN manager_of_year_nl AS m_nl
ON m_al.playerid=m_nl.playerid
FULL JOIN person_info AS p_info
ON m_al.playerid= p_info.playerid
FULL JOIN manager_info AS m_info
ON m_al.playerid= m_info.playerid
FULL JOIN team_info AS t_info
ON m_info.teamid= t_info.teamid
WHERE m_al.playerid=  m_nl.playerid

--ANSWER: Davey Johnson/ David Allen and Jim Leyland/ James Richard
--need to revise the above might do subquery and cte


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


WITH home_run_2016 AS(SELECT playerid 
		,g
		,hr
		,teamid
		,lgid
FROM batting
WHERE yearid=2016
 		AND hr>=1
ORDER BY hr DESC),
veteran_players AS (SELECT  playerid
		,namefirst||' '||namelast AS name
		,namegiven
		,DATE_PART('year',finalgame::date)-DATE_PART('year',debut::date) AS years_palying
		,playerid
FROM people 
WHERE DATE_PART('year',finalgame::date)-DATE_PART('year',debut::date) >=10)

FROM home_run_2016 AS hr
JOIN 
ON 
 


--query shows 2016 playerid, year, teamid,#of games for pitchers that played in 2016 and had at least 1 homerun ordered by desc;
--need to calculate how to find players that have been in the league for 10 years 


-- **Open-ended questions**
--cor (two rows ans then partition by team) by ellisia for one of open ended questions
-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?