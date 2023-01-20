*____________________________________________________________________________*
*____ Master Code to Load Data and Compile Graphs and Figures for Revision _____*
*____________________________________________________________________________*


clear 
 
set more off

* Define working path here to stata_code folder, also change working path in paths.do
capture cd "D:\Sciebo_mitarbeiter_ID\Research on coal and the industrial revolution\Research_coal\paper_Gewerbefreiheit\EEREV-D-21-00547R2_Replication_Files\stata_code"
capture cd "C:\Users\Martin\Sciebo\Research on coal and the industrial revolution\Research_coal\paper_Gewerbefreiheit\Revision\stata_code"

include paths


***** COUNTY-LEVEL RESULTS
*** Load data and construct data sets
* data from iPEHD (for Prussia and control variables) + Prussian data 1837
run "${hp}\stata_code\merge_iPEHD_data"
* data from the Electorate and additional information about Prussian counties from Maps and Wikipedia
run "${hp}\stata_code\add_Prussia_additional_controls_and_data_Hessen_Kassel"

* Generate summary statistics for main data set (Table 2)
run "${hp}\stata_code\summary_statistics_main_county_data"


*** Run regressions
* Diff-in-diff panel regressions Electorate and Prussia with Conley SEs
run "${hp}\stata_code\DiD_regressions_with_panel_data"
* Cross-sectional quantile regressions for Kingdom of Westphalia
run "${hp}\stata_code\quantile_regressions"
* Cross-sectional regressions with alternative outcome variables for Kingdom of Westphalia
run "${hp}\stata_code\alternative_outcome_regressions_kingdom_westphalia"

* Cross-sectional regressions with additional Hessian states (Nassau and Grand Duchy (Hessen-Darmstadt))
run "${hp}\stata_code\regressions_external_validity_incl_Nassau_DAR"


***** MUNICIPALITY-LEVEL RDD RESULTS
run "${hp}\stata_code\regressions_RDD_municipality_level_border_nw"
