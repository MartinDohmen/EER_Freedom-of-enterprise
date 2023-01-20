clear all
set more off


use "${hp}\intermediate_stata_data\full_dataset_Prussia_Hessen_Kassel", clear

merge 1:1 kreiskey1800 using "${hp}\data_input\data_geocoding_results\dataset_Prussia_Hessen_Kassel_lat_long", nogen

drop if state=="NAS"
drop if state=="DAR"
drop if rb=="KOB"
drop if rb=="AAC"
drop if rb=="KOL"
drop if rb=="TRI"
drop if rb=="DUS"
drop if rb=="LIE"
drop if rb=="OPP"
drop if rb=="BRE"
drop if rb=="STR"
drop if rb=="KOS"
drop if rb=="STE"
drop if rb=="FRA"
drop if rb=="POT"
drop if rb=="POS"
drop if rb=="BER"
drop if rb=="BRO"
drop if rb=="KON"
drop if rb=="MAR"
drop if rb=="DAN"
drop if rb=="GUM"


generate Gewerbefreiheit = 0
replace Gewerbefreiheit = 1 if state=="PRU"
rename Westphalen westphalen

* Calculate Growthrates in percentage points
generate growthrate_37_49 = (pop1849_tot - pop1837_tot)/pop1837_tot *100
generate growthrate_37_64 = (pop1864_tot - pop1837_tot)/pop1837_tot *100
generate growthrate_49_64 = (pop1864_tot - pop1849_tot)/pop1849_tot *100
generate growthrate_64_77 = (pop1877_tot - pop1864_tot)/pop1864_tot *100
generate growthrate_37_77 = (pop1877_tot - pop1837_tot)/pop1837_tot *100

* Calculate necessary population densities 
generate pop_density_37 = pop1837_tot/area_in_km2
generate pop_density_49 = pop1849_tot/area_in_km2
generate pop_density_64 = pop1864_tot/area_in_km2
generate pop_density_77 = pop1877_tot/area_in_km2

* Label population density for esttab
label var pop_density_37 "Pop. density 1837"
label var pop_density_49 "Pop. density 1849"
label var pop_density_64 "Pop. density 1864"
label var pop_density_77 "Pop. density 1877"

* Label control variables for esttab
label var share_protestant "Share Protestants"
label var literacy_rate "Literacy rate"
label var share_working_mining "Share working mining"
label var fortification "Fortification"

* Put share control variables in %
replace share_protestant = share_protestant * 100
replace literacy_rate = literacy_rate * 100
replace share_working_mining = share_working_mining * 100

* format variables to make the output more readible
format pop1837_tot area_in_km2 %9.0f
format pop_density_37 %9.1g
format share_working_mining literacy_rate share_protestant fortification %9.2g

sort Gewerbefreiheit
by Gewerbefreiheit: summarize if westphalen==1

* gen difference in log population
gen log_diff_37_64 = log(pop1864_tot) - log(pop1837_tot) 
replace log_diff_37_64 = log_diff_37_64 *100 // get log points


***********
* Main specification Westphalia!! Only include counties that have belonged to Westphalia

**** 1837 - 1864 ****
* OLS 
eststo: reg log_diff_37_64 Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, robust

* quintile 0.2
eststo: qreg log_diff_37_64 Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, vce(robust) q(0.25)

* quintile 0.5
eststo: qreg log_diff_37_64 Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, vce(robust) q(0.5)

* quintile 0.75
eststo: qreg log_diff_37_64 Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, vce(robust) q(0.75)

* generate Table for quantile regressions (Table C.11)
esttab using "${hp}\Tables_Output\Table_C11_Hessen_Kassel_Prussia_Westphalia_1837_64_quantile_regressions.tex", ///
se replace  label nonotes mtitles("OLS" "q0.25" "q0.5" "q0.75")  


