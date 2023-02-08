// ************************************ merge-prowess-index-returns.do *************************************
// This do-file takes the stock returns data downloaded from prowess (original delimited text file).
// This do-file results in creation of returnsData.dta file
// Step 1: IMPORT:		prowesscode-returns.txt original delimited text file
// Step 2: Process:		Select NSE returns by default (BSE if unavailable)
// Step 3: Process:		Format stock date in appropriate format
// Step 4: Merge:		Merge with returnsIndicesAll.dta file (output from Step 2)
// Step 5: SAVE:		returnsData.dta
// *********************************************************************************************************


clear
import delimited "raw-data\prowesscode-returns.txt"

//Generate Returns (equals NSE Returns if available, else, BSE Returns)
destring nse_returns, replace ignore("NA")
destring bse_returns, replace ignore("NA")
gen returns=nse_returns
replace returns = bse_returns if returns == .

//Parse Date
tostring co_stkdate, replace
gen stkdate = date(co_stkdate, "YMD")
format stkdate %td

//Keep Only Relevant Values
keep co_code company_name stkdate returns

rename stkdate date
//Merge with relevant index file (here using all four indices)
merge m:1 date using "datasets\returnsIndicesAll"
keep if _merge==3
drop _merge
sort company_name date
save "datasets\returnsData", replace

// **************** Finished Merging Stock Returns with Index Returns ************************************ 
quietly translate @Results "log-files\3-merge-returns.txt", replace
cls