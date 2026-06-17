use us_infra_funding;

SELECT *FROM us_infra_funding.projects_stagging;
-- ______________________________________________________________________________--
-- count of projects on hold ,active,completed,cancelled ,planning,under review
select 
(select count(lower(status)) from projects_stagging where lower(status)="completed") as complete_count,
(select count(lower(status)) from projects_stagging where lower(status)="on hold") as Onhold_count,
(select count(lower(status)) from projects_stagging where lower(status)="active") as active_count,
(select count(lower(status)) from projects_stagging where lower(status)="cancelled") as cancelled_count,
(select count(lower(status)) from projects_stagging where lower(status)="planning") as plannning_count,
(select count(lower(status)) from projects_stagging where lower(status)="under review") as review_count;
-- ________________________________________________________________________________________________________

-- overall aggregation fact table of each state

SELECT *FROM us_infra_funding.projects_stagging;


with count as(
select 
state_abbr,
count(project_Id) number_of_projects,
round(sum(budget_million),2) overYear_the_budget,
round(sum(actual_cost_milion),2) actual_spend_overtheYear
from projects_stagging
group by state_abbr),

funding as(
select 
ps.state_abbr,
round(sum(fs.amount_million),2) as  funding_overtheYear
from projects_stagging as ps
left join funding_sources_stagging as fs
on ps.project_Id=fs.project_id
group by ps.state_abbr),

summary as(
select 
c.state_abbr,
overYear_the_budget,
 actual_spend_overtheYear,
 funding_overtheYear
from count as c
inner join funding as f
on c.state_abbr=f.state_abbr)

select 
sa.state_name,
s.*
from states_stagging as sa
inner join summary as s
on sa.state_abbr=s.state_abbr;



-- _____________________________________________________________________________________________________________________________________-

-- states year----wise aggregation table as fact table
select
distinct
ss.state_abbr,
ss.state_name,
ss.region,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2018) ),2) as  projects_2018_budget,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2019) ),2) as  projects_2019_budget,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2020) ),2) as  projects_2020_budget,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2021) ),2) as  projects_2021_budget,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2022) ),2) as  projects_2022_budget,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2023) ),2) as  projects_2023_budget,
round((select sum(budget_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2024) ),2) as  projects_2024_budget,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2018) ),2) as actual_spend_2018,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2019) ),2)as actual_spend_2019,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2020) ),2)as actual_spend_2020,
-- round((select sum(actual_cost_million) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2020) ),2)as actual_spend_2020,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2021) ),2)as actual_spend_2021,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2022) ),2)as actual_spend_2022,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2023) ),2)as actual_spend_2023,
round((select sum(actual_cost_milion) from projects_stagging where state_abbr=ss.state_abbr group by state_abbr,year(2024) ),2)as actual_spend_2024,
round((select sum(fs.amount_million) from funding_sources_stagging as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr
and fs.fiscal_year=2018 group by ps.project_id),2) as funding_year2018,
round((select sum(fs.amount_million) from funding_sources_stagging  as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr
and fs.fiscal_year=2019 group by ps.project_id),2) as funding_year2019,
round((select sum(fs.amount_million) from funding_sources_stagging as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr
and fs.fiscal_year=2020 group by ps.project_id),2) as funding_year2020,
round((select sum(fs.amount_million) from funding_sources_stagging  as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr 
and fs.fiscal_year=2021 group by ps.project_id),2) as funding_year2021,
round((select sum(fs.amount_million) from funding_sources_stagging  as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr
and fs.fiscal_year=2022 group by ps.project_id),2) as funding_year2022,
round((select sum(fs.amount_million) from funding_sources_stagging  as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr
and fs.fiscal_year=2023 group by ps.project_id),2) as funding_year2023,
round((select sum(fs.amount_million) from funding_sources_stagging as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr
and fs.fiscal_year=2024 group by ps.project_id),2) as funding_year2024,
round((select sum(fs.amount_million) from funding_sources_stagging as fs
  right join projects_stagging as p on fs.project_id=p.project_id
where p.state_abbr=ps.state_abbr 
and fs.fiscal_year=2025 group by ps.project_id),2) as funding_year2025
from states_stagging as ss
left join projects_stagging as ps
on lower(ss.state_abbr)=lower(ps.state_abbr)
right join funding_sources_stagging as fss
on ps.project_id=fss.project_id;
-- ________________________________________________________________________________________________________
-- incident per project, total_injuries and damage of property
SELECT * FROM us_infra_funding.incidents_stagging;

select
ii.project_id,
count(ii.incident_id) total_incident,
sum(ii.injuries_reported) total_injuries,
round(sum(ii.property_damage_million),2) total_property_total
from incidents_stagging as ii
group by project_Id
order by project_id  asc;
-- _______________________________________________________________________________________
-- all about project timeline avg_delay_days and avg_completion time
select 
distinct
project_id,
count(*) over(partition by project_ID) total_Milestone,
sum(status='in progress') as in_progress_milestone,
sum(status='skipped') as skipped_milestone,
sum(status='delayed') as delayed_milestone,
sum(status='complete') as complete_milestone,
sum(status='not started') as not_started_milestone,
floor(abs(avg(case 
when( actual_date is not null and planned_date is not null) and actual_date>planned_date and timeline_flag="valid" then datediff(planned_date,actual_date)
end )))as avg_delay_days,
floor(avg(case 
when( actual_date is not null and planned_date is not null) and actual_date<planned_date and timeline_flag="valid" then datediff(planned_date,actual_date)
end ))as avg_completion_days
from timelines_stagging 
group by project_id;
-- ______________________________________________________________________________________________________________

-- states with the max total  infrastructure spending
with total as 
(select 
state_abbr,
sum(actual_cost_milion) as total_spending
from projects_stagging
group by state_abbr)
select 
state_abbr,
total_spending
from total
where total_spending>=(select max(total_spending) from total);
-- _________________________________________________________________________________________

-- which years saw the highest projects intiated ?

with total as (
select 
year(actual_start_date) as year,
count(project_ID) as total_project
from projects_stagging
where actual_start_date is not null
group by year(actual_start_date)
order by year(actual_start_date) asc)
select 
year,
total_project
from total
where total_project >= (select max(total_project) from total);
-- __________________________________________________________________________________________

-- for each funding type which fiscal year had the highest  total_funding amount?

with total_funding as (
select 
lower(funding_type) as funding_type,
fiscal_Year,
count(funding_id)  as no_Of_fundings,
sum(amount_million) as  total_amount
from funding_sources_stagging
group by fiscal_year,lower(funding_type)),

 overall as ( select 
 lower(funding_type) as type ,
 fiscal_year,
 count(funding_Id) as number,
 max(amount_million) as max
 from funding_sources_stagging
 group by fiscal_year,lower(funding_type))
 
 select 
 tf.funding_type,
 tf.fiscal_year,
 total_amount
 from total_funding as tf
 where total_amount>=(select max from overall where type=tf.funding_type and fiscal_year=tf.fiscal_year);
--  __________________________________________________________________________________________________________________________
-- which project categories received largest total funidng ?
with  summary as (
select 
cs.category_name,
count(ps.project_id) as project_count,
sum(fss.amount_million) as total_funding
from categories_stagging as cs
left join projects_stagging as ps 
on cs.category_id=ps.category_id
right join funding_sources_stagging as fss
on ps.project_id=fss.project_id
group by cs.category_name)
select 
*
from summary 
order by total_funding desc
limit 1;
-- __________________________________________________________________________________________________________________________
-- which contractor handled the most projects?

with total as(
select 
ps.contractor_id,
count(ps.project_id) as number_oF_projects
from contractors_stagging as cs
left join  projects_stagging as ps 
on cs.contractor_id=ps.contractor_id
group by  ps.contractor_id)
select 
* 
from total 
order by number_oF_projects DESC
limit 1;

-- OR 

WITH  AA AS(
SELECT 
CONTRACTOR_ID,
COUNT(PROJECT_ID) AS TOTAL
FROM PROJECTS_STAGGING
WHERE CONTRACTOR_ID IS NOT NULL
GROUP BY CONTRACTOR_ID)

SELECT * FROM AA
ORDER BY  TOTAL DESC 
LIMIT 1;

-- _______________________________________________________________________________________________
-- WHICH CONTRACTORS MANAGED THE HIGHEST TOTAL_PROJECT_VALUE

WITH INFO AS(
SELECT 
CS.CONTRACTOR_ID,
COUNT(PS.PROJECT_ID) AS PROJECT_COUNT,
SUM(PS.ACTUAL_COST_MILION) AS TOTAL_AMOUNT
FROM CONTRACTORS_STAGGING AS CS
LEFT JOIN PROJECTS_STAGGING  AS PS
ON CS.CONTRACTOR_ID=PS.CONTRACTOR_ID
GROUP BY CS.CONTRACTOR_ID)

SELECT * FROM INFO 
ORDER BY TOTAL_AMOUNT DESC
LIMIT 1;

-- ________________________________________________________________

-- WHICH 10 PROJECTS EXCEEDS THEIR PLANNED BUDGET BY THE LARGEST AMOUNT

WITH BUDGET AS(
SELECT 
PROJECT_ID,
SUM(BUDGET_MILLION) AS TOTAL_BUDGET
FROM PROJECTS_STAGGING
WHERE BUDGET_MILLION IS NOT NULL
GROUP BY PROJECT_iD),
 ACTUAL AS(SELECT 
PROJECT_ID,
SUM(ACTUAL_COST_MILION) AS ACTUAL_TOTAL
FROM PROJECTS_STAGGING
WHERE ACTUAL_COST_MILION IS NOT NULL
GROUP BY PROJECT_iD),
SUMMARY AS(
SELECT 
B.PROJECT_ID,
B.TOTAL_BUDGET,
A.ACTUAL_TOTAL,
A.ACTUAL_TOTAL-B.TOTAL_BUDGET AS LEADING_COST
FROM 
BUDGET AS B
JOIN ACTUAL  AS A
ON B.PROJECT_ID=A.PROJECT_ID)
SELECT * FROM SUMMARY 
ORDER BY LEADING_COST DESC 
LIMIT 10;
-- _____________________________________________________________________________________________--
-- WHICH STATES HAVE THE HIGHEST AVG COMPLETION TIME?
with avg as (
select 
ss.state_abbr,
ps.actual_start_date,
ps.actual_end_date,
abs(datediff(ps.actual_start_date,ps.actual_end_date)) as diff
from states_stagging  as ss
left join projects_stagging as ps
on lower(ss.state_abbr)=lower(ps.state_abbr)
where ps.actual_start_date is not null and ps.actual_end_date is not null) ,
bb as(
select
state_abbr,
floor(avg(diff)) as avg_time
from avg
group by state_abbr)
select 
* from bb 
order by avg_time desc 
limit 1;
-- _______________________________________________________________________________________________________________

-- which projects had the highest number of delayed milestone?
with no as(
select
distinct
ps.project_id,
ts.milestone_name,
year(ps.actual_start_date) as year,
count(ts.timeline_id) over(partition by ps.project_id,year(ps.actual_start_date)) as no_of_milestone
from 
projects_stagging as ps 
left join timelines_stagging as ts
on ps.project_id=ts.project_id
where ts.status="delayed")

select 
* from no 
where no_of_milestone>2
and year is not null
order by year asc;
-- __________________________________________________________________________________________

-- ranking projects within each state by total project cost 

with total as(
select 
ss.state_abbr,
ps.project_id,
ceiling(sum(ps.actuaL_COST_milion) over (partition by ss.state_abbr,ps.project_id) ) as total_amount
from states_stagging  as ss
left join projects_stagging as ps
on lower(ss.state_abbr)=lower(ps.state_abbr)
order by ss.state_abbr asc)

select * ,
dense_rank() over( partition by state_abbr order by total_amount desc) as ranking
from total
where total_amount is not null;
-- ________________________________________________________________________________________________
with total as (
select 
distinct
state_abbr,
year(actual_start_date) as year,
round(sum(actual_cost_milion) over(partition by state_abbr,year(actual_start_date)),2) as total
from projects_stagging
where actual_cost_milion is not null and actual_start_date is not null
order by state_abbr,year(actual_start_date))

select 
* ,
round(sum(total) over( order by state_abbr,year),2) as running_total
from total;

-- ____________________________________________________________________________

-- find projects where more than 50% of the milestones were delayed

with total as (
select  
project_id,
count(milestone_name) as total_count
from timelines_stagging
group by project_id),

delayed_count as (
select 
project_id ,
count(milestone_name) as delayed_count
from timelines_stagging 
where status = "delayed"
group by project_id),

per as (
select 
t.project_id,
t.total_count,
d.delayed_count,
d.delayed_count/t.total_count*100 as percentage
from total as t
join delayed_count as d
on t.project_id=d.project_id)

select 
* from 
per 
where percentage>50;
-- ___________________________________________________________________________________________________________

-- for each milestone type compare avg delay against the overall avg time

with avg_milestone as(
select 
milestone_name,
round(avg(timeline_id),2) as avg_per_milestone
from timelines_stagging 
where status="delayed"
group by milestone_name),

avg_overall as (
select 
distinct
*,
round(avg(avg_per_milestone) over(),2) as overall_avg
from avg_milestone
)

select 
* ,
round(avg_per_milestone-overall_avg,2) as differences
from avg_overall;
-- __________________________________________________________________________________

-- which project that moved from delayed milestone to later completed milestone

select 
distinct
a.timeline_id,
a.project_id,
a.milestone_name,
year(a.actual_date)as a_date,
year(b.actual_date) as b_date,
a.status as  a_status,
b.status as b_status
 from 
timelines_stagging as a
inner join timelines_stagging  as b
on a.milestone_name=b.milestone_name
and a.project_id=b.project_id
and year(b.actual_date)>year(a.actual_date)
where a.status="delayed" and b.status="complete";
-- _____________________________________________________________________________________________

-- which projects have the longest period between their first and last milestone?

with compare as(
select 
t.project_id,
t.actual_date as first_date,
tt.actual_date as last_date
 from 
timelines_stagging as t
join timelines_stagging as tt
on t.project_id=tt.project_id
and t.actual_date is not null and tt.actual_date is not null
where t.actual_date=(select min(actual_date) from timelines_stagging as a where a.project_id=t.project_id 
group by project_id)
and tt.actual_date=(select  max(actual_date) from timelines_stagging as a where a.project_id=t.project_id
group by project_id)
order by t.project_id),

compare2 as(
select 
*,
datediff(last_date,first_date) as difference
from compare)

select 
*,
rank() over(order by difference desc)  as ranking
from compare2
order by  ranking asc;



-- _________________________________________________________________

-- creation of contractor_summary
with total_count as(
select 
distinct
contractor_id,
count(project_id) over(partition by contractor_Id) as total_count
from projects_stagging
where contractor_id is not null),

total_budget as(
select 
contractor_id,
round(sum(budget_million),2) as budget_amount
from projects_stagging
where contractor_id is not null
group by contractor_id),

total_actual_cost as(
select 
contractor_id,
round(sum(actual_cost_milion),2) as actual_amount
from projects_stagging
where contractor_id is not null
group by contractor_id),

 total_funding as (
 select 
 distinct
 cs.contractor_id,
round(sum(fss.amount_million)over(partition by cs.contractor_id),2) as total_funding_amount
 from contractors_stagging as cs
 left join projects_stagging as ps 
 on cs.contractor_id=ps.contractor_id
 right join funding_sources_stagging as fss
 on ps.project_id=fss.project_id
 where cs.contractor_id is not null),
 
 
 project_status1 as( 
 select 
 contractor_Id,
 count(project_id) as completed_project
 from projects_stagging 
 where lower(status)="completed"
 and contractor_id is not null
 group by contractor_id
 ),
 
 project_status2 as(
  select 
 contractor_Id,
 count(project_id) as active_project
 from projects_stagging 
 where lower(status)="active"
 and contractor_id is not null
 group by contractor_id),
 
 project_status3 as (
  select 
 contractor_Id,
 count(project_id) as onHold_project
 from projects_stagging 
 where lower(status)="on hold"
 and contractor_id is not null
 group by contractor_id),
 
 
 project_status4 as (
  select 
 contractor_Id,
 count(project_id) as cancelled_project
 from projects_stagging 
 where lower(status)="cancelled"
 and contractor_id is not null
 group by contractor_id),
 
 completedtime as(
 select 
 contractor_Id,
 round(avg(datediff(actual_end_date,actual_start_date)),2) as avg_completed_time
 from projects_stagging 
 where lower(status)="completed" and (actual_start_date is not null and actual_end_date is not null)
 and contractor_id is not null
 group by contractor_id)
 
 select 
 cs.contractor_id,
 cs.company_name,
 tc. total_count,
 tb.budget_amount,
 tac. actual_amount,
 tf.total_funding_amount,
 ps1.completed_project,
 ps2.active_project,
 ps3.onHold_project,
 ps4.cancelled_project,
 c.avg_completed_time
 from contractors_stagging as cs
 left join total_count as tc
 on cs.contractor_id=tc.contractor_id
  left join total_budget as tb
 on cs.contractor_id=tb.contractor_id
 left join total_actual_cost tac
 on cs.contractor_id=tac.contractor_id
 left join total_funding as tf
 on cs.contractor_id=tf.contractor_id
 left join project_status1 as ps1
 on cs.contractor_id=ps1.contractor_id
 left join project_status2 as ps2
  on cs.contractor_id=ps2.contractor_id
 left join project_status3 as ps3
  on cs.contractor_id=ps3.contractor_id
left join project_status4 as ps4
  on cs.contractor_id=ps4.contractor_id
 left join completedtime as c
 on cs.contractor_id=c.contractor_id;




