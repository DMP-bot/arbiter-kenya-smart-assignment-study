/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Data exploration and cleaning
Author: Hamza Syed
******************************************************************/


import delimited "/Users/hamzasyed/Documents/WB/cases_raw.csv", clear

//Date variables
gen ref_date = date(referral_date, "YMD")
format ref_date %td

gen med_appt_date = date(mediator_appointment_date, "YMD")
format med_appt_date %td

gen concl_date = date(conclusion_date, "YMD")
format concl_date %td

gen year = year(med_appt_date)
format year %ty

gen gap = ref_date - med_appt_date
tab gap
/*
40% -ve values for this gap and two values with +ve values, 60% cases with no
gap. What is referral date? Why is mediator_appointment_date missing for some
cases?
*/

tab id if missing(med_appt_date) & !missing(mediator_id)
/*7 cases with med_appt_date missing but mediators assigned
*/

//Case type
*drop if case_type == "Criminal Cases" | case_type == "Commercial Cases"
encode case_type, gen(casetype)
fre casetype
keep if inlist(casetype,1,6,9,10,11,12)

//Keep only mediators with at least 10 total cases
bys mediator_id: gen total_cases=_N
gen touse=(total_cases>=10)
keep if touse
/*
138 mediators left after dropping, 629 before dropping
Why did we decide to keep the limit at 10? We're dropping about 38% of the sample
*/

//Check if there are cases with negative number of days (ask Wei to check)
tab id if case_days < 0
/*
6412
8401
8402
*/



//Case status
tab case_status
/*
case_status |      Freq.     Percent        Cum.
------------+-----------------------------------
  CONCLUDED |      2,540       89.91       89.91
    PENDING |        285       10.09      100.00
------------+-----------------------------------
      Total |      2,825      100.00
*/

//Sort by mediator and year
sort mediator_id year

//Flags for case types
gen concluded = 1 if case_status == "CONCLUDED"

//Check outcome agreement
tab case_outcome_agreement,m
tab outcome_name, m
/* 
285 pending cases, as above. Should we exclude them?
What do non-compliance and terminated mean? Should these be counted as failure?
*/

//Check mediation session type
tab session_type,m
/*session type missing in 30% of the cases. Can we assume these as in-person?
*/

**** Residualize the outcome, note we use "predict ,dr" because we want to use mediator f.e to estimate effect of covariates but not to residualize
xi: areg case_outcome_agreement i.year i.case_type i.court_type i.court_station i.referral_mode, abs(mediator_id)
predict residuals , dr

*** Create mediator-year identifier 
egen med_year=group(mediator_id year)


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

*****get mediator-year residual variance by subtracting individual-case var and mediator-effects var.
local var_class1=`var_res' - `var_e' - `var_tfx'
local var_class=max(`var_class1', 0.0001)

**** compute shrunk VA
gen h_by_v_jt=v_jt/(`var_class' + `var_e'/n_jt )
gen h_jt= 1/(`var_class' + `var_e'/n_jt )
bysort mediator_id: egen denominator=total(h_jt)
bysort mediator_id: egen numerator=total(h_by_v_jt)
gen v_j= numerator/denominator

gen va_shrunk=v_j*(`var_tfx'/(`var_tfx'+(1/denominator)))

keep mediator_id va_shrunk
duplicates drop
sum va_shrunk


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


