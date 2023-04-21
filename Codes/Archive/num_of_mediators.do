/*****************************************************************
Project: World Bank Kenya Arbiter
PIs: Anja Sautmann and Antoine Deeb
Purpose: Number of mediators used
Author: Hamza Syed 
Instruction: Change the number of cases in line 25 and run (X=5,7 or 10)
******************************************************************/
clear all
local path "/Users/hamzasyed/Dropbox/Arbiter Research/Data analysis"

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

//Keep only mediators with at least x total cases
	
	bys mediator_id: gen totalcases=_N //Total cases with relevant case types 
	keep if totalcases >= 10 //Total cases with relevant case types
	//Calculating value added
	egen med_year=group(mediator_id appt_year)
	vam case_outcome_agreement, teacher(mediator_id) year(appt_year) driftlimit(3) class(med_year) controls(i.appt_month_year i.casetype i.courttype i.courtstation i.referralmode) tfx_resid(mediator_id) data(merge tv)

	collapse tv, by(mediator_id)
	sum tv
	drop if tv == .
	count
	
	//Number of mediators in treatment and control group
	//p=20
	_pctile tv, p(20 80) 
	scalar r1=r(r1)
	scalar r2=r(r2)
	gen treatment1 = 1 if tv >= r2
	replace treatment1 = 0 if tv <= r1 
	tab treatment1,m
	//p=30
	_pctile tv, p(30 70) 
	scalar r1=r(r1)
	scalar r2=r(r2)
	gen treatment2 = 1 if tv >= r2
	replace treatment2 = 0 if tv <= r1 
	tab treatment2,m
	//p=40
	_pctile tv, p(40 60) 
	scalar r1=r(r1)
	scalar r2=r(r2)
	gen treatment3 = 1 if tv >= r2
	replace treatment3 = 0 if tv <= r1 
	tab treatment3,m
	//p=50
	_pctile tv, p(50 50) 
	scalar r1=r(r1)
	scalar r2=r(r2)
	gen treatment4 = 1 if tv >= r2
	replace treatment4 = 0 if tv <= r1 
	tab treatment4,m
	
