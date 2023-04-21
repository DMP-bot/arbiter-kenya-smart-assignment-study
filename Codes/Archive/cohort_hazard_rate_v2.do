/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Hazard rate - including pending accounts and excluding cases with > 365 days
Author: Hamza Syed
******************************************************************/

local path "/Users/hamzasyed/Documents/WB"
use "`path'/Data/cases_cleaned.dta", clear

//creating new case days based on mediator assignment
gen case_days_med = concl_date - med_appt_date if case_status != "PENDING"
replace case_days_med = date("15102022", "DMY") - med_appt_date if missing(case_days_med)

//for two cases where new case days is -ve, using old case days
replace case_days_med = case_days if case_days_med <0

//capping case days at 365
drop if case_days_med > 365

//Preparing data for hazard analysis
*gen tot_closed = 0
sort year case_days_med
bys year: gen cum = _N
sort year case_days_med
bys year: gen closed = 1 if case_status != "PENDING"
replace closed = 0 if missing(closed)
bys year: gen tot_closed = sum(closed)
sort year case_days_med
gen open = cum - tot_closed
gen prop_open = open/cum

*graph twoway line prop_open case_days_med if year == 2016
//Graph for proportion of open cases by case_days
sort year case_days_med prop_open
bytwoway line prop_open case_days_med, by(year) bgcolor(white) xtitle("case days") ytitle("proportion of open cases for the year") note("Note: closed cases here mean either with agreement or without; cases with >365 days dropped") legend(rows(2)) 
graph save "`path'/Output/cohort_wise_survival_with_pending", replace
graph export "`path'/Output/cohort_wise_survival_with_pending.png", as(png) replace

//Hazard analysis
stset case_days_med, fail(open)
sts list, by(year) cumhaz
sts graph, by(year) cumhaz legend(rows(3)) bgcolor(white) note("Note: closed cases here mean either with agreement or without; cases with >365 days dropped")
graph save "`path'/Output/cohort_wise_hazard_with_pending", replace
graph export "`path'/Output/cohort_wise_hazard_with_pending.png", as(png) replace
