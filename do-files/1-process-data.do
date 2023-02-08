// ************************************ process-data.do *************************************
// This do-file takes the Adrian-IIAS data from the provided excel file and cleans the dataset
// This do-file results in creation of 3 stata datasets (.dta files) and 2 logs (.txt file) summarizing the data
// Step 1: IMPORT:			Excel Sheet (named adrian-iias.xlsx, Sheet1)
// Step 2: Process Data:	Rename Columns to Consistent Names, Drop Redundant Columns
// Step 3: SAVE DATA:		"resolutions-withvoting"
// Step 4: LOG:				Print summary of Meeting Type, Resolution Category, Proxy View, Outcome to "summary_start.txt"
// Step 5: Process Data:	Translate Meeting Type & Proxy View Variable to Integers 
// Step 5: Process Data:	Keep only resolutions with a Pass/Fail Result. Store as dummy variable: "votingPassed"
// Step 6: LOG:				Print summary of Meeting Type, Resolution Category, Proxy View, Outcome to "summary_start.txt"
// Step 7: Process Data:	Generate Number of Events by Firm and By Meeting (Firm + Meeting Date)
// Step 7: Process Data:	Parse DATEOFMEETING to store in two columns: "meetingDate", "meetingTime"
// Step 8: SAVE DATA: 		"resolutions-processed"
// ******************************************************************************************

// Note: Assumes that the excel file (named "adrian-iias.xlsx") is located inside raw-data folder.

clear

// IMPORT SHEET1, DROP REDUNDANT COLUMNS, RENAME COLUMNS TO CONSISTENT NAMES
// NOTE: The imported data is CAPITALIZED so as to match with data provided by PROWESS (which stores firm names in capital letters)
// NOTE: Dropping Votes Against, Percentage Votes (which can be calculated from the columns that are retained)
// NOTE: Dropping the Descriptions for the Resolution and IIAS Rationale as textual analyis is not performed
import excel "raw-data\adrian-iias.xlsx", sheet("Sheet1") cellrange(A2:AH57740) firstrow case(upper)
drop RESOLUTIONDESCRIPTION IIASRATIONALE PROMOTERVOTESAGAINST O P Q INSTITUTIONALVOTESAGAINST V W X OTHERSVOTESAGAINST AC AD AE TOTALVOTESAGAINST
format %17.0g PROMOTERNUMSHARES PROMOTERVOTESPOLLED PROMOTERVOTESINFAVOUR INSTITUTIONALNUMSHARES INSTITUTIONALVOTESPOLLED INSTITUTIONALVOTESINFAVOUR OTHERSNUMSHARES OTHERSVOTESPOLLED OTHERSVOTESINFAVOUR TOTALVOTESPOLLED TOTALVOTESINFAVOUR

rename PROMOTERNUMSHARES HOLDINGPROMOTER
rename PROMOTERVOTESPOLLED POLLEDPROMOTER
rename PROMOTERVOTESINFAVOUR INFAVORPROMOTER
rename INSTITUTIONALNUMSHARES HOLDINGINST
rename INSTITUTIONALVOTESPOLLED POLLEDINST
rename INSTITUTIONALVOTESINFAVOUR INFAVORINST
rename OTHERSNUMSHARES HOLDINGOTHER
rename OTHERSVOTESPOLLED POLLEDOTHERS
rename OTHERSVOTESINFAVOUR INFAVOROTHERS
rename TOTALVOTESPOLLED POLLEDTOTAL
rename TOTALVOTESINFAVOUR INFAVORTOTAL

save "datasets\resolutions-withvoting", replace

keep ISIN COMPANYNAME DATEOFMEETING MEETINGTYPE RESOLUTIONCATEGORY IIASVIEW OVERALLVOTINGOUTCOME
save "datasets\resolutions-basic", replace

clear

// ******************************************************************************************
// STEP 3
// ******************************************************************************************
use "datasets\resolutions-basic"
rename ISIN isin_code_equity

//Print Summary of Meetings and Outcomes to text file
tab MEETINGTYPE
tab RESOLUTIONCATEGORY
tab IIASVIEW
tab OVERALLVOTINGOUTCOME

//Translate Meeting Type Variables to Integers
quietly
{
	gen meetType = .
	replace meetType = 1 if MEETINGTYPE== "AGM"
	replace meetType = 2 if MEETINGTYPE== "POSTAL BALLOT"
	replace meetType = 3 if MEETINGTYPE== "EGM"
	replace meetType = 4 if MEETINGTYPE== "CCM"
	replace meetType = 5 if MEETINGTYPE== "NCM"
	replace meetType = 6 if MEETINGTYPE== "MCA"
	replace meetType = 7 if MEETINGTYPE== "MCA Convened"
}

//Translate IIAS Recommendations to Numeric Values from Text
quietly
{
	gen proxyView = .
	replace proxyView = 0 if IIASVIEW== "FOR"
	replace proxyView = 1 if IIASVIEW== "AGAINST"
	replace proxyView = 2 if IIASVIEW== "ABSTAIN"
	replace proxyView = 4 if IIASVIEW== "WITHDRAWN"
	replace proxyView = 3 if proxyView == .
}

//Keep only the resolutions that passed or failed (Remove ones that were withdrawn or have results unavailable)
quietly
{
	keep if OVERALLVOTINGOUTCOME=="PASSED"||OVERALLVOTINGOUTCOME=="REJECTED"
	gen votingPassed=OVERALLVOTINGOUTCOME=="PASSED"
}

tab meetType
tab proxyView
tab votingPassed
tab RESOLUTIONCATEGORY

//Print Summary of Processed Data to text file
quietly translate @Results "log-files\1.0-summary_processed.txt", replace

cls

// ******************************************************************************************
// STEP 7
// ******************************************************************************************
// Generate number of events (per firm and per meeting)
sort isin_code_equity DATEOFMEETING

by isin_code_equity DATEOFMEETING: gen isin_meet_events=_N
by isin_code_equity: gen isin_events=_N

// Store number of events as Integers
recast int meetType
recast int proxyView
recast int votingPassed
recast int isin_meet_events
recast int isin_events

// Drop Unnecessary Columns
keep isin_code_equity COMPANYNAME DATEOFMEETING RESOLUTIONCATEGORY meetType proxyView votingPassed isin_meet_events isin_events

// Store the Date and Time of Meeting in Separate formatted columns
split DATEOFMEETING
gen meetingDate = date(DATEOFMEETING1, "YMD")
format meetingDate %td

gen meetingTime = clock(DATEOFMEETING2, "hms")
format meetingTime %tc

label variable meetType "Type of Meeting "
label variable proxyView "Recommendation of Proxy Advisor"
label variable votingPassed "Voting Result - didPass?"
label variable isin_meet_events "Number of Events per ISIN per Meeting"
label variable isin_events "Number of Events per ISIN"
label variable meetingDate "Date of the Meeting"
label variable meetingTime "Time of the Meeting"

drop DATEOFMEETING DATEOFMEETING1 DATEOFMEETING2

// Save the dataset
save "datasets\resolutions-processed", replace
quietly translate @Results "log-files\1.1-resolutions-processed.txt", replace
cls