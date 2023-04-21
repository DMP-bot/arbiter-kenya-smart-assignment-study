/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Descriptive exhibits
Author: Hamza Syed
******************************************************************/

//Defining locals 
local path "/Users/hamzasyed/Dropbox/Arbiter Research/Data analysis"
local current_date = c(current_date)

//Importing data
use "`path'/Data/cases_cleaned.dta", clear


//Number of cases per mediator with different restrictions
	*No restrictions
	preserve
	collapse (count) cases=id, by(mediator_id)
	label variable cases "Number of cases"
	summ cases
	summ cases if cases >= 10
	hist cases, graphregion(color(white)) width(1) start(0) color(edkblue) freq ytitle("Number of mediators") title("Number of cases per mediator") note("No restrictions on cases")
	graph save "`path'/Output/cases_per_mediator_raw_`current_date'", replace
	graph export "`path'/Output/cases_per_mediator_raw_`current_date'.png", as(png) replace
	forvalues i = 3/9 {
		gen more_than_`i' = 1 if cases > `i' 
	}
	collapse (sum) more_than_*
	gen data_restriction = "No restriction"
	tempfile no_restr
	save `no_restr'
	restore
	*Only family, succession and related cases
	preserve
	keep if usable == 1
	collapse (count) cases=id, by(mediator_id)
	label variable cases "Number of cases"
	summ cases
	summ cases if cases >= 10
	hist cases, graphregion(color(white)) width(1) start(0) color(edkblue) freq ytitle("Number of mediators") title("Number of cases per mediator") note("Family, succession and other related cases")
	graph save "`path'/Output/cases_per_mediator_family_`current_date'", replace
	graph export "`path'/Output/cases_per_mediator_family_`current_date'.png", as(png) replace
	forvalues i = 3/9 {
		gen more_than_`i' = 1 if cases > `i' 
	}
	collapse (sum) more_than_*
	gen data_restriction = "Only family, succession and other related cases"
	tempfile family
	save `family'
	restore
	*Excluding pandemic and recent cases
	preserve
	keep if usable == 1
	drop if issue == 6 | issue == 7
	collapse (count) cases=id, by(mediator_id)
	label variable cases "Number of cases
	summ cases
	summ cases if cases >= 10
	hist cases, graphregion(color(white)) width(1) start(0) color(edkblue) freq ytitle("Number of mediators") title("Number of cases per mediator") note("Family, succession and other related cases, excluding pandemic (Mar2020-Aug2021) and recent cases")
	graph save "`path'/Output/cases_per_mediator_family_excpand_`current_date'", replace
	graph export "`path'/Output/cases_per_mediator_family_excpand_`current_date'.png", as(png) replace
	forvalues i = 3/9 {
		gen more_than_`i' = 1 if cases > `i' 
	}
	collapse (sum) more_than_*
	gen data_restriction = "Family etc, excluding pandemic and recent"
	tempfile family_nopandemic
	save `family_nopandemic'
	restore
	*Only Jan 2019 to Feb 2020
	preserve
	keep if ref_date >= date("01012019", "DMY") & ref_date < date("01032020", "DMY")
	keep if usable == 1
	collapse (count) cases=id, by(mediator_id)
	label variable cases "Number of cases
	summ cases
	summ cases if cases >= 10
	hist cases, graphregion(color(white)) width(1) start(0) color(edkblue) freq ytitle("Number of mediators") title("Number of cases per mediator") note("Family, succession and other related cases, Jan2019 to Feb2020")
	graph save "`path'/Output/cases_per_mediator_family_2019-202002_`current_date'", replace
	graph export "`path'/Output/cases_per_mediator_family_2019-202002_`current_date'.png", as(png) replace
	restore
	*Only Jan 2021 to Feb 2022
	preserve
	keep if ref_date >= date("01012021", "DMY") & ref_date < date("01032022", "DMY")
	keep if usable == 1
	collapse (count) cases=id, by(mediator_id)
	label variable cases "Number of cases
	summ cases
	summ cases if cases >= 10
	hist cases, graphregion(color(white)) width(1) start(0) color(edkblue) freq ytitle("Number of mediators") title("Number of cases per mediator") note("Family, succession and other related cases, Jan2021 to Feb2022")
	graph save "`path'/Output/cases_per_mediator_family_2021-202202_`current_date'", replace
	graph export "`path'/Output/cases_per_mediator_family_2021-202202_`current_date'.png", as(png) replace
	forvalues i = 3/9 {
		gen more_than_`i' = 1 if cases > `i' 
	}
	collapse (sum) more_than_*
	gen data_restriction = "Family, etc. Jan 2021 to Feb 2022"
	tempfile family_2122
	save `family_2122'
	restore

	preserve
	use `no_restr', clear
	append using `family'
	append using `family_nopandemic'
	append using `family_2122'
	export excel using "`path'/Output/mediators_cases_`current_date'.xlsx", firstrow(variables) replace
	restore

//Keeping only relevant cases
keep if usable == 1

//Number of cases per month
gen case = 1
egen monthly_cases = total(case), by(ref_month_year)
drop case
twoway bar monthly_cases ref_month_year, base(0) graphregion(color(white)) xtitle("month") ytitle("number of cases") title("number of cases referred per month") xlabel(#7)
graph save "`path'/Output/number_of_cases_monthly_`current_date'", replace
graph export "`path'/Output/number_of_cases_monthly_`current_date'.png", as(png) replace

//Crosstab of courtstation and casetype
tab courtstation case_type
tab2xl court_station case_type using "`path'/Output/casetype_courtstation_`current_date'", col(1) row(1) replace

//Casetypes by year
tab ref_year case_type
tab2xl ref_year case_type using "`path'/Output/year_casetype_`current_date'", col(1) row(1) replace

//Courtstations with access to cadaster by month
preserve
collapse (first) rollout_month_year, by(courtstation)
sort rollout_month_year
gen cadaster = 1
egen monthly_cadaster = total(cadaster), by(rollout_month_year)
collapse (first) monthly_cadaster, by(rollout_month_year)
gen monthly_courts = sum(monthly_cadaster)
gen mo_diff = rollout_month_year[_n+1]-rollout_month_year
gen mo_temp = 11
gen yr_temp = 2022
gen modate_temp = ym(yr_temp, mo_temp)
replace mo_diff = modate_temp - rollout_month_year if missing(mo_diff)
expand mo_diff
drop mo_diff mo_temp yr_temp modate_temp
bys rollout_month_year: gen instance = _n
by rollout_month_year: gen date_temp = rollout_month_year[1]
gen newdate = date_temp+instance-1
format newdate %tm
drop date_temp instance rollout_month_year
rename newdate rollout_month_year
twoway bar monthly_courts rollout_month_year, base(0) graphregion(color(white)) xtitle("month") ytitle("number of court stations") title("number of court stations with access to cadaster per month") xlabel(#7)
graph save "`path'/Output/courts_with_cadaster_monthly_`current_date'", replace
graph export "`path'/Output/courts_with_cadaster_monthly_`current_date'.png", as(png) replace
drop monthly_cadaster
gen ref_month_year = rollout_month_year
tempfile courts_using_cadaster
save `courts_using_cadaster'
restore

//Courtstations using mediation per month
preserve
collapse (first) first_med_assn_month_year, by(courtstation)
sort first_med_assn_month_year
gen assignment = 1
egen monthly_assignment = total(assignment), by(first_med_assn_month_year)
collapse (first) monthly_assignment, by(first_med_assn_month_year)
gen monthly_courts_assn = sum(monthly_assignment)
gen mo_diff = first_med_assn_month_year[_n+1]-first_med_assn_month_year
gen mo_temp = 11
gen yr_temp = 2022
gen modate_temp = ym(yr_temp, mo_temp)
replace mo_diff = modate_temp - first_med_assn_month_year if missing(mo_diff)
expand mo_diff
drop mo_diff mo_temp yr_temp modate_temp
bys first_med_assn_month_year: gen instance = _n
by first_med_assn_month_year: gen date_temp = first_med_assn_month_year[1]
gen newdate = date_temp+instance-1
format newdate %tm
sort newdate
drop date_temp instance first_med_assn_month_year
rename newdate first_med_assn_month_year
twoway bar monthly_courts_assn first_med_assn_month_year, base(0) graphregion(color(white)) xtitle("month") ytitle("number of court stations") title("number of court stations using mediation per month") xlabel(#7)
graph save "`path'/Output/courts_using_mediation_`current_date'", replace
graph export "`path'/Output/courts_using_mediation_`current_date'.png", as(png) replace
restore


//Correlation between cases per month and number of courts using cadaster per month
preserve
collapse (count) cases=id, by(ref_month_year)
merge m:1 ref_month_year using `courts_using_cadaster'
replace monthly_courts = 0 if missing(monthly_courts)
drop rollout_month_year _merge
reg cases monthly_courts
restore

//Outsheeting the treatment date by courtstation and number of cases pre and post treatment
preserve
sort courtstation med_appt_date
collapse (count) cases=id (first) first_appoint=med_appt_date rollout, by(courtstation post_rollout)
reshape wide cases first_appoint rollout, i(courtstation) j(post_rollout)
rename cases0 pre_rollout_cases
rename cases1 post_rollout_cases
rename rollout0 rollout_date
replace rollout1 = rollout_date if missing(rollout1)
replace rollout_date = rollout1 if missing(rollout_date)
rename first_appoint1 first_appoint_post_rollout
drop first_appoint0 rollout1
replace pre_rollout_cases = 0 if missing(pre_rollout_cases)
replace post_rollout_cases = 0 if missing(post_rollout_cases)
gen gap_rollout_assn = first_appoint_post_rollout - rollout_date
label variable rollout_date "Rollout date of cadaster for the courtstation"
label variable pre_rollout_cases "Cases in mediation before cadaster"
label variable post_rollout_cases "Cases in mediation after cadaster"
label variable first_appoint_post_rollout "First mediator appointment date after rollout of cadaster"
label variable gap_rollout_assn "Days between rollout and first mediator appointment using cadaster"
export excel using "`path'/Output/rollout_by_courtstation_`current_date'.xlsx", firstrow(variables) replace
hist gap_rollout_assn, graphregion(color(white)) width(5) start(0) color(edkblue) freq title("Gap between rollout and first appointment post rollout") note("Bar width is 5, starting from 0")
graph save "`path'/Output/gap_rollout_assign_`current_date'", replace
graph export "`path'/Output/gap_rollout_assign_`current_date'.png", as(png) replace
restore

//Mean and standard deviation of outcomes by courtstation
preserve
collapse (mean) mean_days=case_days_med mean_success=success (sd) st_dev_days=case_days_med st_dev_success=success (count) cases=id (sum) successful=success (first) rollout, by(courtstation)
sort mean_days
order courtstation rollout cases successful mean_days st_dev_days mean_success st_dev_success 
export excel using "`path'/Output/mean_days_by_courtstation_`current_date'.xlsx", firstrow(variables) replace
restore

