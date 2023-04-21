/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Power calculation
Author: Hamza Syed (based on Antoine's file)
******************************************************************/
ssc install vam
//Defining locals 
local path "/Users/hamzasyed/Dropbox/Arbiter Research/Data analysis"
local current_date = c(current_date)
local outcome_variables = "case_days_med success conclude_70" 

//Importing data
use "`path'/Data/cases_cleaned.dta", clear

//Case status, drop pending cases
tab case_status
drop if case_status == "PENDING"

//Keeping only relevant cases
keep if usable == 1
drop if issue == 6 | issue == 7 //Dropping pandemic months

//Keep only mediators with at least 5 total cases
*keep if total_cases >= 5 //Total cases with all case types
bys mediator_id: gen totalcases=_N //Total cases with relevant case types 
keep if totalcases >=5

encode court_type, g(courttype)
egen med_year=group(mediator_id appt_year)

vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)
collapse tv, by(mediator_id)
sum tv
hist tv