# arbiter-kenya-smart-assignment-study
Data analysis code for Arbiter Kenya (aka Cadaster)'s smart assignment study

#### Description of the codes:
- cleaning.do: Uses the raw data and creates a cleaned dataset. It also creates the file issues.xlsx reporting issues in the data. 
- descriptive_exhibits.do: Creates tables and graphs that describe the data (cases per mediator, cases per month, cases per courtsation...)
- impact_eval_details.do (previously known as num_of_mediators_v3): Creates tables and graphs that describe several aspects of the data directly relevant to the impact evaluation i.e. number of cases eligible to be in the impact evaluation referred to court monthly, number of courtstations to be in the impact evaluation, caseload of eligible mediators in the 2022 and 2023 (for cases with characteristics to be in the impact evaluation) and number of mediators in treatment and control groups
- Antoine_va_TC.do: First calculates the value added of eligible mediators and then creates two groups, treatment and control, finally it exports a list with mediator id's, VA and their groups in va_groups.csv. 
- power_calcs.do: Reports the power calculations. It does not export any result, the results appear in the screen. 
- Codes in the Archive: Contains previous versions of the 5 codes above, and other codes not used anymore. 

#### Folder structure: 
In the same folder there should be at least these three folders:
- Data_Raw: Where raw data is saved.
- Data_Clean: Where clean data is saved.
- Ouptut: Where outputs (tables and graphs) are saved. 

#### How to run these codes:
- cleaning.do should be run first to create the cleaned dataset that other codes use. The other codes can be run after cleaning.do in any order, since they don't depend on each other. 
- Set the right "path" (location of the folder with the three subfolders mentioned above) at the beginning of each code.
- All codes can be ran using a data pull from Oct 5th 2022 or a data pull from Feb 27th Feb 2023. At the beginning of each code you can change that. 
- Some codes have instructions at the beginning of each code, follow them. 
