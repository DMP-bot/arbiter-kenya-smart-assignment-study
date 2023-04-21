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
keep if totalcases >= 10


	//Calculating value added
	preserve
	egen med_year=group(mediator_id appt_year)
	*vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)
	vam case_outcome_agreement, teacher(mediator_id) year(appt_year) class(med_year) controls(i.appt_month_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)

	collapse tv, by(mediator_id)
	sum tv
*	hist tv, graphregion(color(white)) color(edkblue) title("Distribution of value added (mediators with >=5 cases)") note("No time fixed effects") 
*graph export "`path'/Output/VA_notimeFE_`current_date'.png", as(png) replace

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
			
			simulate size = r(size), reps(1000) seed(9866): samp_size
			
			bstat, stat(size)
*bootstrap r(samsize), reps(1000) seed(9865): power_calc
*matrix list e(b)
**** with my data extract this was returning 289




/*
**** Residualize the outcome, note we use "predict ,dr" because we want to use mediator f.e to estimate effect of covariates but not to residualize
xi: areg case_outcome_agreement i.appt_year i.case_type i.court_type i.court_station i.referral_mode, abs(mediator_id)
*xi: areg case_outcome_agreement i.case_type i.court_type i.court_station i.referral_mode, abs(mediator_id)
predict residuals , dr

*** Create mediator-year identifier 
egen med_year=group(mediator_id appt_year)


**** Get total residual variance
sum residuals
local var_res=r(sd)^2

**** Get individual-case residual variance
areg residuals, a(med_year)
predict abc,resid
sum abc
local var_e=r(sd)^2



***** get mediator-year residual 
sort med_year, stable
bysort  med_year: egen v_jt=mean(residuals)
***** get number of cases for each mediator-year
bysort  med_year: gen n_jt=_N
**** Keep one observation per mediator-year
duplicates drop med_year, force

****get variance of mediator-effects by taking covariance between years
bysort  mediator_id (med_year): gen num=_n
tsset  mediator_id num 
corr  v_jt  L.v_jt , cov 
local var_tfx1 = `r(cov_12)' 
local var_tfx=max(`var_tfx1', 0.0001)
di `var_tfx'
*****get mediator-year residual variance by subtracting individual-case var and mediator-effects var.
local var_class1=`var_res' - `var_e' - `var_tfx'
local var_class=max(`var_class1', 0.0001)

**** compute shrunk VA
gen h_by_v_jt=v_jt/(`var_class' + `var_e'/n_jt )
gen h_jt= 1/(`var_class' + `var_e'/n_jt )
bysort mediator_id: egen denominator=total(h_jt)
bysort mediator_id: egen numerator=total(h_by_v_jt)
gen v_j= numerator/denominator
*hist v_j, graphregion(color(white)) color(edkblue) title("Distribution of value added (mediators with >=5 cases)") note("Family, succession and related cases, excluding pandemic and recent")
*graph export "`path'/Output/VA_unshrunk_all_`current_date'.png", as(png) replace
*graph export "`path'/Output/VA_unshrunk_excludingpandemic_`current_date'.png", as(png) replace
gen va_shrunk=v_j*(`var_tfx'/(`var_tfx'+(1/denominator)))

keep mediator_id va_shrunk
duplicates drop
sum va_shrunk
*hist va_shrunk, graphregion(color(white)) color(edkblue) title("Distribution of value added (mediators with >=10 cases)") note("Family, succession and related cases")
*graph save "`path'/Output/VA_excludingpandemic_2_`current_date'", replace
*graph export "`path'/Output/VA_excludingpandemic_2_`current_date'.png", as(png) replace
*graph save "`path'/Output/VA_family_all_2_`current_date'", replace
*graph export "`path'/Output/VA_family_all_2_`current_date'.png", as(png) replace


***** Power Calcs


_pctile va_shrunk, p(33 66)
return list
scalar r1=r(r1)
scalar r2=r(r2)
*** Get average VA for lower tercile
sum va_shrunk if va_shrunk<r1
scalar low=r(mean)
**** Get average VA for upper tercile
sum va_shrunk if va_shrunk>r2
scalar high=r(mean)

*** Get expected effect of replacing mediator in lower tercile by mediator in upper tercile.
scalar expected_effect=high-low
di expected_effect
***** Convert to % of outcome SD (average of binary outcome is 0.5 so SD 0.5)
scalar mde=expected_effect/0.5

di mde

***** Power Calc Formula
scalar samp_size=[4*0.5^2*(1.96+0.84)^2]/mde^2
di samp_size

**** with my data extract this was returning 289
