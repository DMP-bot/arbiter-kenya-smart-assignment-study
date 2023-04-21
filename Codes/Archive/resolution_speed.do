/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Resolution speed analysis
Author: Hamza Syed
******************************************************************/

local path "/Users/hamzasyed/Documents/WB"
use "`path'/Data/cases_cleaned.dta", clear
local cutoff = 500
local datapull = "15102022"

//creating new case days based on mediator assignment
gen case_days_med = concl_date - med_appt_date if case_status != "PENDING"
replace case_days_med = date("`datapull'", "DMY") - med_appt_date if missing(case_days_med)

//for two cases where new case days is -ve, using old case days
replace case_days_med = case_days if case_days_med <0

//Creating month-year variable
gen month = month(dofm(med_appt_date))
format month %tm
gen month_year = ym(year,month)
format month_year %tm

//Creating a flag for pre and post rollout cases
gen cr_date = substr(created_at,1,10)
gen create_date = date(cr_date, "YMD")
format create_date %td
gen pre = 1 if med_appt_date - create_date < 0
replace pre = 0 if missing(pre)
gen create_month = month(dofm(create_date))
format create_month %tm
gen create_year = year(create_date)
format create_year %ty
gen create_my = ym(create_year,create_month)
format create_my %tm


//dropping pending cases
drop if case_status == "PENDING"

//dropping cases which were 

//average case days by court station
encode court_station, gen(courtstation)
fre courtstation

sort ref_date
bys courtstation: egen rollout = min(month_year) 
format rollout %tm

preserve
collapse (mean) mean_days=case_days_med (sd) st_dev=case_days_med (count) cases=id (first) rollout, by(courtstation)
graph twoway bar mean_days courtstation
sort mean_days
export excel using "`path'/Output/mean_days_by_courtstation.xlsx", firstrow(variables) replace
restore

*keep if year == 2019 | year == 2021
//average case days by case type
preserve
collapse (mean) mean_days=case_days_med (sd) st_dev=case_days_med (count) cases=id, by(casetype)
graph twoway bar mean_days casetype
sort mean_days
export excel using "`path'/Output/mean_days_by_casetype.xlsx", firstrow(variables) replace
restore


//average case days by referral mode
encode referral_mode, gen(referralmode)
fre referralmode

preserve
collapse (mean) mean_days=case_days_med (sd) st_dev=case_days_med (count) cases=id, by(referralmode)
graph twoway bar mean_days referralmode
sort mean_days
export excel using "`path'/Output/mean_days_by_refertype.xlsx", firstrow(variables) replace
restore


//Excluding the pandemic years
*drop if year == 2020 | year == 2021

//Setting case resolution under 200 days as success
gen resolved_soon = 1 if case_days_med <= `cutoff'
replace resolved_soon = 0 if missing(resolved_soon)

//Getting average case days for every year

preserve
collapse (mean) mean_days=case_days_med (sd) st_dev=case_days_med (count) cases=id, by(year)
graph twoway bar mean_days year
sort mean_days
export excel using "`path'/Output/mean_days_by_year.xlsx", firstrow(variables) replace
restore

//Checking if language differences are present and significant
split defendant_languages, gen(def_lang)
split plaintiff_languages, gen(plain_lang)
gen uncommon_language = 1 if def_lang1 != plain_lang1 & def_lang1 != plain_lang2 & def_lang1 != plain_lang3 & def_lang2 != plain_lang1 & def_lang2 != plain_lang2 & def_lang3 != plain_lang3 & def_lang3 != plain_lang1 & def_lang3 != plain_lang2 & def_lang3 != plain_lang3
replace uncommon_language = 0 if missing(uncommon_language)
tab uncommon_language, m


