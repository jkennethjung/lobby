clear
set more off
log using ../output/analysis.log, replace

import delimited using ../temp/lob_bills.txt, clear
keep if v3 == "|111|"
rename v1 bill
rename v2 gid 
rename v3 congress
keep bill gid congress
duplicates drop bill gid, force
desc
* there are many issues (if that's indeed what they are!) per bill.
* i will only keep one per bill for now
save ../output/bills.dta, replace

import delimited using ../temp/lob_lobbying.txt, clear
keep if v15 == "|2009|" | v15 == "|2010|"
rename v15 year
rename v1 report_id
rename v5 client
save ../output/lobbying.dta, replace

import delimited using ../temp/lob_issue_NoSpecficIssue.txt, clear
desc
rename v1 gid
rename v2 report_id
drop if !regexm(report_id, "^\|([A-Z]*[0-9]*\-)")
*keep if year == "|2009|" | year == "|2010|"
recast str39 report_id
merge m:1 report_id using ../output/lobbying.dta
keep if _merge == 3
drop _merge
save ../temp/master_nsi.dta, replace

forv i = 1/55 {
    local ii `i'
    if `i' < 10 {
        local ii "0`i'"
    }
    import delimited using ../temp/issue`ii'.txt, colrange(1:2) clear
    rename v1 gid
    rename v2 report_id
    desc
    drop if !regexm(gid, "^[0-9]+$")
    *drop if !regexm(report_id, "^\|([A-Z]*[0-9]*\-)")
    *keep if year == "|2009|" | year == "|2010|"
    recast str39 report_id, force
    save ../temp/issue`i'.dta, replace
    merge m:1 report_id using ../output/lobbying.dta
    keep if _merge == 3
    drop _merge
    destring gid, replace
    save ../temp/master`i'.dta, replace
}

clear
forv i = 1/55 {
    append using ../temp/master`i'.dta
}
append using ../temp/master_nsi.dta

desc
tab year
* or dup drop gid, force ? 
duplicates drop gid year, force
merge 1:m gid using ../output/bills.dta
keep if _merge == 3
drop _merge
save ../output/master.dta, replace

destring v8, replace
rename v8 exp
collapse (sum) exp, by(client year) 
save ../output/master_client_year.dta, replace

log close

