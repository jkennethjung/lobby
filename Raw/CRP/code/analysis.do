clear
set more off
log using ../output/analysis.log, replace

import delimited using ../temp/lob_bills.txt, clear
keep if v3 == "|114|" | v3 == "|115|" | v3 == "|116|"
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
rename v15 year
rename v13 use 
rename v14 ind
keep if use == "|y|" 
rename v1 report_id
rename v5 client
duplicates drop report_id, force // it's like two observations
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
destring v8, replace
rename v8 exp
save ../output/master.dta, replace

gen x = 0
foreach co in HONDA HYUNDAI TESLA TOYOTA NISSAN CHRYSLER VOLKSWAGEN {
    replace x = 1 if regexm(client, "`co'")
}
replace x = 1 if regexm(client, "FORD MOTOR")
replace x = 1 if regexm(client, "GENERAL MOTORS")
replace x = 1 if regexm(client, "ALLIANCE OF AUTO")
replace x = 1 if regexm(client, "NATIONAL AUTO DEAL")
replace x = 1 if regexm(client, "ASSOCIATION OF INTL AUTO")
keep if x 
drop x
save ../output/cars.dta, replace

collapse (sum) exp, by(client bill year)
save ../output/master_client_bill_year.dta, replace

* these don't add up to CRP tabulations bc of double counting across multiple issues in a bill
collapse (sum) exp, by(client year) 
save ../output/master_client_year.dta, replace

log close

