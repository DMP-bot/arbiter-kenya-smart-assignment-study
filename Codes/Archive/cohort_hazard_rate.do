/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Hazard rate - excluding pending accounts
Author: Hamza Syed
******************************************************************/

local path "/Users/hamzasyed/Documents/WB"
use "`path'/Data/cases_cleaned.dta", clear

//Dropping pending accounts 
drop if case_status == "PENDING"

//capping case days at 800
replace case_days = 800 if case_days > 800

//Preparing data for hazard analysis
sort year case_days
bys year: gen cum = _N
sort year case_days
bys year: gen closed = _n
gen open = cum - closed
gen prop_open = open/cum

//Graph for proportion of open cases by case_days
sort year case_days prop_open
bytwoway line prop_open case_days, by(year) bgcolor(white) xtitle("case days") ytitle("proportion of open cases for the year") note("Note: closed cases here mean either with agreement or without; case days capped at 800") legend(rows(2)) 
graph save "`path'/Output/cohort_wise_survival", replace
graph export "`path'/Output/cohort_wise_survival.png", as(png) replace

//Hazard analysis
stset case_days, fail(open)
sts list, by(year) cumhaz
sts graph, by(year) cumhaz legend(rows(3)) bgcolor(white) note("Note: closed cases here mean either with agreement or without; case days capped at 800")
graph save "`path'/Output/cohort_wise_hazard", replace
graph export "`path'/Output/cohort_wise_hazard.png", as(png) replace
