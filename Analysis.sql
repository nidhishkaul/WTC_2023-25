## Top 10 run scorers
SELECT 
    player, country, runs
FROM
    batting
ORDER BY runs DESC
LIMIT 10;

## Top 10 wicket takers
SELECT 
    player, country, wkts
FROM
    bowling
ORDER BY wkts DESC
LIMIT 10;

## Players with maximum runs from each team
SELECT player, country, runs
FROM (
    SELECT player, runs, country, 
           RANK() OVER (PARTITION BY country ORDER BY runs DESC) AS rnk
    FROM batting 
) ranked_player
WHERE rnk = 1 order by runs desc;

## Players with maximum wickets from each team
select player,country,wkts 
from (
	select player,country,wkts,
		rank() over(partition by country order by wkts desc) as rnk
	from bowling
) ranked_player
where rnk = 1 order by wkts desc;

## Players with best batting average from each team with minimum 10 innings
with CTE as(
	select player,country,ave 'Average',
		rank() over(partition by country order by ave desc) as 'rank'
	from batting where inns>10
)
select player,country,average from CTE where `rank` = 1 order by average desc;

## Players with most 100's
SELECT 
    player, country, `100`
FROM
    batting
ORDER BY 3 DESC
LIMIT 5;

## Players with most 5 wicket hauls
SELECT 
    player, country, `5`
FROM
    bowling
ORDER BY 3 DESC
LIMIT 5;

## Players with most catches from each team
with CTE as(
	select player,catches,
		rank() over(partition by country order by catches desc) as 'rank'
	from fielding where inns>10
)
select player,catches from CTE where `rank` = 1 order by catches desc;

## Top 5 wicket keepers on the basis of dismissal/inning
SELECT 
    player
FROM
    keeping
WHERE
    inns > 10
ORDER BY `dis/inn` DESC
LIMIT 5;

## Number of 100's scored by each team
SELECT 
    country, COUNT(`100`) 'Hundreds Scored'
FROM
    batting
GROUP BY country
ORDER BY COUNT(`100`) DESC;

## Number of 300+ scores by each team
with CTE as(
select team,cast(left(score,3) as unsigned) as `score` from highest_scores
)
select team,count(team) as `300+ scored` from CTE where score>300 group by team order by count(team) desc;

## Rank the teams on the basis of win percentage at home
with CTE1 as(
SELECT 
    winner, COUNT(Is_Home) 'Matches_won_at_Home'
FROM
    matches
WHERE
    winner IS NOT NULL AND Is_home = 'Yes'
GROUP BY winner , Is_Home
),
CTE2 as(
select Winner,count(winner) 'Matches_won' from matches where winner is not null group by winner
)
select CTE1.winner,
round(((Matches_won_at_home/Matches_won)*100),2) `Win Percentage at home` 
	from CTE1 
	join CTE2 
on CTE1.winner = CTE2.winner order by 2 desc;


## Create WTC points table
# Consider there is no such penalty for slow over rate..
with CTE1 as(
SELECT team, COUNT(*) AS matches_played
FROM (
    SELECT `team 1` AS team FROM matches
    UNION ALL
    SELECT `team 2` AS team FROM matches
) AS all_teams
GROUP BY team
ORDER BY matches_played DESC
)
,CTE2 as (
SELECT winner AS team, COUNT(*) AS matches_won
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY matches_won DESC
),
CTE3 as(
with temp_table as(
SELECT `team 1`, `team 2`
FROM matches
WHERE winner is NULL
)
select team,count(team) as `Matches_Drawn` from (
select `team 1` as team from temp_table
	union all
select `team 2` as team from temp_table
) as teams
group by team
)
select CTE1.team,matches_played `matches`,
matches_won `won`,
ifnull(matches_drawn,0) `draw`,
matches_played - matches_won - ifnull(matches_drawn,0) `loss`,
matches_won*12 + ifnull(matches_drawn,0)*4 `points`,
round((matches_won*12 + ifnull(matches_drawn,0)*4)/(matches_played*12) * 100,2) `percentage` 
from CTE1 join CTE2 on CTE1.team = CTE2.team
left join CTE3 on CTE1.team = CTE3.team
order by 7 desc;

