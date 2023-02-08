// ************************************ read-index-returns.do *************************************
// This file reads the daily OHLC price data from NSE website to calculate the daily returnsN50
// The script creates five files: one file per index and a merged file with daily returns for all four indices
// ************************************************************************************************


//************BEGIN READING FOUR RETURNS FILES, STORED INDIVIDUAL .dta-s **************************************

clear
//NIFTY-50 Returns File
import delimited "raw-data\benchmark-50.csv"
rename date date1
gen date = date(date1, "DM20Y")
format date %td
sort date
gen retN50 = close/close[_n-1]
keep date retN50
save "datasets\returnsN50", replace

clear
//NIFTY-500 Returns File
import delimited "raw-data\benchmark-500.csv"
rename date date1
gen date = date(date1, "DM20Y")
format date %td
sort date
gen retN500 = close/close[_n-1]
keep date retN50
save "datasets\returnsN500", replace

clear
//NIFTY-500 Total Returns File
import delimited "raw-data\benchmark-500-tri.csv"
rename date date1
gen date = date(date1, "DM20Y")
format date %td
sort date
gen retN500T = totalreturnsindex/totalreturnsindex[_n-1]
keep date retN50
save "datasets\returnsN500TRI", replace

clear
//NIFTY-50 Total Returns File
import delimited "raw-data\benchmark-50-tri.csv"
rename date date1
gen date = date(date1, "DM20Y")
format date %td
sort date
gen retN50T = totalreturnsindex/totalreturnsindex[_n-1]
keep date retN50
save "datasets\returnsN50TRI", replace
//************FINISHED READING FOUR RETURNS FILES, STORED INDIVIDUAL .dta-s **************************************

//************BEGIN MERGING ALL FOUR FILES INTO ONE FILE, STORED AS .dta    **************************************
clear
use "datasets\returnsN50"

merge 1:1 date using "datasets\returnsN50TRI"
keep if _merge==3
drop _merge

merge 1:1 date using "datasets\returnsN500"
keep if _merge==3
drop _merge

merge 1:1 date using "datasets\returnsN500TRI"
keep if _merge==3
drop _merge

save "datasets\returnsIndicesAll", replace
//************FINISHED MERGING ALL FOUR FILES INTO ONE FILE, STORED AS .dta **************************************
quietly translate @Results "log-files\2-read-index-returns.txt", replace
cls