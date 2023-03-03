* Generic Seasonality Analysis

* Data requirements for following analysis:  All months of the year must be represented in the data.

* CNNS 2016-18

* These analyses are possible as the CNNS has data from all months of the year. 

ssc install labvalch3
ssc install mdesc
ssc install combomarginsplot



*use "D:\Dropbox\UNICEF\CNNS data May version 12\CNNS_0to4_V12.dta", clear
*  "C:\Temp\CNNS_04_Cleaned_3JUNE_final.dta"
use "C:\Temp\CNNS_04_Cleaned_21MAY_final_with_constructed_var.dta", clear

gen zwfh = _zwfl if _fwfl !=1
gen wasted = 1 if zwfh < -2 & zwfh !=.
replace wasted = 0 if zwfh >= -2 & zwfh !=.
gen sev_wasted = 1 if zwfh < -3 & zwfh !=.
replace sev_wasted = 0 if zwfh >= -3 & zwfh !=.


* to make this code generic
* add local or global with continuous dependent variable - DEPVAR
local depvar zwfh
* calculate the related dichotomous variable - DEPVAR_01
local depvar_01 wasted sev_wasted
* for example with vitamin Age
* gen depvar=serum_retinol
* gen depvar_01 = vitamin A deficiency yes/no

*Control Variables

*Gender
gen male = 1 if q102 ==1
replace male = 0 if q102 ==2

*Age by six month blocks
cap drop agecat
gen agecat = floor(agemons/6)+1
tab agemons agecat, m 
gen agecat_m = agecat
replace agecat_m = 11 if agecat ==.
label def agemo 1 "0-5" 2 "6-11" 3 "12-17" 4 "18-23" 5 "24-29" 6 "30-35" 7 "36-41" 8 "42-47" 9 "48-53" 10 "54-59" 11 "Missing" , replace
label val agecat_m agemo
label var agecat_m "Age (in months)"
tab agecat_m, m 



*Birth weight
gen birth_weight = q645wght if q645wght!=.
replace birth_weight = 9996 if q644 == 2
replace birth_weight = 9998 if q644 == 8
replace birth_weight = 9999 if q644 == 8
replace birth_weight = 9998 if q645u == 8 //if information on the measuring unit is not available

label def bw 9996 "Not weighed at birth" 9998 "Don't know" 9999 "Missing", replace
label val birth_weight bw
label var birth_weight "Birth weight"

*Converting Birth Weight into a categorical variable
egen c_birth_wt = cut(birth_weight), at(0.5,1,2.5,9001,9997,9999,10000) icodes
label def c_birth_wt 0 "Very low" 1 "Low" 2 "Average or more" 3 "Not weighed" 4 "Don't know" 5 "Missing"
label val c_birth_wt c_birth_wt
label var c_birth_wt "Birth weight category"

recode c_birth_wt 2 = 0 0 1 = 2 3=1 4 = 3 5=4, gen(LBW)
label def LBW 0 "0. Average or more" 1 "1. Not weighed at birth" 2 "2. Low" 3 "3. Don't know" 4 "4. Missing", replace
label val LBW LBW
label var LBW "Low birth weight"

* Birth weight recall
gen birth_weight_recall = q645u
label val birth_weight_recall q645u
local title: var label q645u
label var birth_weight_recall "`title'"

* Creation of birth weight based on mothers recall or written card
gen bweight = 0 if LBW == 1 
replace bweight = 1 if LBW == 2 & birth_weight_recall == 2
replace bweight = 2 if LBW == 2 & birth_weight_recall == 1
replace bweight = 3 if LBW == 0 & birth_weight_recall == 2
replace bweight = 4 if LBW == 0 & birth_weight_recall == 1
replace bweight = 5 if LBW >= 3
label def bweight 0 "0. Not weighed" 1 "1. Low weight: From mother's recall" 2 "2. Low weight: From written card" 3 "3. Average or more weight: From mother's recall" 4 "4.  Average or more weight: written card" 5 "5. Don't know/missing", replace
label val bweight bweight
label var bweight "Birth weight: mother's recall or written card"
move bweight LBW

*Mother's Height
gen mean_height_mother = (q1009r1m + q1009r2m)/2 if q1009r1m !=. |  q1009r2m !=.
label var mean_height_mother "Mother's Height (in cm)"
*kdensity mean_height_mother
replace mean_height_mother =. if mean_height_mother<110


*Status of mother's labor force participation
gen mother_working = mother_work
label define working 0 "not in work force" 1 "in work force" 2 "NA/ Not alive" , replace
label val mother_working working
label var mother_working "Working Status"
tab mother_working, m

*Status of mother's education
ren mother_school education_years

*Wealth
gen wealth = wi 
label values wealth `: value label  wi'
labvalch3 wealth , strfcn(proper(`"@"'))

*Household Size
gen hhmem = f_size
label var hhmem "Household Size"

*Religion
gen hindu = religion ==1
label def rel 0 "Other" 1 "Hindu", replace
label val hindu rel
label var hindu "Hindu/Other"



*Caste
label define caste 1 "Schedule Caste" 2 "Schedule Tribe" 3 "OBC" 4 "Other" 8 "Don't know", replace
label val caste caste
label var caste "Caste"



*Residence
gen rural = residence ==1
label def rur 0 "Urban" 1 "Rural", replace
label val rural rur
label var rural "Rural/Urban"

*State
gen statecode = state

*Month of survey
gen month12  = int_m
label define m12 1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun" 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
label val month12 m12 
label var month12 "Month"


* Use state or national weights
*We are using national weights - iw_s_pool
gen survey_weight = iw_s_pool

*Dependent Variables
sum zwfh wasted sev_wasted
*Variable of interest
sum month12
*Other covariates
sum  male agecat_m bweight mean_height_mother mother_working education_years wealth hhmem hindu caste rural statecode
*Gender of the child
*Age of the child
*Birth weight combined with mother's recall status
*Mother's Height
*Mother's Working status
*Mother's education status
*Wealth
*Household Size
*Religion
*Caste
*Rural
*State Dummies
save "C:\Temp\Junk\cnns_seas.dta", replace


* Create dummy variables for all variables below
tab month12, gen(sum_month12)
tab agecat_m, gen(sum_agecat_m)
tab bweight, gen(sum_weight)
tab mother_working, gen(sum_mother_working)
tab education_years, gen(sum_education_years)
tab wealth, gen(sum_wealth)
tab caste, gen(sum_caste)
tab statecode, gen(sum_state)

*Variable finalising the sample to be used for a particular dependent variable
local depvar zwfh
foreach var in `depvar' {
gen final_`var' = 1 if `var' != . & month12 !=. & male !=. & bweight !=. & agecat_m !=. & mean_height_mother != . & education_years   !=. & mother_working  !=. & hindu  !=. & caste !=. & rural !=. & hhmem !=. & wealth !=. & statecode !=. 
}

local depvar_01 wasted sev_wasted
foreach var in `depvar_01' {
gen final_`var' = 1 if `var' != . & month12 !=. & male !=. & bweight !=. & agecat_m !=. & mean_height_mother != . & education_years   !=. & mother_working  !=. & hindu  !=. & caste !=. & rural !=. & hhmem !=. & wealth !=. & statecode !=. 
}

mdesc zwfh male agecat_m bweight mean_height_mother mother_working education_years wealth hhmem hindu caste rural statecode
mdesc male agecat_m bweight mean_height_mother mother_working education_years wealth hhmem hindu caste rural statecode
 if zwfh !=.

* Removed all data but the CNNS

local depvar zwfh
foreach var in `depvar' {
sum `var' sum_month121 sum_month122 sum_month123 sum_month124 sum_month125 sum_month126 sum_month127 sum_month128 sum_month129 sum_month1210 sum_month1211 sum_month1212 male   sum_agecat_m1 sum_agecat_m2 sum_agecat_m3 sum_agecat_m4 sum_agecat_m5 sum_agecat_m6 sum_agecat_m7 sum_agecat_m8 sum_agecat_m9 sum_agecat_m10 sum_agecat_m11 sum_weight1 sum_weight2 sum_weight3 sum_weight4 sum_weight5 sum_weight6 mean_height_mother sum_mother_working1 sum_mother_working2 sum_mother_working3 sum_education_years1 sum_education_years2 sum_education_years3 sum_education_years4 sum_education_years5 sum_education_years6 sum_education_years7 sum_wealth1 sum_wealth2 sum_wealth3 sum_wealth4 sum_wealth5 hhmem hindu sum_caste1 sum_caste2 sum_caste3 sum_caste4 rural sum_state1 sum_state2 sum_state3 sum_state4 sum_state5 sum_state6 sum_state7 sum_state8 sum_state9 sum_state10 sum_state11 sum_state12 sum_state13 sum_state14 sum_state15 sum_state16 sum_state17 sum_state18 sum_state19 sum_state20 sum_state21 sum_state22 sum_state23 sum_state24 sum_state25 sum_state26 sum_state27 sum_state28 sum_state29 sum_state30 if final_`var' ==1

}

local depvar_01 wasted sev_wasted
foreach var in `depvar_01' {
sum `var' sum_month121 sum_month122 sum_month123 sum_month124 sum_month125 sum_month126 sum_month127 sum_month128 sum_month129 sum_month1210 sum_month1211 sum_month1212 male   sum_agecat_m1 sum_agecat_m2 sum_agecat_m3 sum_agecat_m4 sum_agecat_m5 sum_agecat_m6 sum_agecat_m7 sum_agecat_m8 sum_agecat_m9 sum_agecat_m10 sum_agecat_m11 sum_weight1 sum_weight2 sum_weight3 sum_weight4 sum_weight5 sum_weight6 mean_height_mother sum_mother_working1 sum_mother_working2 sum_mother_working3 sum_education_years1 sum_education_years2 sum_education_years3 sum_education_years4 sum_education_years5 sum_education_years6 sum_education_years7 sum_wealth1 sum_wealth2 sum_wealth3 sum_wealth4 sum_wealth5 hhmem hindu sum_caste1 sum_caste2 sum_caste3 sum_caste4 rural sum_state1 sum_state2 sum_state3 sum_state4 sum_state5 sum_state6 sum_state7 sum_state8 sum_state9 sum_state10 sum_state11 sum_state12 sum_state13 sum_state14 sum_state15 sum_state16 sum_state17 sum_state18 sum_state19 sum_state20 sum_state21 sum_state22 sum_state23 sum_state24 sum_state25 sum_state26 sum_state27 sum_state28 sum_state29 sum_state30 if final_`var' ==1
}



* Establish the method to identify the relevant independant variables that should be included in the model
*Variables of Interest - sum_month121 sum_month122 sum_month123 sum_month124 sum_month125 sum_month126 sum_month127 sum_month128 sum_month129 sum_month1210 sum_month1211 sum_month1212
*Other Covariates
local covariates  male   sum_agecat_m1 sum_agecat_m2 sum_agecat_m3 sum_agecat_m4 sum_agecat_m5 sum_agecat_m6 sum_agecat_m7 sum_agecat_m8 sum_agecat_m9 sum_agecat_m10 sum_agecat_m11 sum_weight1 sum_weight2 sum_weight3 sum_weight4 sum_weight5 sum_weight6 mean_height_mother sum_mother_working1 sum_mother_working2 sum_mother_working3 sum_education_years1 sum_education_years2 sum_education_years3 sum_education_years4 sum_education_years5 sum_education_years6 sum_education_years7 sum_wealth1 sum_wealth2 sum_wealth3 sum_wealth4 sum_wealth5 hhmem hindu sum_caste1 sum_caste2 sum_caste3 sum_caste4 rural sum_state1 sum_state2 sum_state3 sum_state4 sum_state5 sum_state6 sum_state7 sum_state8 sum_state9 sum_state10 sum_state11 sum_state12 sum_state13 sum_state14 sum_state15 sum_state16 sum_state17 sum_state18 sum_state19 sum_state20 sum_state21 sum_state22 sum_state23 sum_state24 sum_state25 sum_state26 sum_state27 sum_state28 sum_state29 sum_state30



* Seasonality of depvar
local depvar zwfh
foreach var in `depvar' {
reg `var' ib12.month12 male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}




* recode of SES
gen wealth3 = 1 if wealth ==1 | wealth ==2
replace wealth3 = 2 if wealth ==3 
replace wealth3 = 3 if wealth ==4 | wealth ==5

* Seasonality of depvar by socio-economic status 
* Interaction of month with SES tercile
local depvar zwfh
foreach var in `depvar' {
reg `var' ib12.month12##i.wealth3 male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth3 hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12#wealth3
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}

* state_comp - we can ignore this as it was created to find the states common across different rounds of NFHS3, NFHS4 and CNNS 


* Rural Urban
*reg zwfh ib12.month12##i.wealth3 i.weight i.agecat_m i.statecode i.education_years i.mother_working hindu i.caste rural hhmem [pw = survey_weight] 
*margins month12##rural
*marginsplot

* Rural Urban
reg zwfh ib12.month12 if rural ==1 [pw = survey_weight]
margins month12, saving("C:\Temp\Junk\temp_1.dta", replace)
reg zwfh ib12.month12 if rural ==0 [pw = survey_weight]
margins month12, saving ("C:\Temp\Junk\temp_0.dta", replace)
combomarginsplot "C:\Temp\Junk\temp_1.dta" "C:\Temp\Junk\temp_0.dta", labels("Rural" "Urban") ytitle(Linear Predictions) noci


* Male vs Female
reg zwfh ib12.month12 if male==1 [pw = survey_weight]
margins month12, saving("C:\Temp\Junk\temp_1.dta", replace)
reg zwfh ib12.month12 if male ==0 [pw = survey_weight]
margins month12, saving ("C:\Temp\Junk\temp_0.dta", replace)
combomarginsplot "C:\Temp\Junk\temp_1.dta" "C:\Temp\Junk\temp_0.dta", labels("Male" "Female") ytitle(Linear Predictions) noci

* recode of agecat
gen age = 0 if agecat<3
replace age = 1 if agecat>=3 & agecat<5
replace age = 2 if agecat>=5 & agecat<7
replace age = 3 if agecat>=7 & agecat<9
replace age = 4 if agecat>=9 & agecat<11
tab agecat age, m

* Does month of birth affect seasonality effect on prevalence of wasting (WHZ<-2SD)  in children under-five
* Month of birth -q103m
* add code - I am trying two different specifications
*1. Including month of birth alongwith age of the child
local depvar zwfh
foreach var in `depvar' {
reg `var' ib12.month12 ib12.q103m male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}

local depvar_01 wasted sev_wasted
foreach var in `depvar' {
logit `var' ib12.month12 ib12.q103m male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}
*2. Replacing age of the children by month of birth as it is likely to be collinear with the age.
local depvar zwfh
foreach var in `depvar' {
reg `var' ib12.month12 ib12.q103m male  i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}

local depvar_01 wasted sev_wasted
foreach var in `depvar' {
logit `var' ib12.month12 ib12.q103m male i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}

* Age in years
* should control for month of birth
reg zwfh ib12.month12 if age==0 [pw = survey_weight]
margins month12, saving("C:\Temp\Junk\temp_0.dta", replace)
reg zwfh ib12.month12 if age==1  [pw = survey_weight]
margins month12, saving ("C:\Temp\Junk\temp_1.dta", replace)
reg zwfh ib12.month12 if age==2 [pw = survey_weight]
margins month12, saving ("C:\Temp\Junk\temp_2.dta", replace)
reg zwfh ib12.month12 if age==2 [pw = survey_weight]
margins month12, saving ("C:\Temp\Junk\temp_3.dta", replace)
reg zwfh ib12.month12 if age==2 [pw = survey_weight]
margins month12, saving ("C:\Temp\Junk\temp_4.dta", replace)
combomarginsplot "C:\Temp\Junk\temp_0.dta" "C:\Temp\Junk\temp_1.dta" "C:\Temp\Junk\temp_2.dta" "C:\Temp\Junk\temp_3.dta" "C:\Temp\Junk\temp_4.dta", ///
	labels("0 years" "1 year" "2 years" "3 years" "4 years") ytitle(Linear Predictions) noci


* Does seasonality have an effect on prevalence of wasting (WHZ<-2SD)  in children under-five 
* wasted
tab wasted
tab wasted, m 

* Seasonality of wasting WITHOUT control vars
logit wasted ib12.month12  [pw = survey_weight] 
margins month12
marginsplot, title("Seasonality of Wasting")
* There is little seasonal variation with wasting here, from 15 to 20%

* Seasonality of wasting with control vars
logit wasted ib12.month12 male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
marginsplot, title("Seasonality of Wasting")
* There is significant seasonal variation here from 11 to 23%





* Does seasonality have an effect on prevalence of overweight / obesity in children under-five 

* Overweight WHZ>+2 SD
gen overwgt = zwfh
recode overwgt (min/1.99=0) (2/max=1) (.=.)
replace overwgt=. if _fwfl==1
tab overwgt, m 

* Seasonality of overweight WITHOUT control vars
logit overwgt ib12.month12  [pw = survey_weight] 
margins month12
marginsplot, title("Seasonality of Overweight")
* These results are counterintuitive as overweight increases in March through May and declines to normal in September. 


* Seasonality of overweight with control vars
logit overwgt ib12.month12 male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
marginsplot, title("Seasonality of Overweight")
* These results are counterintuitive as overweight increases in March through May and declines to normal in September. 

*You may use the loop if you want
local depvar_01 wasted sev_wasted overwgt
foreach var in `depvar' {
logit `var' ib12.month12 male i.agecat_m i.bweight mean_height_mother i.mother_working i.education_years i.wealth hhmem hindu i.caste rural i.statecode [pw = survey_weight] 
margins month12
* marginsplot, noci
marginsplot
*graph save "PATH\`var'_1"
}


* END



* Please describe model or hypothesis for code below. 
*This was to plot the regression coefficients instead of predicted values of the dependent variable across the three rounds (NFHS3 NFHS4 combined and CNNS)
reg zwfh mos1-mos11 male i.weight i.agecat_m i.state_comp i.education_years ///
	i.mother_working hindu i.caste rural hhmem i.wealth i.round if round_new ==0 [pw = survey_weight] 
estimates store A
reg zwfh mos1-mos11 male i.weight i.agecat_m i.state_comp i.education_years ///
	i.mother_working hindu i.caste rural hhmem i.wealth if round_new ==1 [pw = survey_weight] 
estimates store B
coefplot A B,  vertical keep(  mos* )  citop recast(connected) label (1 "NFHS" 2 "CNNS")

* Please describe model or hypothesis for code below.
*In order to find the predicted values across the three rounds  NFHS3, NFHS4 and CNNS
reg zwfh ib12.month12##i.round [pw = survey_weight]
margins month12#round
marginsplot, noci

* Please describe model or hypothesis for code below. 
*In order to find the predicted values across the three rounds (NFHS3 NFHS4 combined and CNNS)
reg zwfh ib12.month12##i.round_new [pw = survey_weight]
margins month12#round_new
marginsplot, noci

* Please describe model or hypothesis for code below. 
*In order to find the predicted values across the three rounds (NFHS3 NFHS4 combined and CNNS) for a subsample of rural children
reg zwfh ib12.month12##i.round_new if rural ==1 [pw = survey_weight]
margins month12#round_new
marginsplot, noci

* Please describe model or hypothesis for code below. 
*In order to find the predicted values across the three rounds (NFHS3 NFHS4 combined and CNNS) for a subsample of urban children
reg zwfh ib12.month12##i.round_new if rural ==0 [pw = survey_weight]
margins month12#round_new
marginsplot, noci

* Please describe model or hypothesis for code below. 
*In order to find the predicted values across the three rounds (NFHS3 NFHS4 combined and CNNS) for a subsample of boys
reg zwfh ib12.month12##i.round_new if male ==1 [pw = survey_weight]
margins month12#round_new
marginsplot, noci

* Please describe model or hypothesis for code below. 
*In order to find the predicted values across the three rounds (NFHS3 NFHS4 combined and CNNS) for a subsample of girls
reg zwfh ib12.month12##i.round_new if male ==0 [pw = survey_weight]
margins month12#round_new
marginsplot, noci




