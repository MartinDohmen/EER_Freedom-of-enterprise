*** Construct the data set for Prussia and the counties of former Electorate of Hesse
* using the iPEHD data base
* Follow the instructions to merge files from the authors of the iPEHD data base


clear all
set more off


*** Step 1 and 2 to get control variables from 1871 --> literacy rate and share protestant
insheet using "${hp}\data_input\data_ipehd_1871_edu_literacy_part1.csv", clear 
save "${hp}\intermediate_stata_data\ipehd_1871_edu_literacy.dta", replace

insheet using "${hp}\data_input\data_ipehd_1871_rel_deno.csv", clear 
save "${hp}\intermediate_stata_data\ipehd_1871_rel_deno.dta", replace

insheet using "${hp}\data_input\data_ipehd_1871_pop_demo_part1.csv", clear 
save "${hp}\intermediate_stata_data\ipehd_1871_pop.dta", replace

merge 1:1 kreiskey1871 using "${hp}\intermediate_stata_data\ipehd_1871_rel_deno.dta" /* Step 2 */
drop _merge

merge 1:1 kreiskey1871 using "${hp}\intermediate_stata_data\ipehd_1871_edu_literacy.dta" /* Step 2 */
drop _merge

save "${hp}\intermediate_stata_data\ipehd_1871_all.dta", replace /* Step 3 */

insheet using "${hp}\data_input\data_ipehd_merge_county.csv", clear /* Step 4 */

duplicates drop kreiskey1871, force /* Step 5 */
drop if kreiskey1871==.

merge 1:1 kreiskey1871 using "${hp}\intermediate_stata_data\ipehd_1871_all.dta" /* Step 6 */

replace kreiskey1800 = 9000 + kreiskey1871 if rb =="KAS"

*** save new kreiskey file, such that counties in Electorate are not dropped
preserve
keep kreiskey* county* county rb
save "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", replace
restore

collapse (sum) pop1871_tot rel1871_pro rel1871_cat rel1871_jew lit1871_raw_ov10 lit1871_mis_ov10 lit1871_ill_ov10, by (kreiskey1800) /* Step 7 */
drop if kreiskey1800==.
save "${hp}\intermediate_stata_data\ipehd_1871_pop_for_merge.dta", replace



*** Data alternative outcome variable income tax per capita 1878
insheet using "${hp}\data_input\data_ipehd_1878_pop_demo.csv", clear 
drop if county=="TUCHEL"
save "${hp}\intermediate_stata_data\ipehd_1878_pop_demo.dta", replace

insheet using "${hp}\data_input\data_ipehd_1878_wag_tax.csv", clear 
save "${hp}\intermediate_stata_data\ipehd_1878_wag_tax.dta", replace

merge 1:1 kreiskey1878 using "${hp}\intermediate_stata_data\ipehd_1878_pop_demo.dta" /* Step 2 */
drop _merge

generate income_tax_pc_1878 = ( tax1878_cta +  tax1878_cit ) / pop1877_tot

save "${hp}\intermediate_stata_data\ipehd_1878_income_tax.dta", replace /* Step 3 */

use "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", clear /* Step 4 */

duplicates drop kreiskey1878, force /* Step 5 */
drop if kreiskey1878==.

merge 1:1 kreiskey1878 using "${hp}\intermediate_stata_data\ipehd_1878_income_tax.dta", nogen /* Step 6 */

collapse (sum) pop1877_tot income_tax_pc_1878, by (kreiskey1800) /* Step 7 */

drop if kreiskey1800==.
save "${hp}\intermediate_stata_data\ipehd_1878_income_tax_for_merge.dta", replace



*** Prepare data for 1882 for control of share in mining and share of manufacturing
* from occupations survey
insheet using "${hp}\data_input\data_ipehd_1882_rel_occ.csv", clear 
drop county rb
save "${hp}\intermediate_stata_data\ipehd_1882_rel_occ.dta", replace

use "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", clear /* Step 4 */

duplicates drop kreiskey1882, force /* Step 5 */
drop if kreiskey1882==.

merge 1:1 kreiskey1882 using "${hp}\intermediate_stata_data\ipehd_1882_rel_occ.dta", nogen /* Step 6 */

collapse (sum) occ1882_sum_tot occ1882_se_min_tot occ1882_emp_min_tot ///
	occ1882_se_sto_tot occ1882_emp_sto_tot occ1882_se_met_tot occ1882_emp_met_tot occ1882_se_eng_tot occ1882_emp_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_emp_che_tot occ1882_se_lum_tot occ1882_emp_lum_tot occ1882_se_tex_tot occ1882_emp_tex_tot occ1882_se_pap_tot occ1882_emp_pap_tot ///
	occ1882_se_woo_tot occ1882_emp_woo_tot occ1882_se_foo_tot occ1882_emp_foo_tot occ1882_se_clo_tot occ1882_emp_clo_tot occ1882_se_bui_tot ///
	occ1882_emp_bui_tot occ1882_se_pri_tot occ1882_emp_pri_tot occ1882_se_art_tot occ1882_emp_art_tot occ1882_se_utb_tot occ1882_emp_utb_tot, ///
	by (kreiskey1800) /* Step 7 */ 

drop if kreiskey1800==.
save "${hp}\intermediate_stata_data\ipehd_1882_rel_occ_for_merge.dta", replace


*** Prepare population data for 1964 (including data on population for military and civilian)
insheet using "${hp}\data_input\data_ipehd_1864_pop_demo.csv", clear 
keep kreiskey1864 pop1864_tot pop1864_m_0to15 pop1864_f_0to15 pop1864_mil 
save "${hp}\intermediate_stata_data\ipehd_1864_pop.dta", replace

*  get data to calculate school enrollment
insheet using "${hp}\data_input\data_ipehd_1864_edu_stud.csv", clear 
keep kreiskey1864 edu1864_pub_ele_stud edu1864_pub_mim_stud_m edu1864_pub_mif_stud_f 
merge 1:1 kreiskey1864 using "${hp}\intermediate_stata_data\ipehd_1864_pop.dta", nogen
save "${hp}\intermediate_stata_data\ipehd_1864_pop.dta", replace


use "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", clear /* Step 4 */

duplicates drop kreiskey1864, force /* Step 5 */
drop if kreiskey1864==.

merge 1:1 kreiskey1864 using "${hp}\intermediate_stata_data\ipehd_1864_pop.dta" /* Step 6 */

collapse (sum) pop* edu1864_pub_ele_stud edu1864_pub_mim_stud_m edu1864_pub_mif_stud_f , by (kreiskey1800) /* Step 7 */

drop if kreiskey1800==.


save "${hp}\intermediate_stata_data\ipehd_1864_pop_for_merge.dta", replace


*** Prepare population data for 1949 and for 1937 from other dataset
insheet using "${hp}\data_input\data_ipehd_1849_pop_demo.csv", clear 
keep kreiskey1849 pop1849_tot pop1849_m_6to7 pop1849_f_6to7 pop1849_m_8to14 pop1849_f_8to14
save "${hp}\intermediate_stata_data\ipehd_1849_pop.dta", replace

* get data to calculate school enrollment
insheet using "${hp}\data_input\data_ipehd_1849_edu_stud.csv", clear 
keep kreiskey1849 edu1849_pub_ele_stud_m edu1849_pub_ele_stud_f edu1849_pub_mim_stud_m edu1849_pub_mif_stud_f
merge 1:1 kreiskey1849 using "${hp}\intermediate_stata_data\ipehd_1849_pop.dta", nogen


save "${hp}\intermediate_stata_data\ipehd_1849_pop.dta", replace

import excel using "${hp}\data_input\data_Prussia_1837_Sachsen_Westphalen_Rheinprovinz", clear sheet("Sheet1") firstrow

merge 1:1 kreiskey1849 using "${hp}\intermediate_stata_data\ipehd_1849_pop.dta", nogen /* Step 6 */
save "${hp}\intermediate_stata_data\1937_iPEHD_1949_pop_data.dta", replace


use "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", clear /* Step 4 */

duplicates drop kreiskey1849, force /* Step 5 */
drop if kreiskey1849==.

merge 1:1 kreiskey1849 using "${hp}\intermediate_stata_data\1937_iPEHD_1949_pop_data.dta" /* Step 6 */

gen byte pop1837_missing = missing(pop1837_tot)
collapse (sum) pop* edu1849_pub_ele_stud_m edu1849_pub_ele_stud_f edu1849_pub_mim_stud_m edu1849_pub_mif_stud_f , by (kreiskey1800) /* Step 7 */
replace pop1837_tot=. if pop1837_missing!=0
drop pop1837_missing
drop if kreiskey1800==.
save "${hp}\intermediate_stata_data\ipehd_1837_49_pop_for_merge.dta", replace

* Prepare area data from 1858
insheet using "${hp}\data_input\data_ipehd_1858_misc_area.csv", clear 
save "${hp}\intermediate_stata_data\ipehd_1858_area.dta", replace

use "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", clear /* Step 4 */

duplicates drop kreiskey1858, force /* Step 5 */
drop if kreiskey1858==.

merge 1:1 kreiskey1858 using "${hp}\intermediate_stata_data\ipehd_1858_area.dta" /* Step 6 */

collapse (sum) misc1858_area, by (kreiskey1800) /* Step 7 */
drop if kreiskey1800==.
save "${hp}\intermediate_stata_data\ipehd_1858_area_for_merge.dta", replace



*** Get data for 1821 - population and area
insheet using "${hp}\data_input\data_ipehd_1821_misc_area.csv", clear /* Step 8 */
save "${hp}\intermediate_stata_data\ipehd_1821_area.dta", replace

insheet using "${hp}\data_input\data_ipehd_1821_pop_demo.csv", clear /* Step 8 */
save "${hp}\intermediate_stata_data\ipehd_1821_pop.dta", replace

merge 1:1 id1819 using "${hp}\intermediate_stata_data\ipehd_1821_area.dta" /* Step 2, merge data from same year 1821 */
drop _merge

collapse (sum) pop1821_tot misc1821_area, by (kreiskey1800)
save "${hp}\intermediate_stata_data\ipehd_1821_pop_area.dta", replace

use "${hp}\intermediate_stata_data\ipehd_merge_county_with_KAS.dta", clear /* Step 4 */
duplicates drop kreiskey1800, force
drop if kreiskey1800==.
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1821_pop_area.dta"
collapse (sum) pop* misc1821_area  (firstnm) county rb, by (kreiskey1800)
save "${hp}\intermediate_stata_data\ipehd_1821.dta", replace


*** Merge population data from 1837, 1849 and 1864 and 1977 and income tax data
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1837_49_pop_for_merge.dta" /* Step 9 */
drop _merge
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1864_pop_for_merge.dta" /* Step 9 */
drop _merge
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1878_income_tax_for_merge.dta" /* Step 9 */
drop _merge

* Merge area from 1958 and convert area data from prussian Morgen to km²
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1858_area_for_merge.dta"
drop _merge

generate area_in_km2 = misc1858_area * 0.00255322
generate area_in_km2_1821 = misc1821_area * 0.00255322


save "${hp}\intermediate_stata_data\ipehd_pop_1821_1837_1849.dta", replace

*** Merge the data for the control variables
merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1871_pop_for_merge.dta" /* Step 9 */
drop _merge
save "${hp}\intermediate_stata_data\ipehd_1821_1837_1849_1871.dta", replace

merge 1:1 kreiskey1800 using "${hp}\intermediate_stata_data\ipehd_1882_rel_occ_for_merge.dta" /* Step 9 */
drop _merge
save "${hp}\intermediate_stata_data\ipehd_1821_1837_1849_1871_1882.dta", replace

* aggregate both counties of the city of Kassel  - city county and hinterlands county - ensure that missings in tax data and population data of 1977 are preserved
gen missing = 0
replace missing = 1 if income_tax_pc_1878 == .
replace kreiskey1800 = 9999 if county == "KASSEL"
collapse (sum) pop1821_tot misc1821_area pop1837_tot pop1849_tot pop1864_tot area_in_km2 area_in_km2_1821 pop1871_tot rel1871_pro rel1871_cat rel1871_jew lit1871_raw_ov10 lit1871_mis_ov10 ///
	lit1871_ill_ov10 occ1882_sum_tot occ1882_se_min_tot occ1882_emp_min_tot pop1864_mil ///
	pop1849_m_6to7 pop1849_f_6to7 pop1849_m_8to14 pop1849_f_8to14 edu1849_pub_ele_stud_m edu1849_pub_ele_stud_f edu1849_pub_mim_stud_m edu1849_pub_mif_stud_f /// school enrollment 1849
	edu1864_pub_ele_stud edu1864_pub_mim_stud_m edu1864_pub_mif_stud_f pop1864_m_0to15 pop1864_f_0to15 ///school enrollment 1864
		occ1882_se_sto_tot occ1882_emp_sto_tot occ1882_se_met_tot occ1882_emp_met_tot occ1882_se_eng_tot occ1882_emp_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_emp_che_tot occ1882_se_lum_tot occ1882_emp_lum_tot occ1882_se_tex_tot occ1882_emp_tex_tot occ1882_se_pap_tot occ1882_emp_pap_tot ///
	occ1882_se_woo_tot occ1882_emp_woo_tot occ1882_se_foo_tot occ1882_emp_foo_tot occ1882_se_clo_tot occ1882_emp_clo_tot occ1882_se_bui_tot ///
	occ1882_emp_bui_tot occ1882_se_pri_tot occ1882_emp_pri_tot occ1882_se_art_tot occ1882_emp_art_tot occ1882_se_utb_tot occ1882_emp_utb_tot ///
	pop1877_tot income_tax_pc_1878 missing (firstnm) county rb, by (kreiskey1800)
	
replace pop1877_tot = . if missing > 0
replace income_tax_pc_1878 = . if missing > 0	
drop missing

* calculate school enrollment
gen primary_school_enr_approx_1864 = (edu1864_pub_ele_stud+edu1864_pub_mim_stud_m+edu1864_pub_mif_stud_f)/(pop1864_m_0to15+pop1864_f_0to15) 
gen primary_school_enrollment_1849 = (edu1849_pub_ele_stud_m+edu1849_pub_ele_stud_f+edu1849_pub_mim_stud_m+edu1849_pub_mif_stud_f)/(pop1849_m_6to7+pop1849_f_6to7+pop1849_m_8to14+pop1849_f_8to14) 
drop edu1864_pub_ele_stud edu1864_pub_mim_stud_m edu1864_pub_mif_stud_f pop1864_m_0to15 pop1864_f_0to15 edu1849_pub_ele_stud_m ///
	edu1849_pub_ele_stud_f edu1849_pub_mim_stud_m edu1849_pub_mif_stud_f pop1849_m_6to7 pop1849_f_6to7 pop1849_m_8to14 pop1849_f_8to14
*Get share data
generate share_protestant = rel1871_pro / pop1871_tot
generate literacy_rate = lit1871_raw_ov10/(lit1871_ill_ov10+lit1871_raw_ov10)

* Get data for share working in mining and manufacturing
generate share_working_mining = (occ1882_se_min_tot+occ1882_emp_min_tot)/occ1882_sum_tot 

egen workers_manufacturing = rowtotal(occ1882_se_sto_tot occ1882_emp_sto_tot occ1882_se_met_tot occ1882_emp_met_tot occ1882_se_eng_tot occ1882_emp_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_emp_che_tot occ1882_se_lum_tot occ1882_emp_lum_tot occ1882_se_tex_tot occ1882_emp_tex_tot occ1882_se_pap_tot occ1882_emp_pap_tot ///
	occ1882_se_woo_tot occ1882_emp_woo_tot occ1882_se_foo_tot occ1882_emp_foo_tot occ1882_se_clo_tot occ1882_emp_clo_tot occ1882_se_bui_tot ///
	occ1882_emp_bui_tot occ1882_se_pri_tot occ1882_emp_pri_tot occ1882_se_art_tot occ1882_emp_art_tot occ1882_se_utb_tot occ1882_emp_utb_tot occ1882_se_min_tot occ1882_emp_min_tot), missing
generate share_manufacturing = (workers_manufacturing)/occ1882_sum_tot 

* share of self-employed workers in manufacturing
egen workers_manufacturing_se = rowtotal(occ1882_se_sto_tot occ1882_se_met_tot occ1882_se_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_se_lum_tot occ1882_se_tex_tot occ1882_se_pap_tot ///
	occ1882_se_woo_tot occ1882_se_foo_tot occ1882_se_clo_tot occ1882_se_bui_tot ///
	occ1882_se_pri_tot occ1882_se_art_tot occ1882_se_utb_tot occ1882_se_min_tot), missing
generate share_self_empl_manufacturing = (workers_manufacturing_se)/workers_manufacturing 

* share in manufcaturing without mining (alternative definition)
egen workers_manufacturing_wo_mining = rowtotal(occ1882_se_sto_tot occ1882_emp_sto_tot occ1882_se_met_tot occ1882_emp_met_tot occ1882_se_eng_tot occ1882_emp_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_emp_che_tot occ1882_se_lum_tot occ1882_emp_lum_tot occ1882_se_tex_tot occ1882_emp_tex_tot occ1882_se_pap_tot occ1882_emp_pap_tot ///
	occ1882_se_woo_tot occ1882_emp_woo_tot occ1882_se_foo_tot occ1882_emp_foo_tot occ1882_se_clo_tot occ1882_emp_clo_tot occ1882_se_bui_tot ///
	occ1882_emp_bui_tot occ1882_se_pri_tot occ1882_emp_pri_tot occ1882_se_art_tot occ1882_emp_art_tot occ1882_se_utb_tot occ1882_emp_utb_tot), missing
generate share_manufacturing_wo_mining = (workers_manufacturing_wo_mining)/occ1882_sum_tot 

* share of self-employed workers in manufacturing without mining
egen workers_manuf_wo_mining_se = rowtotal(occ1882_se_sto_tot occ1882_se_met_tot occ1882_se_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_se_lum_tot occ1882_se_tex_tot occ1882_se_pap_tot ///
	occ1882_se_woo_tot occ1882_se_foo_tot occ1882_se_clo_tot occ1882_se_bui_tot ///
	occ1882_se_pri_tot occ1882_se_art_tot occ1882_se_utb_tot), missing
generate share_self_empl_manuf_wo_min = (workers_manuf_wo_mining_se)/workers_manufacturing_wo_mining 


drop rel1871_* lit1871_* occ1882_se_min_tot occ1882_emp_min_tot occ1882_sum_tot occ1882_se_sto_tot occ1882_emp_sto_tot occ1882_se_met_tot occ1882_emp_met_tot occ1882_se_eng_tot occ1882_emp_eng_tot occ1882_se_che_tot /// all manufacrturing sectors
	occ1882_emp_che_tot occ1882_se_lum_tot occ1882_emp_lum_tot occ1882_se_tex_tot occ1882_emp_tex_tot occ1882_se_pap_tot occ1882_emp_pap_tot ///
	occ1882_se_woo_tot occ1882_emp_woo_tot occ1882_se_foo_tot occ1882_emp_foo_tot occ1882_se_clo_tot occ1882_emp_clo_tot occ1882_se_bui_tot ///
	occ1882_emp_bui_tot occ1882_se_pri_tot occ1882_emp_pri_tot occ1882_se_art_tot occ1882_emp_art_tot occ1882_se_utb_tot occ1882_emp_utb_tot workers_manufacturing workers_*


* set missing variables to missing for Kassel countries
replace pop1821_tot = . if rb == "KAS"
replace pop1837_tot = . if rb == "KAS"
replace pop1849_tot = . if rb == "KAS"
replace pop1864_tot = . if rb == "KAS"
replace misc1821_area = . if rb == "KAS"
replace area_in_km2 = . if rb == "KAS"


* drop exclaves and parts not belonging to Hesse before (Gersfeld, which was a part of Bavaria)
drop if county == "SCHMALKALDEN" | county == "SCHAUMBURG" | county == "GERSFELD"

save "${hp}\intermediate_stata_data\ipehd_Prussia_full.dta", replace

