*** Add additional controls for Prussian countries and load data for the Electorate


clear all
set more off


* Add additional controls for Prussia constructed by hand using Wikipedia (fortification), maps etc
import excel using "${hp}\data_input\data_Hesse_plus_extra_variables_Prussia", clear sheet("additional_controls_Prussia") firstrow

drop county
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_Prussia_full.dta", nogen

replace state = rb if rb == "KAS"

save "${hp}\intermediate_stata_data\ipehd_Prussia_full_with_additional_controls.dta", replace

keep if rb == "KAS"


save "${hp}\intermediate_stata_data\ipehd_only_Hessen_Kassel.dta", replace


* add population data and additional controls for Hessen-Kassel
import excel using "${hp}\data_input\data_Hesse_plus_extra_variables_Prussia", clear sheet("data_Hessen_Kassel") firstrow
drop in 20/22

merge 1:1 county using "${hp}\intermediate_stata_data\ipehd_only_Hessen_Kassel.dta", nogen

save "${hp}\intermediate_stata_data\ipehd_only_Hessen_Kassel.dta", replace



* append both data sets
use "${hp}\intermediate_stata_data\ipehd_Prussia_full_with_additional_controls.dta", clear
drop if rb == "KAS"

append using "${hp}\intermediate_stata_data\ipehd_only_Hessen_Kassel.dta"

save "${hp}\intermediate_stata_data\full_dataset_Prussia_Hessen_Kassel", replace
