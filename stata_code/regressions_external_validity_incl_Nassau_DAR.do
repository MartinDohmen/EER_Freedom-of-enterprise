*** run regressions including the other two hessian states for external validity

clear all
set more off


import excel using "${hp}\data_input\data_county_level_NAS_DAR", firstrow sheet(data_county_level_DAR_NAS)

merge 1:1 ID county using "${hp}\data_input\data_geocoding_results\dataset_NAS_DAR_lat_long", nogen

save "${hp}\intermediate_stata_data\dataset_NAS_DAR_final", replace


use "${hp}\intermediate_stata_data\full_dataset_Prussia_Hessen_Kassel", clear

merge 1:1 kreiskey1800 using "${hp}\data_input\data_geocoding_results\dataset_Prussia_KAS_full_lat_long", nogen


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

append using  "${hp}\intermediate_stata_data\dataset_NAS_DAR_final"


generate Gewerbefreiheit = 0
replace Gewerbefreiheit = 1 if state=="PRU"
replace Gewerbefreiheit = 1 if state=="NAS"

generate Prussia = 0
replace Prussia = 1 if state=="PRU"

generate Grand_Duchy = 0
replace Grand_Duchy = 1 if state == "DAR"
label var Grand_Duchy "Grand Duchy"

* define which counties belonged to ruhr area
gen ruhr = 0
replace ruhr = 1 if county == "DUISBURG" | county =="RECKLINGHAUSEN" | county =="DORTMUND" | ///
	county == "BOCHUM" | county == "HAGEN" | county == "ISERLOHN" | county == "ALTENA" | county == "HAMM"


* Calculate Growthrates in percentage points
generate growthrate_37_49 = (pop1849_tot - pop1837_tot)/pop1837_tot*100
generate growthrate_37_64 = (pop1864_tot - pop1837_tot)/pop1837_tot*100
generate growthrate_49_64 = (pop1864_tot - pop1849_tot)/pop1849_tot*100
gen log_diff_37_64 = log(pop1864_tot) - log(pop1837_tot) 
replace log_diff_37_64 = log_diff_37_64 *100 // get log points

* Calculate necessary population densities
generate pop_density_37 = pop1837_tot/area_in_km2
generate pop_density_49 = pop1849_tot/area_in_km2

* Label population density for esttab
label var pop_density_37 "Pop. density 1837"
label var pop_density_49 "Pop. density 1849"





**** 1837 - 1864 **** CONLEY SEs
eststo clear 
*Kassel Nassau
eststo: acreg log_diff_37_64 Gewerbefreiheit pop_density_37 if state=="KAS" | state=="NAS", spatial latitude(g_lat) longitude(g_lon) dist(50)
*Kassel DAR
eststo: acreg log_diff_37_64 pop_density_37 Grand_Duchy if state=="KAS" | (state=="DAR" & county!="Kreis Offenbach"), spatial latitude(g_lat) longitude(g_lon) dist(50)

* DAR Prussia
eststo: acreg log_diff_37_64 pop_density_37 Gewerbefreiheit if (state=="DAR" & county!="Kreis Offenbach") | rb=="KOB" | (rb=="ARN" & ruhr!=1), spatial latitude(g_lat) longitude(g_lon) dist(50)


* DAR Nassau
eststo: acreg log_diff_37_64 pop_density_37 Gewerbefreiheit if (state=="DAR" & county!="Kreis Offenbach") | state=="NAS", spatial latitude(g_lat) longitude(g_lon) dist(50)

* Pooled all
eststo: acreg log_diff_37_64 Gewerbefreiheit pop_density_37 if county!="Kreis Offenbach", spatial latitude(g_lat) longitude(g_lon) dist(50)
* Pooled adjacent distr.
eststo: acreg log_diff_37_64 Gewerbefreiheit pop_density_37 if ruhr!=1 & rb!="AAC" & rb!="KOL" & rb!="DUS" & rb!="TRI" & rb!="MUN" & rb!="MAG" & rb!="MER" & county!="Kreis Offenbach", spatial latitude(g_lat) longitude(g_lon) dist(50)

esttab using "${hp}\Tables_Output\Table_6_external_validity_all_states_Conley_SEs.tex", ///
se r2 replace nonotes mtitles("\footnotesize Elec-Nas" "\footnotesize  Elec-GrDu" "\footnotesize  GrDu-Pru" "\footnotesize  GrDu-Nas" "\footnotesize  Pooled all" "\footnotesize  Pooled distr.") label 
