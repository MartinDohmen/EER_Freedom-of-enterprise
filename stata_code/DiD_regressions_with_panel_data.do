***** DiD regression in panel data

clear all
set more off

* load data
use "${hp}\intermediate_stata_data\full_dataset_Prussia_Hessen_Kassel", clear
*add information from geocoding
merge 1:1 kreiskey1800 using "${hp}\data_input\data_geocoding_results\dataset_Prussia_Hessen_Kassel_lat_long", nogen

* analyze share of military population (footnote 37 and 38)
gen share_mil_pop = pop1864_mil / pop1864_tot
sum share_mil_pop if state=="PRU" & Westphalen== 1
tab share_mil_pop if state=="PRU" & Westphalen== 1
sum share_mil_pop if  state=="PRU" & Westphalen== 0
sum share_mil_pop if  state=="PRU" & fortification== 1
sum share_mil_pop if  state=="PRU" & fortification== 1 & Westphalen== 1
drop share_mil_pop

* drop all data not belonging to the Electorate or neighboring Prussian Provinces
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

rename pop1821_tot pop1821
rename pop1837_tot pop1837
rename pop1849_tot pop1849
rename pop1864_tot pop1864

* test correlation of education variables
correlate primary_school_enrollment_1849 primary_school_enr_approx_1864 literacy_rate if state=="PRU" & Westphalen==1

* get panel data format
reshape long pop, i(kreiskey1800) j(year)

gen log_pop = log(pop)
replace log_pop = log_pop * 100 // such that results can be interpreted in log points

generate Gewerbefreiheit = 0
replace Gewerbefreiheit = 1 if state=="PRU"
rename Westphalen westphalen

gen log_pop_mil_1864 = log(pop1864_mil)


*** make results look nicer
* Label control variables for esttab
label var share_protestant "Share Protestants"
label var literacy_rate "Literacy rate"
label var share_working_mining "Working in mining"
label var fortification "Fortification"

* Put share control variables in %
replace share_protestant = share_protestant * 100
replace literacy_rate = literacy_rate * 100
replace share_working_mining = share_working_mining * 100

* format variables to make the output more readible
format share_working_mining literacy_rate share_protestant fortification %9.2g

* get constant variables for pop density
gen pop_density = pop / area_in_km2
bysort kreiskey1800: egen pop_density_1821 = total(cond(year==1821,pop_density,0))
gen log_pop_density_1821 = log(pop_density_1821)
bysort kreiskey1800: egen pop_1821 = total(cond(year==1821,pop,0))



***panel regression with spatial SEs and HAC
* gen constant
generate constant = 1

* generate variables interacted with time dummies 
gen Gewerbefreiheit_1837 = 0
replace Gewerbefreiheit_1837 = 1 if Gewerbefreiheit == 1 & year == 1837 
label var Gewerbefreiheit_1837 "Gewerbefreiheit * 1837"
gen Gewerbefreiheit_1849 = 0
replace Gewerbefreiheit_1849 = 1 if Gewerbefreiheit == 1 & year == 1849
label var Gewerbefreiheit_1849 "Gewerbefreiheit * 1849"
gen Gewerbefreiheit_1864 = 0
replace Gewerbefreiheit_1864 = 1 if Gewerbefreiheit == 1 & year == 1864
label var Gewerbefreiheit_1864 "Gewerbefreiheit * 1864"

gen popp_density_1821_1837 = 0
replace popp_density_1821_1837 = pop_density_1821 if year == 1837 
label var popp_density_1821_1837 "Population density * 1837"
gen popp_density_1821_1849 = 0
replace popp_density_1821_1849 = pop_density_1821 if year == 1849 
label var popp_density_1821_1849 "Population density * 1849"
gen popp_density_1821_1864 = 0
replace popp_density_1821_1864 = pop_density_1821 if year == 1864 
label var popp_density_1821_1864 "Population density * 1864"


foreach y in 1837 1849 1864 {
	gen share_protestant_`y' = 0
	replace share_protestant_`y' = share_protestant if year == `y'
	label var share_protestant_`y' "Share Protestants * `y'"
		gen literacy_rate_`y' = 0
	replace literacy_rate_`y' = literacy_rate if year == `y'
		label var literacy_rate_`y' "Literacy rate * `y'"
		gen share_working_mining_`y' = 0
	replace share_working_mining_`y' = share_working_mining if year == `y'
		label var share_working_mining_`y' "Share mining * `y'"
			gen fortification_`y' = 0
	replace fortification_`y' = fortification if year == `y'
		label var fortification_`y' "Fortification * `y'"
	gen pop_mil_64_`y' = 0
	replace pop_mil_64_`y' = log_pop_mil_1864 if year == `y'
		label var pop_mil_64_`y' "Military pop 1864 * `y'"
}	


*encode kreiskey1800, gen(id)
egen id = group(kreiskey1800)



keep id g_lat g_lon log_pop Gewerbefreiheit_* constant popp_density_1821_* year share_protestant* literacy_rate* share_working_mining* westphalen fortification_* pop_mil_64_*



foreach distcutoff in 30 50 100 {

eststo clear 
xtset id year

eststo: acreg log_pop Gewerbefreiheit_1837 Gewerbefreiheit_1849 Gewerbefreiheit_1864 if westphalen==1, ///
	time(year) id(id) pfe1(id) pfe2(year) lagcut(44) spatial latitude(g_lat) longitude(g_lon) dist(`distcutoff') correctr2 hac 
estadd local county_time_FEs "Yes"
estadd local controls "No"


* with pop density	
eststo: acreg log_pop Gewerbefreiheit_1837 Gewerbefreiheit_1849 Gewerbefreiheit_1864 ///
popp_density_1821_1837 popp_density_1821_1849 popp_density_1821_1864  if westphalen==1, ///
	time(year) id(id) pfe1(id) pfe2(year) lagcut(44) spatial latitude(g_lat) longitude(g_lon) dist(`distcutoff') correctr2 hac 
estadd local county_time_FEs "Yes"
estadd local controls "No"

* with all controls
eststo: acreg log_pop Gewerbefreiheit_1837 Gewerbefreiheit_1849 Gewerbefreiheit_1864 ///
popp_density_1821_1837 popp_density_1821_1849 popp_density_1821_1864 share_protestant_1837 share_protestant_1849 share_protestant_1864 ///
literacy_rate_1837 literacy_rate_1849 literacy_rate_1864 share_working_mining_1837 share_working_mining_1849 share_working_mining_1864 ///
 if westphalen==1, time(year) id(id) pfe1(id) pfe2(year) lagcut(44) spatial latitude(g_lat) longitude(g_lon) dist(`distcutoff') correctr2 hac 
estadd local county_time_FEs "Yes"
estadd local controls "P\&L\&M"

* fortification dummy 
eststo: acreg log_pop Gewerbefreiheit_1837 Gewerbefreiheit_1849 Gewerbefreiheit_1864 ///
popp_density_1821_1837 popp_density_1821_1849 popp_density_1821_1864 share_protestant_1837 share_protestant_1849 share_protestant_1864 ///
literacy_rate_1837 literacy_rate_1849 literacy_rate_1864 share_working_mining_1837 share_working_mining_1849 share_working_mining_1864 ///
fortification_1837 fortification_1849 fortification_1864 if westphalen==1, ///
time(year) id(id) pfe1(id) pfe2(year) lagcut(44) spatial latitude(g_lat) longitude(g_lon) dist(`distcutoff') correctr2 hac 
estadd local county_time_FEs "Yes"
estadd local controls "All"
 
* Province specfification
eststo: acreg log_pop Gewerbefreiheit_1837 Gewerbefreiheit_1849 Gewerbefreiheit_1864 ///
popp_density_1821_1837 popp_density_1821_1849 popp_density_1821_1864 share_protestant_1837 share_protestant_1849 share_protestant_1864 ///
literacy_rate_1837 literacy_rate_1849 literacy_rate_1864 share_working_mining_1837 share_working_mining_1849 share_working_mining_1864 ///
fortification_1837 fortification_1849 fortification_1864, ///
time(year) id(id) pfe1(id) pfe2(year) lagcut(44) spatial latitude(g_lat) longitude(g_lon) dist(`distcutoff') correctr2 hac 
estadd local county_time_FEs "Yes"
estadd local controls "All"

* long table (Appendix C1)
esttab using "${hp}\Tables_Output\Table_C8_C9_C10_Hessen_Kassel_Prussia_Westphalia_1837_64_DiD_Conley_SEs_HAC_dist_`distcutoff'.tex", star( * 0.10 ** 0.05 *** 0.010)  ///
se r2 replace  nomtitles label nonotes noomitted scalars("county_time_FEs County \& time FEs") nogaps  

* short table (Table 3 in section 5)
esttab using "${hp}\Tables_Output\Table_3_variants_Hessen_Kassel_Prussia_Westphalia_1837_64_DiD_Conley_SEs_HAC_dist_`distcutoff'_short.tex", star( * 0.10 ** 0.05 *** 0.010)  ///
se r2 replace  nomtitles label nonotes noomitted scalars("county_time_FEs County \& time FEs" "controls Additional controls") ///
drop(share_protestant_1837 share_protestant_1849 share_protestant_1864 literacy_rate_1837 literacy_rate_1849 literacy_rate_1864 ///
share_working_mining_1837 share_working_mining_1849 share_working_mining_1864 fortification_1837 fortification_1849 fortification_1864)

}
