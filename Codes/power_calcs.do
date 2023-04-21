/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Power calculation
Author: Hamza Syed 
Updated by: Didac Marti Pinto (April 2023)
Instructions: To run this code, 3 things need to be set. 
Min num of cases per mediator (line 18) - 3,4,5 or 6
Num of cases in experimental sample (line 19) - 200,300 or 400
Split of mediators in different percentiles (line 67) - 30 or 50
******************************************************************/

clear all
capture program drop exp_effect
program define exp_effect, rclass
//Defining locals 
local path "C:\Users\user\Dropbox\Arbiter Research\Data analysis"
local current_date = c(current_date)
local min_cases = 5 // Number of cases per mediator
local cases_exp = 400 //Number of cases for experimental sample

//Importing data
use "`path'/Data_Clean/cases_cleaned_pull27Feb2023", clear

//Case status, drop pending cases
tab case_status
drop if case_status == "PENDING"

//Keeping only relevant cases
keep if usable == 1
drop if issue == 6 | issue == 7 //Dropping pandemic months 

//Keeping only courtstations with >=10 cases
bys courtstation:gen stationcases = _N
drop if stationcases<10

//Generating resolution rates for each case type
tab casetype,m
bys casetype: egen res_rate = mean(case_outcome_agreement)
tab res_rate
label variable res_rate "Success rate for each casetype"

//Keep only mediators with at least 5 total cases
bys mediator_id: gen totalcases=_N //Total cases with relevant case types 
tempfile raw
save `raw'

//Drawing sample with replacement 
bsample if totalcases >= `min_cases', strata(mediator_id)

//Calculating value added
egen med_year=group(mediator_id appt_year)
vam case_outcome_agreement, teacher(mediator_id) year(appt_year) driftlimit(3) class(med_year) controls(i.appt_month_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)
sort id, stable // NEW

//Generating probability of success
gen prob_success = tv+res_rate
label variable prob_success "Probability of success"

//Saving the case level sample
tempfile sampled
save `sampled'

collapse tv prob_success, by(mediator_id)
sum tv prob_success
drop if tv == .

//Assigning mediators to treatment and control group
_pctile tv, p(30 70) //Change this for different values of p - the values are (p 100-p)
return list
scalar r1=r(r1)
scalar r2=r(r2)
gen treatment = 1 if tv >= r2
replace treatment = 0 if tv <= r1 
tab treatment,m
drop if missing(treatment)
tab treatment 
local tot_med = r(N) 
count if treatment == 1
local treated = r(N) 
count if treatment == 0 
local untreated = r(N) 
gen merge_id = _n 
tempfile mediators
save `mediators'

//Drawing random sample of experimental cases 
use `raw', clear
rename mediator_id old_mediator_id
sample `cases_exp', count 
gen rand = runiform(1,`tot_med') 
sort rand, stable
gen merge_id = mod(_n,`tot_med')+1
*tab merge_id
merge m:1 merge_id using `mediators'
sort id, stable // NEW
drop _merge
bys merge_id: gen cases_req = _N
bys merge_id: gen case_no = _n
tempfile assigned
save `assigned'

//Saving a dataset which has the number of cases the mediator will be assigned in the experiment
keep mediator_id merge_id cases_req 
duplicates drop merge_id, force
tempfile sampling_req
save `sampling_req'

//Drawing case outcome for treatment and control mediators
use `sampled', clear
merge m:1 mediator_id using `mediators'
keep if _merge == 3
sort id, stable // NEW
drop _merge
merge m:1 merge_id using `sampling_req'
sort id, stable // NEW
drop _merge
	levelsof cases_req, local(reqs)
	foreach i of local reqs {
		preserve
			keep if cases_req == `i'
				forvalues j = 1/`i' {
					bsample 1, strata(mediator_id)  
					tempfile samp_`i'_`j'
					save `samp_`i'_`j''
				}
		restore
	}
	clear
	gen a = .
	foreach i of local reqs {
		forvalues j = 1/`i' {
			append using `samp_`i'_`j''
		}
	}
	drop a
	
*bsample cases_req, strata(mediator_id)
bys mediator_id: gen case_no = _n
keep mediator_id merge_id case_no case_outcome_agreement treatment
rename case_outcome_agreement experimental_outcome

//Merging experimental outcome to experimental cases
merge 1:m mediator_id merge_id case_no using `assigned'
bys mediator_id: egen avg_success = mean(experimental_outcome)
	*correlation between avg success in experiment and probability of success for mediator
	cor avg_success prob_success
		return scalar a_p_corr = el(r(C),1,2)
	*returning the avg success in experiment and probability of success for mediators
	summ avg_success 
		return scalar avg_success = r(mean)
	summ prob_success
		return scalar prob_success = r(mean)
	*calculating the difference between avg success for treatment and control
	summ avg_success if treatment == 1
	scalar avg_upper = r(mean)
	summ avg_success if treatment == 0
	scalar avg_lower = r(mean)
		return scalar avg_success_diff = avg_upper - avg_lower
	*calculating the difference between prob of success for treatment and control mediators
	summ prob_success if treatment == 1
	scalar prob_upper = r(mean)
	summ prob_success if treatment == 0
	scalar prob_lower = r(mean)
		return scalar prob_success_diff = prob_upper - prob_lower
	*calculating the difference between value added of treatment and control mediators
	summ tv if treatment == 1
	scalar tv_upper = r(mean)
	summ tv if treatment == 0
	scalar tv_lower = r(mean)
		return scalar tv_diff = tv_upper - tv_lower
	*calculating the treatment effect and whether it is significant or not
	reghdfe experimental_outcome treatment, noabsorb nocons
		return scalar b = el(r(table),1,1)
		return scalar p = el(r(table),4,1)
end

//Running the program the first time and storing the results in different matrices
exp_effect
matrix a_p_corr = r(a_p_corr)
matrix avg_success = r(avg_success)
matrix prob_success = r(prob_success)
matrix avg_success_diff = r(avg_success_diff)
matrix prob_success_diff = r(prob_success_diff)
matrix t = r(tv_diff)
matrix b = r(b)
matrix p = r(p)

//Displaying the matrices to check that they all have values in the first run
matlist a_p_corr
matlist avg_success
matlist prob_success
matlist avg_success_diff
matlist prob_success_diff
matlist b
matlist p
matlist t

//Simulating
simulate a_p_corr = r(a_p_corr) avg_success = r(avg_success) prob_success = r(prob_success) avg_success_diff=r(avg_success_diff) prob_success_diff=r(prob_success_diff) b = r(b) p = r(p) t=r(tv_diff), reps(1000) seed(45415): exp_effect 

//Displaying the results of the simulation
bstat, stat(a_p_corr, avg_success, prob_success, avg_success_diff, prob_success_diff, p, b, t)
summ avg_success prob_success a_p_corr avg_success_diff prob_success_diff p b t
gen sig = 1 if p<0.05
replace sig = 0 if p>=0.05 & p!=.
replace sig = -99 if missing(sig)
label define signif 1 "Significant" 0 "Not significant" -99 "No result"
label values sig signif
tab sig,m
