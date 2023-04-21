/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Power calculation
Author: Hamza Syed (based on Antoine's file)
******************************************************************/
clear all

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
keep if totalcases >= 5


	//Calculating value added
	preserve
	egen med_year=group(mediator_id appt_year)
	*vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)
	vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_month_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)
	*vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)

	collapse tv, by(mediator_id)
	sum tv
	*hist tv, graphregion(color(white)) color(edkblue) title("Distribution of value added (mediators with >=10 cases)") note("No time fixed effects, among others") 
*graph export "`path'/Output/VA_notimeFE_10_`current_date'.png", as(png) replace

	***** Power Calcs


	_pctile tv, p(33 66)
	return list
	scalar r1=r(r1)
	scalar r2=r(r2)
	*** Get average VA for lower tercile
	sum tv if tv<r1
	scalar low=r(mean)
	**** Get average VA for upper tercile
	sum tv if tv>r2
	scalar high=r(mean)

	*** Get expected effect of replacing mediator in lower tercile by mediator in upper tercile.
	scalar expected_effect=high-low
	di expected_effect
	***** Convert to % of outcome SD (average of binary outcome is 0.5 so SD 0.5)
	scalar mde=expected_effect/0.5

	di mde

	***** Power Calc Formula
	scalar samp_size=[4*0.5^2*(1.96+0.84)^2]/mde^2
	gen samsize = samp_size
	summ samsize
	return list

	matrix size = r(mean)
	restore
	matrix list size

		capture program drop samp_size
		program define samp_size, rclass
			preserve
				bsample
					
					egen med_year=group(mediator_id appt_year)
	*vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)
					vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_month_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)

					collapse tv, by(mediator_id)
					sum tv
					*hist tv

					***** Power Calcs


					_pctile tv, p(33 66)
					return list
					scalar r1=r(r1)
					scalar r2=r(r2)
					*** Get average VA for lower tercile
					sum tv if tv<r1
					scalar low=r(mean)
					**** Get average VA for upper tercile
					sum tv if tv>r2
					scalar high=r(mean)

					*** Get expected effect of replacing mediator in lower tercile by mediator in upper tercile.
					scalar expected_effect=high-low
					di expected_effect
					***** Convert to % of outcome SD (average of binary outcome is 0.5 so SD 0.5)
					scalar mde=expected_effect/0.5

					di mde

					***** Power Calc Formula
					scalar samp_size=[4*0.5^2*(1.96+0.84)^2]/mde^2
					gen samsize = samp_size
					summ samsize
					return list
					
					return scalar size = r(mean)
				restore
			end
			
			simulate size = r(size), reps(1000) seed(9867): samp_size //For mediators with >= 5 cases
*			simulate size = r(size), reps(1000) seed(9855): samp_size //For mediators with >= 7 cases
*			simulate size = r(size), reps(1000) seed(4959): samp_size //For mediators with >= 10 cases
			
			bstat, stat(size)
*bootstrap r(samsize), reps(1000) seed(9865): power_calc
*matrix list e(b)
