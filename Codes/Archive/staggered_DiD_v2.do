/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Resolution speed analysis - Diff-in-Diff
Author: Hamza Syed
******************************************************************/

//Defining locals 
local path "C:\Users\user\Dropbox\Arbiter Research\Data analysis\"
local current_date = c(current_date)
local outcome_variables = "case_days_med success conclude_70" 
*ssc install csdid
*ssc install drdid

//Importing data
use "`path'/Data/cases_cleaned_pull27Feb2023.dta", clear

//Keeping only relevant cases
keep if usable == 1

//dropping pending cases
drop if case_status == "PENDING"

	keep if usable == 1
	drop if issue == 6 | issue == 7
tab post_rollout
summ case_days_med if post_rollout == 1

//Staggered DiD
foreach i in `outcome_variables' {
	*courtstation, casetype and month FE
	reghdfe `i' post_rollout, absorb(courtstation casetype ref_month_year) nocons
	outreg2 using "`path'/Output/`i'_did", excel replace addtext(Courtstation FE, YES, Casetype FE, YES, Month FE, YES)
	*courtstation and month FE
	reghdfe `i' post_rollout, absorb(courtstation ref_month_year) nocons
	outreg2 using "`path'/Output/`i'_did", excel addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
	*month FE
	reghdfe `i' post_rollout, absorb(ref_month_year) nocons
	outreg2 using "`path'/Output/`i'_did", excel addtext(Courtstation FE, NO, Casetype FE, NO, Month FE, YES)
	*All FE but data excluding pandemic and 300 days before data pull
	preserve
	keep if usable == 1
	drop if issue == 6 | issue == 7
	reghdfe `i' post_rollout, absorb(courtstation casetype ref_month_year) nocons
	outreg2 using "`path'/Output/`i'_did", excel addtext(Courtstation FE, YES, Casetype FE, YES, Month FE, YES)
	restore
	*All FE but data restricted to Jan 2021 to Feb 2022
	preserve
	keep if ref_date >= date("01012021", "DMY") & ref_date < date("01032022", "DMY")
	keep if usable == 1
	reghdfe `i' post_rollout, absorb(courtstation casetype ref_month_year) nocons
	outreg2 using "`path'/Output/`i'_did", excel addtext(Courtstation FE, YES, Casetype FE, YES, Month FE, YES)
	restore
}

/*
preserve
keep if casetype == 1
reghdfe case_days_med post_rollout, absorb(courtstation ref_month_year) nocons
outreg2 using "`path'/Output/child_custody_sucession_did", excel replace addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
reghdfe success post_rollout, absorb(courtstation ref_month_year) nocons
outreg2 using "`path'/Output/child_custody_sucession_did", excel addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
reghdfe conclude_70 post_rollout, absorb(courtstation ref_month_year) nocons
outreg2 using "`path'/Output/child_custody_sucession_did", excel addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
restore
preserve
keep if casetype == 12
reghdfe case_days_med post_rollout, absorb(courtstation ref_month_year) nocons
outreg2 using "`path'/Output/child_custody_sucession_did", excel addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
reghdfe success post_rollout, absorb(courtstation ref_month_year) nocons
outreg2 using "`path'/Output/child_custody_sucession_did", excel addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
reghdfe conclude_70 post_rollout, absorb(courtstation ref_month_year) nocons
outreg2 using "`path'/Output/child_custody_sucession_did", excel addtext(Courtstation FE, YES, Casetype FE, NO, Month FE, YES)
restore
