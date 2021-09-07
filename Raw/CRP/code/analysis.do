clear
set more off
log using ../output/analysis.log, replace


import delimited using ../temp/lob_bills.txt, clear
keep if v3 == "|111|"
save ../output/bills.dta, replace

import delimited using ../temp/lob_lobbying.txt, clear
keep if v15 == "|2009|" | v15 == "|2010|"
rename v1 report_id
save ../output/lobbying.dta, replace

forv i = 1/55 {
    local ii `i'
    if `i' < 10 {
        local ii "0`i'"
    }
    import delimited using ../temp/issue`ii'.txt, colrange(1:2) clear
    rename v1 issue_id
    rename v2 report_id
    drop if !regexm(issue_id, "^[0-9]+$")
    drop if !regexm(report_id, "^\|([A-Z]*[0-9]*\-)")
    recast str39 report_id
    save ../temp/issue`i'.dta, replace
    merge m:1 report_id using ../output/lobbying.dta
    keep if _merge == 3
    drop _merge
    save ../temp/master`i'.dta, replace
}

clear
forv i = 1/55 {
    append using ../temp/master`i'.dta
}
save ../output/master.dta, replace

log close

