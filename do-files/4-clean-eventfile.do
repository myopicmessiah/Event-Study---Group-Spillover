// ************************************ clean-eventfile.do *************************************
// This file is for cleaning Event-File to Reduce File Size For Merge with Returns File
// Starts with resolutions-processed, creates eventdates.dta
// Additionally create a file containing date-range for each event-firm (Dates of First Event & Last Event)
// Start with merger with prowess-codes file on ISIN to get company_id (uses isincodes.dta)
// *********************************************************************************************

// Importing prowess codes and isins from prowess raw data (prowesscode-isin.txt)
clear
import delimited "raw-data\prowesscode-isin.txt"
save "datasets\isincodes", replace
clear

// Create a list of unique event-firm-isin
use "datasets\resolutions-processed"
bys isin_code_equity: gen temp=_n
by isin_code_equity: keep if temp==1
keep isin_code_equity
save "datasets\event-isins", replace

// Merge with event-firm-isins to prowess-codes
merge 1:m isin_code_equity using "datasets\isincodes"
keep if _merge==3
keep isin_code_equity co_code
save "datasets\isin-procode-eventfirms", replace

// Merge with the original resolutions file
use "datasets\resolutions-processed"
merge m:1 isin_code_equity using "datasets\isin-procode-eventfirms"
keep if _merge == 3
drop _merge

// Generate voting result related variables
bys isin_code_equity meetingDate meetingTime : gen num1 = _N
gen isRPT = RESOLUTIONCATEGORY=="Related party transactions"
gen tempRPT = isRPT*(votingPassed==0)
by isin_code_equity meetingDate meetingTime: gen hadFailedRPT = sum(tempRPT)
by isin_code_equity meetingDate meetingTime: gen hadRPT = sum(isRPT)
by isin_code_equity meetingDate meetingTime: gen numPass = sum(votingPassed)
by isin_code_equity meetingDate meetingTime : gen num2 = _n
by isin_code_equity meetingDate meetingTime : keep if num1==num2

// Keep minimal variables
keep COMPANYNAME isin_meet_events meetingDate hadFailedRPT hadRPT numPass co_code
rename co_code company_id
rename meetingDate event_date
save eventdates, replace

// Create a datafile with the date of the first resolution & last resolution for each company_id
// Might be useful in case stock returns file becomes too large
keep event_date company_id
sort company_id event_date
by company_id: gen temp=_n
by company_id: keep if temp==1 | temp==_N
by company_id: gen j=_n
drop temp
reshape wide event_date, i(company_id) j(j)
save "datasets\code-beg-fin", replace

// **************** Finished Creating eventdates.dta file ************************************ 
quietly translate @Results "log-files\4-clean-eventfile.txt", replace
cls