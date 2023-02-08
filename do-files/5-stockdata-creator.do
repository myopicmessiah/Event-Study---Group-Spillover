// ************************************ stockdata-creator.do ***********************************
// This file is for creating stockdata.dta file to be used for Step 6 (Run Event Study)
// Renames column names to ensure consistency across datasets
// Selects which index returns to use for market_returns for the model
// INPUT FILE(s):	returnsData.dta
// OUTPUT FILE(s):	stockdata.dta
// *********************************************************************************************

clear
use "datasets\returnsData"
rename co_code company_id
rename retN50 market_returns
rename returns ret
// keep company_id date ret market_returns
save stockdata, replace

// **************** Finished Creating stockdata.dta file ************************************ 
quietly translate @Results "log-files\5-stockdata-creator.txt", replace
cls