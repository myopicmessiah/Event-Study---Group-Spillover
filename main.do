cd "C:\Users\sharm\OneDrive - Indian Institute of Management\PhD\~RA-IS Work\Group-Spillover-Voting\V1.2"
cls
clear

local start_time = c(current_time)
display "Started at: `start_time'"

display "Begin Step 1: Processing Adrian Data, at, $S_TIME"
do "do-files\1-process-data.do"

display "Begin Step 2: Processing Index Returns Data, at, $S_TIME"
do "do-files\2-read-index-returns.do"

display "Begin Step 3: Merging Stock Data with Index Data, at, $S_TIME"
do "do-files\3-merge-prowess-index-returns.do"

display "Begin Step 4: Cleaning Event File, at, $S_TIME"
do "do-files\4-clean-eventfile.do"

display "Begin Step 5: Creating Files for Event Study, at, $S_TIME"
// Note: Edit this do file to pick which index to be used for market returns
do "do-files\5-stockdata-creator.do"

display "Begin Step 6: Start Event Study, at, $S_TIME"
// Note: Edit this do file to set the size of estimation & event windows, pass/fail metric
do "do-files\6-run-event-study.do"

display "Finished Execution!"
display "Started at: `start_time'"
display "Ended at: $S_TIME"
