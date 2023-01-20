*** Calculate kingdom westphalia regression with alternative outcome variables


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


/* Robustness checks city counties
* Exclude city states with very small areas!
drop if county=="Halle (Saale)" & rb=="MER"
drop if county=="Magdeburg"
drop if county=="Stadt M?ster"

* Dummy for city states 
generate city_county = 0
replace city_county = 1 if county=="Magdeburg" | county=="Halle (Saale)" | county=="Stadt M?ster"
*/

generate Gewerbefreiheit = 0
replace Gewerbefreiheit = 1 if state=="PRU"
rename Westphalen westphalen


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
label var share_working_mining "Working in mining"
label var fortification "Fortification"

* Put share control variables in %
replace share_protestant = share_protestant * 100
replace literacy_rate = literacy_rate * 100
replace share_working_mining = share_working_mining * 100
replace share_manufacturing = share_manufacturing * 100
replace share_manufacturing_wo_mining = share_manufacturing_wo_mining *100
replace share_self_empl_manuf_wo_min = share_self_empl_manuf_wo_min * 100

* format variables to make the output more readible
format pop1837_tot area_in_km2 %9.0f
format pop_density_37 %9.1g
format share_working_mining literacy_rate share_protestant fortification  %9.2g


/** Calculate state level pop density

keep if westphalen==1
collapse (sum) pop1837_tot pop1864_tot area_in_km2, by(state)

gen pop_density_64 = pop1864_tot/ area_in_km2
gen pop_density_37 = pop1837_tot/ area_in_km2
*/


**** 1837 - 1864 **** ALTERNATIVE OUTCOME VARIABLES  ****** CONLEY SEs
eststo clear 

preserve
* Exclude city states with very small areas! Because they give all important variation in outcome variable otherwise.
drop if county=="HALLE" & rb=="MER"
drop if county=="MAGDEBURG"
drop if county=="MUNSTER" & kreiskey1800 == 193

*drop if county=="Kreis Kassel"

*** Population density 1864
eststo: acreg pop_density_64 Gewerbefreiheit pop_density_37 if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)

* with all controls and fortification dummy 
eststo: acreg pop_density_64 Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)



*** Income tax variable 1878
eststo: acreg income_tax_pc_1878 Gewerbefreiheit pop_density_37 if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)

* with all controls and fortification dummy 
eststo: acreg income_tax_pc_1878 Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)
restore 

*** share manufacturing without mining
eststo: acreg share_manufacturing_wo_mining Gewerbefreiheit pop_density_37 if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)

* with all controls and fortification dummy 
eststo: acreg share_manufacturing_wo_mining Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)

*** share self employed without mining
eststo: acreg share_self_empl_manuf_wo_min Gewerbefreiheit pop_density_37 if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)

* with all controls and fortification dummy 
eststo: acreg share_self_empl_manuf_wo_min Gewerbefreiheit pop_density_37 share_protestant literacy_rate share_working_mining fortification if westphalen==1, spatial latitude(g_lat) longitude(g_lon) dist(50)



esttab using "${hp}\Tables_Output\Table_4_Hessen_Kassel_Prussia_Westphalia_1837_64_alternative_outcome_variables_new_Conley_SEs.tex", star( * 0.10 ** 0.05 *** 0.010) compress ///
se r2 replace nonotes nomtitles mgroups("Pop. density 64" "Income tax pc 77/78" "Share manuf. 82" "Self-employed in manuf.", pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) ///
suffix(}) span erepeat(\cmidrule(lr){@span})) label 


