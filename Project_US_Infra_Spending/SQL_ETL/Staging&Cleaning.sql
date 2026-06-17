use us_infra_funding;

/* creating stagging table for eda */

create table categories_stagging
(category_id int primary key,
category_name varchar(40),
sector varchar(20),
federal_agency varchar(20),
avg_cost_million float,
priority_level varchar(20),
notes varchar(20) default (null));

drop table categories_stagging;
alter table contractors 
rename to contractors_stagging;
create table contractors (
contractor_id int primary key,
company_name  varchar(40),
city  varchar(20),
state_abbr  varchar(20),
company_size  varchar(20),
annual_revenue_million float,
employees int,
year_in_business int,
specility  varchar(20),
certified_minority_owned  varchar(20),
certified_women_owned  varchar(20),
active_flag  varchar(20));
drop table contractors_stagging;
create table funding_sources_stagging
(funding_id int primary key,
project_id int ,
funding_type  varchar(20),
amount_million float,
fiscal_year year,
agency_name  varchar(20),
grant_number  varchar(30),
disbursed_pct float,
approval_date date,
notes  varchar(30));

create table incidents_stagging 
(incident_id int primary key,
project_id int,
incident_date date,
incident_type  varchar(20),
severity  varchar(20),
injuries_reported int,
fatalities int,
property_damage_million float,
cause  varchar(20),
reported_by  varchar(20),
reported_date  varchar(20),
solved_date  varchar(20),
emergency_repair_cost float,
insurance_claim  varchar(20),
regulatory_notified  varchar(20),
description  varchar(20));

create table inspection_stagging
(inspection int primary key,
project_id int ,
inspection_date date,
inspector_name  varchar(20),
inspector_id  int,
inspection_type  text,
result  varchar(20),
score_out_of_100 int,
deficiences_found  int,
reinspection_required  text,
reinspection_date date,
regulatory_body  varchar(20),
notes  text);
drop table projects_stagging;
create table projects_stagging 
(project_id int primary key,
project_name  text,
state_abbr  varchar(20),
category_id int,
contractor_id int ,
status  varchar(20),
budget_million float,
actual_cost_milion float,
cost_overrun float,
planned_start_date date,
actual_start_date date,
planned_end_date date,
actual_end_date date,
federal_funding float,
congressional_district int ,
project_manager  varchar(20),
created_at date,
last_updated date);

create table states_stagging
(state_id int primary key,
state_abbr  varchar(20),
state_name  varchar(20),
region  varchar(20),
population_2020 bigint,
gdp_millions float,
poverty_rate float,
unemployment_rate float,
infrastructure_grade  varchar(20),
notes  varchar(20));

create table timelines_stagging
(timeline_id int primary key,
project_id int,
milestone_name  text,
planned_date date,
actual_date date,
days_delayed int,
dalay_reason text,
responsible_party  text,
status  varchar(20),
notes  text);

-- _______________________________________________________________________________________
-- cleaning phase 
SELECT * FROM us_infra_funding.categories_raw;

insert into categories_stagging
select 
category_id,
category_name,
sector,
federal_agency,
cast(nullif(avg_cost_million,'N/A') as float) as avg_cost,
priority_level ,
notes 
from categories_raw;

select * from contractors_raw;

insert into contractors_stagging
select 
contractor_id,
company_name,
city,
state_abbr,
company_size,
cast(annual_revenue_million as float) as annual_revenue,
-- cast(nullif(employees,"") as signed) as employees,
case employees
when 'n/a' then nullif(employees,'n/a')
when "" then nullif(employees,"")
else cast(employees as signed) 
end employees,
-- cast(nullif(years_in_business,("n/a"or"")) as signed) as years,          
case years_in_business
when 'n/a' then nullif(years_in_business,"n/a")
when "" then nullif(years_in_business,"")
else cast(years_in_business as signed)
end years_in_business,
specialty,
case  certified_minority_owned
when '1' then replace(certified_minority_owned,'1',"yes")
when '0' then  replace(certified_minority_owned,'0',"no")
when '' then nullif(certified_minority_owned,'')
when 'N' then  replace(certified_minority_owned,'N',"no")
else certified_minority_owned
end cc,
case certified_woman_owned
when 'Y' then replace(certified_woman_owned,"Y","yes")
when 'N' then replace(certified_woman_owned,"N","no")
else certified_woman_owned
end ddd,
case active_flag
when '1'then  replace( active_flag,"1","yes")
when '0' then replace(active_flag,"2","no")
else  lower(active_flag)
end 
from contractors_raw;


SELECT * FROM us_infra_funding.funding_sources_raw;
insert into funding_sources_stagging
select 
cast(funding_id as signed) as funding_id,
cast(project_id as signed) as project_id,
funding_type,
cast(nullif(amount_million_usd,"") as float) as amount_million_usd,
CASE 
WHEN FISCAL_YEAR REGEXP '[A-Za-z///?-]' then nullif(fiscal_year,0)
ELSE CAST(nullif(FISCAL_YEAR,"") AS SIGNED) 
END fascial_year,

nullif(agency_name,"") as agency_name,
nullif(grant_number,"") as grant_number,

case disbursed_pct
when disbursed_pct  not regexp '[0-9]' then ifnull(null,0)
else cast(disbursed_pct as float)
end,

convert_date(approval_date) as date,
notes
from funding_sources;

SELECT * FROM us_infra_funding.incidents_raw;
insert into incidents_stagging
select 
incident_id,
project_id,
/*
i got lots fo ambuigous dates inside the incident_date column so i decided to change them into valide date as per source date from as its a united state 
datasets*/
CASE
    WHEN REPLACE(incident_date,'/','-')
         REGEXP '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
    THEN STR_TO_DATE(REPLACE(incident_date,'/','-'),'%d-%m-%Y')

    WHEN REPLACE(incident_date,'/','-')
         REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
    THEN STR_TO_DATE(REPLACE(incident_date,'/','-'),'%m-%d-%Y')

    WHEN REPLACE(incident_date,'/','-')
         REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    THEN STR_TO_DATE(REPLACE(incident_date,'/','-'),'%Y-%m-%d')
END,
incident_type,
severity,
case
when injuries_reported in ('?','-','N/A','') then null
else cast(injuries_reported as signed) 
end injurires,
case
when fatalities in ('?','-','N/A','TBD','') then null
else cast(FATALITIES as signed) 
end FAT,
case
when property_damage_million_usd in ('?','-','N/A','TBD') then null
else cast(property_damage_million_usd as float) 
end damage,
cause,
reported_by,
CASE
    WHEN REPLACE(reported_date,'/','-')
         REGEXP '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
    THEN STR_TO_DATE(REPLACE(reported_date,'/','-'),'%d-%m-%Y')

    WHEN REPLACE(reported_date,'/','-')
         REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
    THEN STR_TO_DATE(REPLACE(reported_date,'/','-'),'%m-%d-%Y')

    WHEN REPLACE(reported_date,'/','-')
         REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    THEN STR_TO_DATE(REPLACE(reported_date,'/','-'),'%Y-%m-%d')
END as reported,
CASE
    WHEN REPLACE(resolution_date,'/','-')
         REGEXP '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
    THEN STR_TO_DATE(REPLACE(resolution_date,'/','-'),'%d-%m-%Y')

    WHEN REPLACE(resolution_date,'/','-')
         REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
    THEN STR_TO_DATE(REPLACE(resolution_date,'/','-'),'%m-%d-%Y')

    WHEN REPLACE(resolution_date,'/','-')
         REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    THEN STR_TO_DATE(REPLACE(resolution_date,'/','-'),'%Y-%m-%d')
END as reess,
case
when emergency_repair_cost_million in ('-','?','N/A','TBD') then 0
else round(cast(emergency_repair_cost_million as float),2)
end as eerp,
case
when insurance_claim_filed in ('Yes','1','Y') then "Yes"
when insurance_claim_filed in ('No','0',"N") then "No"
when insurance_claim_filed="Pending" then "Pending"
else null
end as insurance_claim,
regulatory_notified,
description
from incidents_raw;

-- ___________________________________________________
ALTER TABLE INSPECTION_STAGGING
MODIFY COLUMN INSPEctor_id TEXT;
SELECT * FROM us_infra_funding.inspections_raw;

-- here lot of dates are in same foramt and ambigous we treated them in us format of mdy
insert into inspection_stagging
select 
cast(inspection_id as signed) as id,
convert(nullif(project_id,""),signed) as p_id,
case 
when  replace(inspection_date,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(inspection_date,'/','-'),'%Y-%m-%d')
when replace(inspection_date,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(inspection_date,'/','-'),'%d-%m-%Y')
when replace(inspection_date,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(inspection_date,'/','-'),'%m-%d-%Y')
 else null
 end as dd,
 inspector_name,
 inspector_id,
 inspection_type,
 result,
 case
when score_out_of_100 in('?','-','N/A','TBD',"",'n/a'
) then null
else cast(score_out_of_100 as signed) 
end score,
case
when  deficiencies_found 
in ('?','-','N/A','TBD',""
) then null 
else  cast(deficiencies_found as signed)
end found,
case 
when reinspection_required="N" then "NO"
when reinspection_required="Y" then "YES"
ELSE REINSPECTION_REQUIRED
END AS RR,
case 
when  replace(reinspection_date,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(reinspection_date,'/','-'),'%Y-%m-%d')
when replace(reinspection_date,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(reinspection_date,
'/','-'),'%d-%m-%Y')
when replace(reinspection_date,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(reinspection_date,'/','-'),'%m-%d-%Y')
else null
end redate,
regulatory_body,
notes
from 
inspections_raw;

-- _________________________________________________________________________________

SELECT * FROM us_infra_funding.projects_raw;

insert into projects_stagging
select 
cast(project_id as signed) as p_id,
project_name,
state_abbr,
case 
when lower(category_id) in ("","n/a","-","?",'tbd') then null
else cast(category_id as signed)
end category_id,
case 
when lower(contractor_id) in ("","n/a","-","?",'tbd') then null
else cast(contractor_id as signed)
end contractor_id,
status,
case
when lower(trim(budget_million_usd)) in ('','n/a','-','?','tbd') then null
else cast(budget_million_usd as float)
end budget,
case
when lower(actual_cost_million_usd) in ("","n/a","-","?",'tbd') then null 
else cast(actual_cost_million_usd as float)
end actucal_cost,
case
when lower(cost_overrun_pct) in ("","n/a","-","?",'tbd') then null 
else cast(cost_overrun_pct as float)
end as overrun,
case 
when  replace(planned_start_date,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(planned_start_date,'/','-'),'%Y-%m-%d')
when replace(planned_start_date,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(planned_start_date,
'/','-'),'%d-%m-%Y')
when replace(planned_start_date,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(planned_start_date,'/','-'),'%m-%d-%Y')
else null
end p_start_date,
case 
when  replace(actual_start_date,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(actual_start_date,'/','-'),'%Y-%m-%d')
when replace(actual_start_date,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(actual_start_date,
'/','-'),'%d-%m-%Y')
when replace(actual_start_date,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(actual_start_date,'/','-'),'%m-%d-%Y')
else null
end as actual_s_date,
case 
when  replace(planned_end_date,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(planned_end_date,'/','-'),'%Y-%m-%d')
when replace(planned_end_date,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(planned_end_date,
'/','-'),'%d-%m-%Y')
when replace(planned_end_date,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(planned_end_date,'/','-'),'%m-%d-%Y')
else null
end as p_end_start,
case 
when  replace(actual_end_date,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(actual_end_date,'/','-'),'%Y-%m-%d')
when replace(actual_end_date,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(actual_end_date,
'/','-'),'%d-%m-%Y')
when replace(actual_end_date,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(actual_end_date,'/','-'),'%m-%d-%Y')
else null
end as actual_end,
case
when lower(federal_funding_pct) in ("","n/a","-","?",'tbd') then null 
else cast(federal_funding_pct as float)
end as federal_pct,
case
when lower(congressional_district) in ("","n/a","-","?",'tbd') then null 
else cast(congressional_district as signed)
end as district,
case
when lower(project_manager) in ("","n/a","-","?",'tbd') then null 
else project_manager
end as manager,
case 
when  replace(created_at,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(created_at,'/','-'),'%Y-%m-%d')
when replace(created_at,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(created_at,
'/','-'),'%d-%m-%Y')
when replace(created_at,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(created_at,'/','-'),'%m-%d-%Y')
else null
end as created_at,
case 
when  replace(last_updated,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then str_to_date(replace(last_updated,'/','-'),'%Y-%m-%d')
when replace(last_updated,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
then str_to_date(replace(last_updated,
'/','-'),'%d-%m-%Y')
when replace(last_updated,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(last_updated,'/','-'),'%m-%d-%Y')
else null
end as last_up
from projects_raw;
-- ________________________________________________
-- it was late but finally i decided to create this function  fro date conversion as we are using it often;

delimiter $$
create function convert_date(dt varchar(20))
returns date
deterministic
begin 
     return 
     case 
		when  replace(dt,'/','-') regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
		then str_to_date(replace(dt,'/','-'),'%Y-%m-%d')
		when replace(dt,'/','-') regexp '^(1[3-9]|2[0-9]|3[0-1])-[0-9]{2}-[0-9]{4}$'
		then str_to_date(replace(dt,
		'/','-'),'%d-%m-%Y')
		when replace(dt,'/','-') regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then  str_to_date( replace(dt,'/','-'),'%m-%d-%Y')
		else null
		end;
end$$
delimiter ;

-- _____________________________________________________

SELECT * FROM us_infra_funding.states_raw;
insert into states_stagging
select
state_id,
state_abbr,
state_name,
region,
case
when lower(population_2020) in ("","n/a","-","?",'tbd') then null 
else cast(population_2020 as signed)
end as population,
case
when lower(gdp_million_usd) in ("","n/a","-","?",'tbd') then null 
else cast(gdp_million_usd as signed) 
end as gdp,
case
when lower(poverty_rate_pct) in ("","n/a","-","?",'tbd') then null 
else cast(poverty_rate_pct as float)
end as povert,
case
when lower(unemployment_rate_pct) in ("","n/a","-","?",'tbd') then null 
else cast(unemployment_rate_pct as float)
end as unemployment,
case
when lower(infrastructure_grade) in ("","n/a","-","?",'tbd') then null 
else infrastructure_grade
end as grade,
case
when lower(notes) in ("","n/a","-","?",'tbd') then null 
else notes
end as notes
from states_raw;
-- ________________________________________________
SELECT * FROM us_infra_funding.timelines_raw;
insert into timelines_stagging
select 
timeline_id,
project_id,
milestone_name,
convert_date(planned_date) as date_plannned,
convert_date(actual_date) as actual_date,
case
when lower(days_delayed) in ("","n/a","-","?",'tbd') then null 
else abs(days_delayed)
end as days ,
case
when lower(delay_reason) in ("","n/a","-","?",'tbd') then null 
else delay_reason
end reason,
case
when lower(responsible_party) in ("","n/a","-","?",'tbd') then null 
else responsible_party
end party,
case
when lower(status) in ("","n/a","-","?",'tbd') then null 
else lower(status)
end as status,
case
when lower(notes) in ("","n/a","-","?",'tbd') then null 
else notes
end as notes
from timelines_raw;



