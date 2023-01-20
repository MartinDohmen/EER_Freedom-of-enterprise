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
generate growthrate_64_77 = (pop1877_tot - pop1864_tot)/pop1864_tot *100
generate growthrate_37_77 = (pop1877_tot - pop1837_tot)/pop1837_tot *100

* Calculate necessary population densities 
generate pop_density_37 = pop1837_tot/area_in_km2


* Label population density for esttab
label var pop_density_37 "Pop. density 1837"


* Label control variables for esttab
label var share_protestant "Share Protestants"
label var literacy_rate "Literacy rate"
label var share_working_mining "Share working mining"
label var fortification "Fortification"

* Put share control variables in %
replace share_protestant = share_protestant * 100
replace literacy_rate = literacy_rate * 100
replace share_working_mining = share_working_mining * 100

***** Summary statistics
* format variables to make the output more readible
format pop1837_tot area_in_km2 %9.0f
format pop_density_37 %9.1g
format share_working_mining literacy_rate share_protestant fortification %9.2g

sort Gewerbefreiheit
by Gewerbefreiheit: summarize if westphalen==1

eststo clear 
by Gewerbefreiheit: eststo: estpost summarize pop1837_tot area_in_km2 pop_density_37 share_working_mining literacy_rate share_protestant fortification if westphalen==1
esttab using "${hp}\Tables_Output\Table_2_summary_statistics_county_level_Westphalia.tex", replace nonumbers  ///
coeflabels(pop1837_tot "Population 1837" area_in_km2 "Area in km$^2$" pop_density_37 "Pop. density 1837" share_protestant "Share Protestants 1871" literacy_rate "Literacy rate 1871" share_working_mining "Working mining 1882" fortification "Fortification") ///
gaps cells("mean(fmt(%9.2f) label(Mean)) sd(fmt(%9.2f) label(StdDev)) min(fmt(%9.2f) label(Min)) max(fmt(%9.2f) label(Max))") label mtitles("Electorate of Hesse" "Prussia") booktabs



*** Test for correlation between different outcome variable - main paper data section
correlate growthrate_37_77 income_tax_pc_1878 if westphalen==1
correlate growthrate_64_77 income_tax_pc_1878 if westphalen==1


