/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Power calculation
Author: Hamza Syed 
Instructions: To run this code, 3 things need to be set. 
Min num of cases per mediator (line 19) - 5,7 or 10
Num of cases in experimental sample (line 20) - 200,300 or 400
Split of mediators in different percentiles (line 62) - 20,30,40 or 50
Anja's detailed instructions are at the end of the code
******************************************************************/
clear all
capture program drop exp_effect
program define exp_effect, rclass
//Defining locals 
local path "/Users/hamzasyed/Dropbox/Arbiter Research/Data analysis"
local current_date = c(current_date)
local outcome_variables = "case_days_med success conclude_70" 
local min_cases = 5 // Number of cases per mediator
local cases_exp = 200 //Number of cases for experimental sample

//Importing data
use "`path'/Data/cases_cleaned.dta", clear

//Case status, drop pending cases
tab case_status
drop if case_status == "PENDING"

//Keeping only relevant cases
keep if usable == 1
drop if issue == 6 | issue == 7 //Dropping pandemic months

//Dropping too old cases to avoid issues in value added simulations
tab appt_year
drop if appt_year == 2016

//Keep only mediators with at least 5 total cases
*keep if total_cases >= 5 //Total cases with all case types
bys mediator_id: gen totalcases=_N //Total cases with relevant case types 
*keep if totalcases >= `min_cases'
tempfile raw
save `raw'


*use `raw', clear
//Drawing sample with replacement
bsample if totalcases >= `min_cases', strata(mediator_id)

//Calculating value added
egen med_year=group(mediator_id appt_year)
vam case_outcome_agreement, teacher(mediator_id) year(appt_year) driftlimit(3) class(med_year) controls(i.appt_month_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)

//Saving the case level sample
tempfile sampled
save `sampled'

collapse tv, by(mediator_id)
sum tv
drop if tv == .

//Assigning mediators to treatment and control group
_pctile tv, p(20 80) //Change this for different values of p - the values are (p 100-p)
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
sort rand
gen merge_id = mod(_n,`tot_med')+1
*tab merge_id
merge m:1 merge_id using `mediators'
drop _merge
tempfile assigned
save `assigned'

//Drawing case outcome for treatment and control mediators
use `sampled', clear
merge m:1 mediator_id using `mediators'
keep if _merge == 3
drop _merge
bsample 1, strata(mediator_id)
keep mediator_id case_outcome_agreement treatment
rename case_outcome_agreement experimental_outcome

//Merging experimental outcome to experimental cases
merge 1:m mediator_id using `assigned'
summ tv if treatment == 1
scalar tv_upper = r(mean)
summ tv if treatment == 0
scalar tv_lower = r(mean)
return scalar tv_diff = tv_upper - tv_lower
reghdfe experimental_outcome treatment, noabsorb nocons
return scalar b = el(r(table),1,1)
return scalar p = el(r(table),4,1)

*mat list r(table)

end

exp_effect
matrix t = r(tv_diff)
matrix b = r(b)
matrix p = r(p)


matlist b
matlist p
matlist t

//Simulating
simulate b = r(b) p = r(p) t=r(tv_diff), reps(1000) seed(45415): exp_effect 
bstat, stat(t, b, p)
gen sig = 1 if p<0.05
replace sig = 0 if p>=0.05 & p!=.
replace sig = -99 if missing(sig)
label define signif 1 "Significant" 0 "Not significant" -99 "No result"
label values sig signif
tab sig,m
summ p b t

/* Anja's instructions
Here's the steps we need:

Bootstrap the "sample split" based on value added:
	We want to draw a set of mediators from the total sample (e.g. all M(T) mediators with E(xperience)>=T, where T is the inclusion threshold, say 7 cases) with replacement. So we draw a new sample of size M, and then, for each of these mediators, draw E case outcomes with replacement from their case results. Now you have a new sample that "looks like" the original sample of M mediators with E>=T.
	Based on this new sample, estimate the mediator's value added, and then create a treatment group T and a control group C. These should consist of the top and bottom percentile p of mediators, 20%<=p<=50%, by mediator value added. There are now K=p/2*M(T) mediators in each the treatment and control group.

Bootstrap the experimental outcomes in T and C:
	Next, we want to simulate the experiment, which will consist of drawing N new cases and "randomly assigning them" to the mediators in the treatment and control. We do this by drawing N/2 mediators without replacement from T and C (assuming K>N/2, otherwise we "assign" one case to each mediator and then assign the N/2-K remaining cases by drawing mediators without replacement).
	Then, from the selected mediators, we draw one case outcome WITH replacement from their original sample of cases. This is the sample of experimental case outcomes. It should be different from the sample of cases above. Then we use the experimental case outcomes sample and estimate the same model as above but without the mediator fixed effect, just a dummy for treatment group T and the constant. The object of interest is the coefficient on this dummy.

Get the proportion of significant dummy coefficients by repeating the steps above many times for given T, p, and N.

The second drawing step is needed because we do not want to use the cases we used to split the sample to estimate group outcome. Rather, we want to simulate outcomes in new cases assigned to these mediators, taking into account that we may have misclassified them.

Last, I'd like the proportion of significant coefficients (i.e. p-value below 5%, say) for combinations of T, p, and N. Let's start with just one T to make sure it works, and let's try p= 20%, 30%, 40%, 50%, and N =200, 300, and 400 (or some subset of these if this takes too long). If you prefer you can also do this for only one draw of p and N so we can see what it looks like.
