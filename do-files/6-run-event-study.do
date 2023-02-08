// ************************************ run-event-study.do *************************************
// Final Step: Conducts The Event Study
// NOTE:	Set the Length of Estimation Window & Even Window in this File
// NOTE:	Set the Metric for Meeting Success/Failure in this File
// INPUT FILE(s):	eventdates.dta and stockdata.dta
//	eventdates -> 	company_id, event_date. (Optional: num-events, num-pass, had-RPT, had-failed-RPT) 
//	stockdata -> 	company_id, return date, returns, market_returns
// OUTPUT FILE(s):	eventcount.dta, eventdates2.dta, stockdata2.dta (temp files)
// *********************************************************************************************

local ev_begin = -4
local ev_end = 4
local est_begin = -90
local est_end = -31
local ev_count = `ev_end' - `ev_begin' + 1
local est_count = `est_end' - `est_begin' + 1

//find out how many event dates there are for each company
//generate a variable that counts the number of event dates per company
use eventdates, clear
bys company_id: gen eventcount=_N

//Cut the dataset down to just one observation for each company
by company_id: keep if _n==1
sort company_id
keep company_id eventcount 
save eventcount, replace

//Merge the new 'eventcount' dataset with your dataset of stock data
use stockdata, clear
sort company_id
merge company_id using eventcount
tab _merge
keep if _merge==3
drop _merge
expand eventcount

//Create a variable that indicates which 'set' of observations within the company each observation belongs to
drop eventcount
sort company_id date
by company_id date: gen set=_n
sort company_id set
save stockdata2, replace

use eventdates, clear
bys company_id: gen set=_n
sort company_id set
save eventdates2, replace
use stockdata2, clear
merge company_id set using eventdates2
tab _merge	

list company_id if _merge==2 
keep if _merge==3
drop _merge

egen group_id = group(company_id set)	

//Calculating number of trading days
sort group_id date
by group_id: gen datenum=_n
by group_id: gen target=datenum if date==event_date
egen td=min(target), by(group_id)
drop target
gen dif=datenum-td

//Event window and estimation window
by group_id: gen event_window=1 if dif>=`ev_begin' & dif<=`ev_end'
egen count_event_obs=count(event_window), by(group_id)
by group_id: gen estimation_window=1 if dif>=`est_begin' & dif<=`est_end'
egen count_est_obs=count(estimation_window), by(group_id)
replace event_window=0 if event_window==.
replace estimation_window=0 if estimation_window==.

//Produce a list of company_ids that do not have enough observations within the event and estimation windows
// tab group_id if count_event_obs<`ev_count'
// tab group_id if count_est_obs<`est_count'

//Eliminating these companies
drop if count_event_obs < `ev_count'
drop if count_est_obs < `est_count'
keep if event_window==1 | estimation_window==1

// Note: Definition of Pass Fail? 
// Case 1: A Single Failed Resolution implies Event Fail
// Case 2: 33% Failed Resolutions imply Event Fail
gen pass_score = isin_meet_events==numPass
//------> gen pass_score = numPass/isin_meet_events>2/3
//Estimating Normal Performance
set more off /* this command just keeps stata from pausing after each screen of output */

gen predicted_return=.
egen id=group(group_id) 
 /* for multiple event dates, use: egen id = group(group_id) */

save stockdata2, replace 
 
sum id 
local loopmax = r(max)
display `loopmax'

// Note: Replace market_return with retN50T or retN500 or retN500T
display "Begin Estimation/Prediction: $S_TIME"
forvalues i=1 (1) `loopmax' { /*note: replace N with the highest value of id */ 
	if(mod(`i',500)==1) display "Processed `i': $S_TIME"
// 	l id group_id if id==`i' & dif==0		// l is short for list command
// 	quietly reg ret market_return if id==`i' & estimation_window==1 
// 	quietly reg ret retN50T if id==`i' & estimation_window==1 
	quietly reg ret retN500 if id==`i' & estimation_window==1 
// 	quietly reg ret retN500T if id==`i' & estimation_window==1 
// 	quietly predict p if id==`i'
	quietly predict p if id==`i' & event_window==1
	quietly replace predicted_return = p if id==`i' & event_window==1 
	drop p	
}
display "End Estimation/Prediction: $S_TIME"

//Calculate the abnormal and cumulative abnormal returns for our data
sort id date
gen abnormal_return=ret-predicted_return if event_window==1
by id: egen cumulative_abnormal_return = sum(abnormal_return) 

//Compute a test statistic, test, to check whether the average abnormal return for each stock is statistically different from zero
sort id date
by id: egen ar_sd = sd(abnormal_return) 
gen test =(1/sqrt(5)) * ( cumulative_abnormal_return /ar_sd) 
// list group_id cumulative_abnormal_return test if dif==0

//Calculate the cumulative abnormal for all companies treated as a group
reg cumulative_abnormal_return if dif==0, robust
reg cumulative_abnormal_return pass_score if dif==0, robust

reg cumulative_abnormal_return if dif==0 & pass_score==0, robust
reg cumulative_abnormal_return if dif==0 & pass_score==1, robust


save stockdata3, replace 
quietly translate @Results "log-files\6-eventstudy.txt", replace
cls