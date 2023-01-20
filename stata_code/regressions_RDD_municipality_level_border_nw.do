*** Import and regressions for RDD data municipality level
* final regression using conel SEs and border distances

clear all
set more off

*** Load data about border between Prussia and Electorate (todays border between Hessen and North Rhine-Westphalia)

cd "${hp}\intermediate_stata_data"

shp2dta using "${hp}\data_input\data_Landesgrenzen_shape\data_vg2500_bld", database(Landesgrenzen_daten) coordinates(Landesgrenzen_coordinates) genid(id_var) replace



***** get coordinates of border between NRW and Hessen
use "${hp}\intermediate_stata_data\Landesgrenzen_coordinates", clear
keep if _ID == 4 | _ID==5
duplicates tag _X _Y, gen(dupl)

keep if _ID==5 & dupl == 1

* drop coordinates that are not needed
drop in 201
drop in 1/2

* point to where the border is needed: 51.447228, 9.088848
drop if _X < 9.088848
drop in 1/2 // two points that are two far on the border


**** calculate distance between adjacent points and interpolate points if distance too large
* Make sure that the line segments are short. Target
* 0.1 km between each point. Create new points for polygon segments
* that are too long

rename _X lon
rename _Y lat
order _ID lat lon
drop _ID
gen id = _n
    // distance between consecutive points
    gen double lat2 = lat[_n+1]
    gen double lon2 = lon[_n+1]
    geodist lat lon lat2 lon2, gen(d) 
    
    // number of points needed to keep the segments at < 0.1 km
    gen n = 1 + int(d/0.1)
    
    expand n if !mi(d)
    sort id
    
    // interpolate linearly each intermediary points
    by id: gen double lat3 = lat + (_n-1) * (lat2 - lat) / n
    by id: gen double lon3 = lon + (_n-1) * (lon2 - lon) / n
    
    // use these new coordinates
    drop lat lon
    rename lat3 lat
    rename lon3 lon
    replace id = _n
    
    // double check; ignore missing distances (separate polygons)
    keep id lat lon
    gen double lat2 = lat[_n+1]
    gen double lon2 = lon[_n+1]
    geodist lat lon lat2 lon2, gen(d) 
     assert round(d,.1) <= 0.1 if !mi(d)


* Clean-up and save
    keep id lat lon

save "${hp}\intermediate_stata_data\coordinates_points_border_PRU_KAS", replace


**** Calculate distance between all municipalities and border	 
use "${hp}\data_input\data_geocoding_results\dataset_municipalities_RDD_geocodes_lat_long", clear
    
    geonear ID g_lat g_lon using "${hp}\intermediate_stata_data\coordinates_points_border_PRU_KAS", ///
        n(id lat lon) 

rename km_to_nid distance_to_border_km		
		
save "${hp}\intermediate_stata_data\coordinates_points_border_PRU_KAS_with_border_distance", replace		




*** import municipality-level data, merge with border distance data and perform regressions
import excel using "${hp}\data_input\data_municipalities_border_Electorate_Minden_Pru", firstrow sheet(municipality_data_border_Electo) clear

drop Municipality 
merge 1:1 ID using "${hp}\intermediate_stata_data\coordinates_points_border_PRU_KAS_with_border_distance", nogen
order ID Municipality 

rename State state 
rename County county 

generate Gewerbefreiheit = 0
replace Gewerbefreiheit = 1 if state=="PRU"

* gen positive and negative distance to border, negative for Kassel
gen border_dist_reg = distance_to_border_km
replace border_dist_reg = distance_to_border_km * (-1) if state == "KAS"
label var border_dist_reg "Border distance"

gen border_dist_reg_sq = distance_to_border_km^2
replace border_dist_reg_sq = distance_to_border_km^2 * (-1) if state == "KAS"
label var border_dist_reg_sq "Border distance\textsuperscript{2}"

gen border_dist_reg_third = distance_to_border_km^3
replace border_dist_reg_third = distance_to_border_km^3 * (-1) if state == "KAS"
label var border_dist_reg_third  "Border distance\textsuperscript{3}"



* label total population for esttab
label var pop_tot_1837 "Pop. 1837 in 1000"

* Calculate Growthrates in percentage points and log differences in population
gen log_diff_37_49 = log(pop_tot_1849) - log(pop_tot_1837) 
replace log_diff_37_49 = log_diff_37_49 *100 // get log points
label var log_diff_37_49 "y{subscript:i,1849} - y{subscript:i,1837}"


*** fixed effects for districts from the department Fulda in the Kingdom Westphalia
generate distr_Kassel = 0
replace  distr_Kassel = 1 if Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
label var distr_Kassel "Old district Kassel"
generate distr_Hoexter = 0
replace  distr_Hoexter = 1 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1

* measure population in 1000 inhabitants for regression
gen pop_weights = pop_tot_1837
replace pop_tot_1837 = pop_tot_1837/1000
gen log_pop_1837 = log(pop_tot_1837)
replace pop_weights = round(pop_weights)


save "${hp}\intermediate_stata_data\municipality_data_RDD_border_Electorate_Minden_Pru", replace


*** Plot data west and east of the border separately as RDD plot in bins and add linear fit with confidence intervals (95%)
* bins are 2 km wide and plot average of the data within each bin
cd "${hp}\Figures_output"
cmogram log_diff_37_49 border_dist_reg, cut(0) scatter lineat(0) lfitci  histopts(w(2)) lfitopts(level(95)) graphopts(xlabel(-50(10)50) ylabel(0(5)20)) // graphopts(ytitle("Mean of difference in log population")) median 

graph export Figure_3_RDD_binned_data_plot_lfit_ci_95.pdf, replace 


**** 1837 - 1849 **** USING CONLEY SEs, BORDER DISTANCE AND PWEIGHT
eststo clear 
*** all ***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg [pweight=pop_weights], spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 
local obs_tot = `r(N)'
sum log_diff_37_49 if state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km
estadd scalar mean_dist = round(`r(mean)',.01)
sum distance_to_border_km 
display `r(max)'
estadd scalar max_dist  = round(`r(max)',.01)
estadd local weighted "Yes"

* unweighted 
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 
local obs_tot = `r(N)'
sum log_diff_37_49 if state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km
estadd scalar mean_dist = round(`r(mean)',.01)
sum distance_to_border_km 
display `r(max)'
estadd scalar max_dist  = round(`r(max)',.01)
estadd local weighted "No"


*** adjacent counties***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg [pweight=pop_weights] if county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen", spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen"
local obs_tot = `r(N)'
sum log_diff_37_49 if (county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen") & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen"
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "Yes"

*** Only adjacent Kantons to border from former Kingdom Westphalia***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg [pweight=pop_weights] if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
local obs_tot = `r(N)'
sum log_diff_37_49 if (Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1) & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "Yes"

*** Only adjacent Kantons to border from former Kingdom Westphalia including district FE***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg distr_Kassel [pweight=pop_weights] if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
local obs_tot = `r(N)'
sum log_diff_37_49 if (Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1) & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "Yes"

* unweighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg distr_Kassel if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
local obs_tot = `r(N)'
sum log_diff_37_49 if (Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1) & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "No"

esttab using "${hp}\Tables_Output\Table_5_municipality_level_1837_1849_with_Conley_SEs_border_distance_and_pweights.tex", star( * 0.10 ** 0.05 *** 0.010) ///
se replace r2 label nonotes scalars("weighted Weighted by pop." "share_Pru Share Prussia" "mean_dist Mean border dist." "max_dist Max border dist.") ///
sfmt(%3.2f %9.2f %9.2f) mtitles("All" "All" "Adj" "Kantons" "Kantons" "Kantons")



**** ADD POLYNOMIAL CONTROLS

**** 1837 - 1849 **** USING CONLEY SEs, BORDER DISTANCE AND PWEIGHT
eststo clear 
*** all ***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg border_dist_reg_sq border_dist_reg_third [pweight=pop_weights], spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 
local obs_tot = `r(N)'
sum log_diff_37_49 if state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km
estadd scalar mean_dist = round(`r(mean)',.01)
sum distance_to_border_km 
display `r(max)'
estadd scalar max_dist  = round(`r(max)',.01)
estadd local weighted "Yes"

* unweighted 
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg border_dist_reg_sq border_dist_reg_third, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 
local obs_tot = `r(N)'
sum log_diff_37_49 if state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km
estadd scalar mean_dist = round(`r(mean)',.01)
sum distance_to_border_km 
display `r(max)'
estadd scalar max_dist  = round(`r(max)',.01)
estadd local weighted "No"


*** adjacent counties*** 
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg border_dist_reg_sq border_dist_reg_third [pweight=pop_weights] if county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen", spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen"
local obs_tot = `r(N)'
sum log_diff_37_49 if (county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen") & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if county=="Warburg" | county=="Höxter" | county=="Hofgeismar" | county=="Wolfenhagen"
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "Yes"

*** Only adjacent Kantons to border from former Kingdom Westphalia***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg border_dist_reg_sq border_dist_reg_third [pweight=pop_weights] if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
local obs_tot = `r(N)'
sum log_diff_37_49 if (Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1) & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "Yes"

*** Only adjacent Kantons to border from former Kingdom Westphalia including district FE***
* weighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg  border_dist_reg_sq border_dist_reg_third distr_Kassel [pweight=pop_weights] if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
local obs_tot = `r(N)'
sum log_diff_37_49 if (Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1) & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "Yes"

* unweighted
eststo: acreg log_diff_37_49 Gewerbefreiheit pop_tot_1837 border_dist_reg border_dist_reg_sq border_dist_reg_third distr_Kassel if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1, spatial latitude(g_lat) longitude(g_lon) dist(10)
sum log_diff_37_49 if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
local obs_tot = `r(N)'
sum log_diff_37_49 if (Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1) & state=="PRU"
local obs_pru = `r(N)'
estadd scalar share_Pru = `obs_pru'/`obs_tot'
sum distance_to_border_km if Trendelburg_Hoexter==1 | Roesebeck_Hoexter==1 | Warburg_Hoexter==1 | Beverungen_Hoexter==1 ///
| Karlshafen_Kassel==1 | Hofgeismar_Kassel==1 | Niedermeisner_Kassel==1 | Volksmarsen_Kassel==1
estadd scalar mean_dist = round(`r(mean)',.01) 
estadd scalar max_dist  = round(`r(max)',.01) 
estadd local weighted "No"

esttab using "${hp}\Tables_Output\Table_C12_municipality_level_1837_1849_with_Conley_SEs_border_distance_and_pweights_dist_poly.tex", star( * 0.10 ** 0.05 *** 0.010) ///
se replace r2 label nonotes scalars("weighted Weighted by pop." "share_Pru Share Prussia" "mean_dist Mean border dist." "max_dist Max border dist.") ///
sfmt(%3.2f %9.2f %9.2f) mtitles("All" "All" "Adj" "Kantons" "Kantons" "Kantons")

