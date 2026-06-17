use us_infra_funding;

-- Exploratory Data analyze (EDA)
-- _____________________________________________________________________
-- --Data types inital standardization, dublicates checks,
-- --and basic cleaning were done during the stagging phase,
-- -- this is focused on quality validation , missing 
-- -______________________________________________________________________
select 
count(*)
from categories_stagging
group by category_id
having count(*)>1;

select 
count(*) 
from categories_stagging
group by category_name
having count(*)>1;

-- _________________________________________________________________
-- Category table assesment
-- ____________________________________________________________
-- this table contains about project categories ,responsible
-- contractor, and average category-level cost metrics
--  the purpose of avg_cost_million was investiagated to determing whether it represents project budget or category benchmark costs

select 
cs.category_id,
cs.category_name,
ps.project_id,
avg(budget_million) over(partition by cs.category_id) as total,
ps.created_at,
ps.planned_start_date,
ps.actual_start_date,
ps.planned_end_date,
ps.actual_end_date,
ps.budget_million,
ps.actual_cost_milion,
ps.cost_overrun
FROM
categories_stagging as cs
left join projects_stagging as ps
on cs.category_id=ps.category_id;

-- some category handled federal_agency is missing we can consider it
-- agency not recoreder,
-- data missed during collection
select
category_id,
avg_cost_million,
category_name,
count(*) over()
from categories_stagging
where avg_cost_million is null or avg_cost_million=0;
--  ______________________________________________________________
--  Data qualtity check :
-- No missing values were identified:
--  ________________________________________________________________________
select 
state_abbr,
count(*)over()
from contractors_stagging
where state_abbr is null or state_abbr='';
-- ______________________________________________________________
-- validiation focused on business relavant attributes
-- that may support future analysic and reporting
--  ___________________________________________________________

-- years_in_business was reviewed because contractor
-- expreience may infulence project size funding
-- and performance metrics

select 
company_name,
count(*)over()
from contractors_stagging
where year_in_business is null or year_in_business in ('',0);

-- some contractor has missing active_flag value so we will use funding table to check if any contractor has any project asigned in recent year we will mark him to active 
-- or we will create a new drived table ;
select 
company_name,
count(*)over()
from contractors_stagging
where active_flag is null or active_flag in ('','0');

-- ____________________________________________________________________________
-- active_flag values were updated using recent project 
-- participation and funding activity

with info as(
select 
cs.contractor_id,
ps.project_id,
fss.fiscal_year
from contractors_stagging as cs 
left join projects_stagging as ps
on cs.contractor_id=ps.contractor_id
left join funding_sources_stagging as fss
on ps.project_id=fss.project_id
and fss.fiscal_year=(SELECT max(fiscal_year) FROM us_infra_funding.funding_sources_stagging ))

update contractors_stagging
set active_flag=
case 
when contractor_id in (select contractor_id from info) then "yes"
else "no"
end
;


select 
company_name,
count(*) 
from contractors_stagging
group by company_name
having count(*)>1;

-- _____________________________________________________________

SELECT * FROM funding_sources_stagging;


select 
project_id,
count(funding_id)
from funding_sources_stagging
where funding_type=""
group by project_id;

-- ______________________________________________________________________________
-- missing funding_type values were invesitgated using
-- project level frequency analysis no reliable dominant
-- patter were identified therefore missing values were retained


WITH type_counts AS (
    SELECT
        project_id,
        LOWER(funding_type) AS funding_type,
        COUNT(*) AS cnt
    FROM funding_sources_stagging
    WHERE funding_type IS NOT NULL
    GROUP BY project_id, funding_type
),

ranked AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY project_id
               ORDER BY cnt DESC
           ) AS rn
    FROM type_counts
)

select  * from ranked;

-- _____________________________________________________________________-

-- missing amount_million values were  investigated 
-- intital category level averages  were tried but rejected 
-- as it significant vary across funding types

select 
lower(funding_type),
min(amount_million),
avg(amount_million),
max(amount_million) 
from funding_sources_stagging
where lower(funding_type)<>''and amount_million <>0
group by lower(funding_type);

select 
trim(lower(funding_type)),
trim(fiscal_year),
avg(amount_million)
from funding_sources_stagging
where funding_type<>"" and fiscal_year is not null and funding_type is not null
group by trim(lower(funding_type)),trim(fiscal_year)
order by trim(fiscal_year), trim(lower(funding_type));


with avg as(
select 
trim(lower(funding_type)) as funding_type,
fiscal_year,
avg(amount_million) as amount_million
from funding_sources_stagging
where funding_type<>"" and fiscal_year is not null and funding_type is not null
group by trim(lower(funding_type)),fiscal_year
order by fiscal_year, trim(lower(funding_type)))

update funding_sources_stagging as ss
inner join avg  as aa
on trim(lower(ss.funding_type))= trim(lower(aa.funding_type))
and ss.fiscal_year=aa.fiscal_year
set ss.amount_million=aa.amount_million
where ss.amount_million is null or ss.amount_million=""
and trim(lower(ss.funding_type))= trim(lower(aa.funding_type))
and ss.fiscal_year=aa.fiscal_year;

-- missing amount_million values were imputed using the 
--  average amount within the same funding type  and fiscal_year 
--  record lacking sufficient info were left null

select 
count(*)
from funding_sources_stagging
where disbursed_pct =0
;
-- approx 10 % of disbursed_pct column values are missing 
-- and required further investigation before imputation
--  

select 
trim(lower(funding_type)),
fiscal_year,
min(disbursed_pct),
avg(disbursed_pct),
max(disbursed_pct),
stddev(disbursed_pct)
from funding_sources_stagging
where disbursed_pct<>0
group by trim(lower(funding_type)),fiscal_year;

SELECT 
max(disbursed_pct),
min(disbursed_pct)
 FROM us_infra_funding.funding_sources_stagging ;


-- no significant outlieres were identified 
-- missing values were be replaced using the avg 
-- disbursed percentage with the same funding_type and fiscal_year;

-- values recorded as 0 represent missing values
-- introduced during the stagging process and were treated as null

with fill as(
select 
trim(lower(funding_type)) as funding_type,
fiscal_year,
min(disbursed_pct) as min,
avg(disbursed_pct) as avg,
max(disbursed_pct) as max
from funding_sources_stagging
where disbursed_pct<>0
group by trim(lower(funding_type)),fiscal_year)

update funding_sources_stagging as aa
inner join fill  as ss
on trim(lower(aa.funding_type))=trim(lower(ss.funding_type))
and aa.fiscal_year=ss.fiscal_year
set aa.disbursed_pct = ss.avg
where aa.disbursed_pct =0
and aa.fiscal_year = ss.fiscal_year
and trim(lower(aa.funding_type))=trim(lower(ss.funding_type));

-- _______________________________________________________________________________________

-- incident dates were reviewed for sequence
-- consistency between incident date and reported and solved
select
count(incident_date)
from incidents_stagging
where incident_date>reported_date;
with flag as(
select 
incident_id,
incident_date,
reported_date,
solved_date,
case
when  incident_id  in 
(select
incident_id
from incidents_stagging 
where incident_date>reported_date
and reported_date>solved_date
and incident_date>solved_date) then "totally inconsistent" else "consistent"
end as date_flag
from incidents_stagging)

select 
count(*)
from flag where date_flag='totally inconsistent';


-- found records containing at least one 
-- sequence inconsistency across date field

with flag2 as(
select 
incident_id,
incident_date,
reported_date,
solved_date,
case
when  incident_id  in 
(select
incident_id
from incidents_stagging 
where incident_date>reported_date
or reported_date>solved_date
or incident_date>solved_date) then "in-valid" else "valid"
end as date_flag
from incidents_stagging)

select 
count(*)
from 
flag2
where date_flag="in-valid";

-- a large number of records contains inconsistenices
-- this may indicate  source date quality issues are differing 
-- business defination for date fields
-- ____________________________________________________________________________________________________



with dd as(
select distinct
incident_type
from incidents_stagging
where incident_type <>""),
ff as(
select 
incident_type,
lower(description)as description
from incidents_stagging
where lower(description)<>""
and lower(incident_type)<>""),
done as(
select 
s.incident_id,
s.incident_type,
s.description,
case 
when s.incident_type =""and d.incident_Type <>"" then d.incident_type
when s.incident_Type="" and s.description<>"" and  lower(s.description)=lower(f.description) then f.incident_type
else s.incident_type
end as flag
from incidents_stagging as s
 left join dd as d
on lower(s.description) regexp lower(d.incident_Type)
left join ff as f
on lower(s.description)=lower(f.description)),

-- missing incident_type values were evaluated using
-- description based pattern match and duplicate 
-- description comparison
-- ______________________________________________________________________________________

 done2 as 
 (select distinct
*
from done ),

done3 as (
select 
incident_id,
min(flag) as flag
 from done2
 group by incident_id
 having count(distinct flag)=1)
 

 update incidents_stagging as s
 join done3 as d
 on s.incident_id=d.incident_id
 set s.incident_type =
 (case 
 when s.incident_type ="" then d.flag
 else s.incident_type 
 end);

-- Filled missing incident_type values using description-based pattern matching
-- and duplicate description matching. Records with multiple possible
-- incident types were excluded to avoid incorrect classification.

-- _____________________________________________________________________________-

-- null values represent unkown injury counts
-- while 0 indicates that no injuries were reported 
select
count(*)
from incidents_stagging
where injuries_reported is null;

select 
max(emergency_repair_cost),
avg(emergency_repair_cost),
min(emergency_repair_cost)
from incidents_stagging
where emergency_repair_cost<>0;
select 
count(*)
from incidents_stagging
where  emergency_repair_cost =0;

-- we will treat 0 in emergency_repair_cost as 0 may be it does not require repair we will not replace with other
-- ________________________________________________________________________________________________________________________

select distinct regulatory_notified from incidents_stagging;

update incidents_stagging
set regulatory_notified= 
(case 
when regulatory_notified in("State DOT",
"EPA",
"Yes",
"OSHA","Y") then "Yes"
when  regulatory_notified  in ("No","N") then "No"
else "Unkown"
end);
-- ____________________________________________________________________

SELECT 
count(*)-count(inspection_date) as inspection_date,
sum(trim(inspector_name)="") as inspectore_nam,
sum(trim(inspector_id)='') as inspector_id,
 sum(trim(result)="")as result,
count(*)-count(score_out_of_100) as score_COUNT,
sum(trim(reinspection_required)="") as reinspection_required,
 count(*)-count(reinspection_date) as reinspection_date
 FROM us_infra_funding.inspection_stagging;
 
--  summary of missing vlaues or empty srring
-- across key column were inspected
-- ___________________________________________________________________________

select
result,
inspection_date,
reinspection_date,
count(*)over()
from inspection_stagging
where (inspection_date>reinspection_date)
and (inspection_date is not null or reinspection_date is not null)
and result ="fail" or result="pass with conditions";
-- _____________________________________________________________________________
with  flag as (
select 
inspection,
inspection_date,
result,
deficiences_found,
reinspection_required,
reinspection_date,
case
when inspection_date > reinspection_date then "date inconssitency"
when  upper(result)="pass" and upper(reinspection_required) ="yes" then "conflict result"
when upper(reinspection_required)="no" and reinspection_date is not null then "Unnecessary reinpection date"
else "no isssue"
end as inspection_flag
from inspection_stagging)
update inspection_stagging as aa 
join flag  as bb
on aa.inspection=bb.inspection
set aa.inspection_flag=bb.inspection_flag;

alter table inspection_stagging
add column  inspection_flag text;

-- inspection records violate business rules
-- flagged and retained for future analysis and reporting

-- __________________________________________________________________________________
SELECT 
sum(trim(state_abbr)="") as state_abbr_string,
count(state_name)-count(*) as state_name_null,
sum(trim(state_name)="") as state_NAME_STRING,
sum(trim(region)="") as state_abbr_string,
count(*)-count(population_2020)
 FROM us_infra_funding.states_stagging;
 
 select 
 count(*)
 from states_stagging
 group by state_abbr;
 
--  states table is mostly unique which tells about each state some has missing values like populaion and some region which cannot be estimated untile we figure it 
--  out from google search so will leave it as it is

--  we see some of the notes empty in state_table we will be doing predictive search to drawn a drived colum by checking the project table where we will find 
--  which contractor has taken this state_project what contractor known for . if we find something matching we will drawn into drived_table;

select 
ss.state_id,
ps.project_id,
cs.contractor_id,
cs.specility,
ss.notes,
i.incident_type
from
states_stagging as ss
left join projects_stagging as ps
on lower(ss.state_abbr)=lower(ps.state_abbr)
left join contractors_stagging as cs
on ps.contractor_id=cs.contractor_id
left join incidents_stagging as i
on ps.project_id=i.project_id;

-- conclusion- missing notes cannot be predicted as we joined contractors,incidents ,and projects no clear pattern were found same notes were containing different
-- incident_type where does not gives us pattern to look for 
-- decision will be null;
-- ________________________________________________________________________________________\

--  some actual_days are missing we will check for missing actual_date and planned_date with ther realted non missing days delayed column rows

-- with this techique rows with actual_date and planned_date missing were recovered and filled;

 with actual_date as(
select 
timeline_id,
project_id,
planned_date,
actual_date,
days_delayed,
case
when actual_date is null and planned_date is not null and days_delayed is not null then date_add(planned_date,interval days_delayed day)
else actual_date
end  as actual_datee 
 from timelines_stagging),
 
planned_date as(
 select 
 timeline_id,
 project_id,
 planned_date,
 actual_date,
 actual_datee,
 days_delayed,
 case
 when planned_date is null and actual_datee is not null and days_delayed is not null then date_sub(actual_datee ,interval days_delayed day)
 else planned_date
 end as planned_datee
 from actual_date)
 
-- planned_date missing column has been recoverd and filled fully
update  timelines_stagging as tt
 join planned_date as pp
 on tt.timeline_id=pp.timeline_id
 and tt.project_id=pp.project_Id
 set tt.planned_date=pp.planned_datee
 where tt.planned_date is null;
 
--  actual_column missing date were recovered and filled;
 update  timelines_stagging as tt
 join planned_date as pp
 on tt.timeline_id=pp.timeline_id
 and tt.project_id=pp.project_Id
 set tt.actual_date=pp.actual_datee
 where tt.actual_date is null;

-- we will flag the incident_id where actual_date is smaller then planned_date but marked as delayed

with a as(
select 
timeline_id,
planned_date
actual_date,
days_delayed,
case 
when actual_date<planned_date and days_delayed >0  then "Timeline conflict"
when actual_date is not null and year(actual_date)>2026 then "timeline exceeds"
else "valid"
end as flag
from timelines_stagging)

-- we will add new column to timeLinde_stagging_table 
update timelines_stagging as t
join a as a
on t.timeline_id=a.timeline_id
set t.timeline_flag=a.flag
where t.planned_date=a.planned_date and t.actual_date=a.actual_date;






















