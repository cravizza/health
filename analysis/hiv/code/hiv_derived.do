/* 
This file creates derived dataset
*/
clear all
set more off

program main
	qui do ..\globals.do
	foreach filename in  "agg_fam" "ind_fam" {
		clean_families, filename(`filename')
	}
	
	clear
	
	use "..\..\..\derived\clean\output\agg_pbon.dta", clear
	merge m:1 id_m id_b month isapre using ..\temp\agg_fam.dta, keep(1 3) nogen
	merge m:1 code7 using "D:\Personal Directory\Catalina\Google_Drive\Projects\health_shock\codes\dic_codes_all.dta", keep(1 3)
	* Clean
	qui clean_pbon_time
	//keep if date_hiv==date_pb & n_hiv_test==1
	//drop n_hiv_test date_hiv
	qui create_demo_vars
	qui create_health_vars
	save ..\temp\agg_pbon.dta, replace //hiv_pbon.dta
	
	keep if i_hiv==1
	drop i_hiv code*
	isid id_b date_pb
	qui create_hiv_vars
	save ..\temp\agg_hiv.dta, replace //hiv_tests
	assert date_pb==date_hiv
	keep id_b date_hiv initiation less_than_yr test_n4
	save ..\temp\agg_all_tests.dta, replace 

	clear
	
	use "..\..\..\derived\clean\output\ind_pbon.dta", clear
	merge m:1 id_b id_m using ..\temp\ind_fam.dta, nogen // keep(3)
	merge m:1 code7 using "D:\Personal Directory\Catalina\Google_Drive\Projects\health_shock\codes\dic_codes_all.dta", nogen keep(1 3)
	* Clean
	qui clean_pbon_time	
	qui create_demo_vars
	qui create_health_vars
	drop tests1 tests2
	bys id_m id_b: egen date_hivm = min(date_hiv) if control==0 & date_hiv>=td(${hiv5_Day_R})
	bys id_m id_b: egen date_hivC = min(date_hiv) if control==1 & date_hiv>=mdy(month(td(${hiv5_Day_R})),day(td(${hiv5_Day_R})),year(td(${hiv5_Day_R}))-1)
	replace date_hivm = date_hivC                 if control==1 & date_hiv>=mdy(month(td(${hiv5_Day_R})),day(td(${hiv5_Day_R})),year(td(${hiv5_Day_R}))-1)
	bys id_m id_b (date_hivm):  replace date_hivm = date_hivm[1] if mi(date_hivm)
	format %td date_hivm
	drop date_hivC
	assert !mi(date_hivm)
	drop date_hiv dod_m pais_m code2
	rename date_hivm date_hiv
	lab define control 0 "Treatment, 2017" 1 "Control, 2016"
	lab values control control
	save ..\temp\ind_pbon.dta, replace
end

capture program drop clean_pbon_time
program              clean_pbon_time
	drop  index
	duplicates drop
	todate date, p(yyyymmdd) f(%td) g(date_pb)
	todate date if code7=="0306169", p(yyyymmdd) f(%td) g(date_hiv)
	duplicates drop id_m id_b date_pb code7, force
	bys id_m id_b isapre date_pb (date_hiv): replace date_hiv = date_hiv[1] if date_hiv==.
	bys id_m id_b isapre          date_hiv : egen n_hiv_test = total(code7=="0306169")
	bys id_m id_b isapre: egen N_hiv_test = total(code7=="0306169")
	gen Week = wofd(date_pb)
	format %tw Week	
	gen Month = mofd(date_pb)
	format %tm Month
	gen Quarter = qofd(dofm(Month))
	format %tq Quarter
	gen weekno  = week(dofw(Week))
	gen monthno = month(dofm(Month))	
	gen Year    = year(dofm(Month))
	drop date
end

capture program drop create_demo_vars
program              create_demo_vars
	* Gender
	keep if gender!=2
	lab drop gender
	lab def gender 0 "Female" 1 "Male"
	lab val gender gender
	gen male    = 1 if gender==1
	gen female  = 1 if gender==0
	lab var male   "Men"
	lab var female "Non-pregnant women"
	* Age groups 1
	gen age_18_45 = (inrange(age,18,45))
	gen age_20_35 = (inrange(age,20,35))
	local start_list = "18 25 31 41"
	local   end_list = "24 30 40 50"
	gen age_male =.
	gen age_female =.
	gen age_all =.
	local N = `: word count `start_list''
	local age_groups = ""
	forv x = 1(1)`N' {
		local s1: word `x' of `start_list'
		local e1: word `x' of   `end_list'
		local age_groups = `"`age_groups'"' + `" `x' "`s1'_`e1'" "'
		replace age_male   = `x' if inrange(age,`s1',`e1') & male==1
		replace age_female = `x' if inrange(age,`s1',`e1') & female==1
		replace age_all    = `x' if inrange(age,`s1',`e1') & (male==1|female==1)
	}
	capture label drop age_groups
	label define age_groups `age_groups'
	label values age_male    age_groups
	label values age_female  age_groups
	label values age_all     age_groups
	gen all = !mi(age_all)
	keep if inrange(age,12,70)
	* Age groups 2
	local start_a_list = "15 20 25 30 35 40 45 50"
	local   end_a_list = "19 24 29 34 39 44 49 60"
	gen age_a_male =.
	gen age_a_female =.
	local N_a = `: word count `start_a_list''
	local age_a_groups = ""
	forv x = 1(1)`N_a' {
		local s2: word `x' of `start_a_list'
		local e2: word `x' of   `end_a_list'
		local age_a_groups = `"`age_a_groups'"' + `" `x' "`s2'_`e2'" "'
		replace   age_a_male = `x' if gender==1 & inrange(age,`s2',`e2')
		replace age_a_female = `x' if gender==0 & inrange(age,`s2',`e2')
	}
	capture label drop age_a_groups
	label define age_a_groups `age_a_groups'
	label values age_a_male    age_a_groups
	label values age_a_female  age_a_groups
	* Regions
	gen     proreg_13 = 13 if proreg==13
	replace proreg_13 = 1  if proreg!=13
	replace proreg_13 = .  if proreg==0
	label define proreg_13 13 "Metropolitan region" 1 "Other regions"
	label values proreg_13 proreg_13
	* Civs
	replace child = 0 if typben==0
	replace child = . if age_all!=1
	label define child 0 "Main insured" 1 "Dependent"
	label values child child
	gen married = (partner==1) if child!=1 & inlist(civs,1,2)
	replace married = 2 if child!=1 & civs==0
	replace married = 0 if child==1
	label define married 0 "Single" 1 "Married" 2 "Unknown"
	label values married married
	* Income
	qui sum ti if all==1, det
	gen income_am = (ti>r(p50))
	label define income_am 0 "Below median" 1 "Above median"
	label values income_am income_am
end

capture program drop create_health_vars
program              create_health_vars
	gen code4 = substr(code7,1,4)
	gen i_hiv = (code7=="0306169")
	local list_codes1 = "0301045 0306042 0309022"
	local list_codes2 = "0302075 0302076 0302034"
	local list_names1 = "hemogra syphili urinaly"
	local list_names2 = "metabol liverpa lipidpa"
	local N = `: word count `list_codes1''
	local list_labs = ""
	forv i = 1/2 {
		gen tests`i' = .
		forv x = 1(1)`N' {
			local c`i': word `x' of `list_codes`i''
			local n`i': word `x' of `list_names`i''
			replace tests`i' = `x' if code7=="`c`i''"
			gen i_`n`i'' = (code7=="`c`i''")
		}
	}
	label define tests1 1 "Hemogram (CBC)" 2 "Syphilis (VDRL)" 3 "Urine analysis"
	label values tests1 tests1
	label define tests2 1 "Metabolic panel" 2 "Liver panel" 3 "Lipid panel"
	label values tests2 tests2
		* Outcomes
	foreach x in "docvisit" "spevisit" "hospital" "prevscre" "labblood" "laburine" "diagther" "surgery" "drcancer" "imaging" "psychias" {
		gen y_`x' = (code_type == "`x'")
	}
	gen y_examslab = (code_group=="examslab")
end

capture program drop create_hiv_vars
program              create_hiv_vars	
	* Copay groups
	gen copay_gr = 1 if copay==0
	forval i = 0/1 {
		qui sum copay if copay!=0 & gender==`i', det
		replace copay_gr = 2 if gender==`i' & inrange(copay,`r(p1)',`r(p50)')
		replace copay_gr = 3 if gender==`i' & inrange(copay,`r(p50)',`r(p99)')
	}
	label define copay_gr 1 "Zero" 2 "Non-0 below median" 3 "Non-0 above median"
	label values copay_gr copay_gr
	* Number of tests
	bys id_m (date_pb): gen test_n = _n
	gen test_n4 = cond(test_n>4,4,test_n)
	label define test_n4 1 "First" 2 "Second" 3 "Third" 4 "4+"
	label values test_n4 test_n4
	gen     int_2ndtest = Week-Week[_n-1] if test_n==2
	egen    test_N      = max(test_n), by(id_b)
	replace test_n      = 3 if test_n>3
	label define test_n 1 "First time" 2 "Second time" 3 "3+"
	label values test_n test_n
	bys id_b (date_pb): gen days_last_test = date_pb - date_pb[_n-1]
	gen less_than_yr = (days_last_test<365 & !mi(days_last_test))
	drop days_last_test
	label define less_than_yr 0 "No recent test" 1 "Less than a year"
	label values less_than_yr less_than_yr
	gen initiation = (test_n==1)
	label define initiation 0 "Recurring" 1 "Initiation"
	label values initiation initiation
end

capture program drop clean_families
program              clean_families
syntax, filename(string)
	use "..\..\..\derived\clean\output\\`filename'.dta", clear
	drop index
	* Fix main insured
	replace codrel = 1 if id_m==id_b & codrel!=1
	replace typben = 1 if id_m==id_b & typben!=1
	assert codrel==1 & typben==1 if id_b==id_m
	* Fix beneficiaries
	replace typben=2 if id_m!=id_b & typben==1 & codrel==3 //son isn't main insured
	replace typben=2 if inlist(typben,0,3)
	gen yob_m = int(dob/10000) if typben==1
	gen yob_b = int(dob/10000) if typben!=1
	bys id_m month (yob_m): replace yob_m = yob_m[1] if yob_m==.
	assert id_b==id_m if mi(yob_b)
	gen age_dif = yob_m - yob_b
	forval i = 2/4 {
		sum age_dif          if typben==2 & codrel==`i', det
		replace codrel = `i' if typben==2 & codrel==0 & inrange(age_dif,`r(p5)',`r(p95)')
		replace codrel = `i' if typben==2 & codrel==1 & inrange(age_dif,`r(p5)',`r(p95)')
	}
	replace codrel=0 if id_b!=id_m & codrel==1
	assert codrel!=1 & typben!=1 if id_b!=id_m
	* Create vars
	bys id_m id_b month       : egen n_isa  = count(month)
	bys id_m      month isapre: egen n_fam  = count(month)
	bys id_m      month isapre: egen n_pare = total(codrel==4)
	bys id_m      month isapre: egen n_kids = total(codrel==3)
	bys id_m      month isapre: egen n_cony = total(codrel==2)
	bys id_m      month isapre: egen n_m    = total(codrel==1)
	assert inlist(n_m,0,1)
	gen n_dif = n_fam - n_kids - n_cony - n_m - n_pare
	* Civil status
	gen I_conyuge = (codrel==2 | civs_m==2)
	egen  conyuge = max(I_conyuge), by(id_m month isapre)
	gen      civs = civs_m if typben==1
	replace  civs = 2 if (conyuge==1 & codrel==1) | codrel==2 
	replace  civs = 2 if indcom==1 & civs==0
	replace  civs = 1 if codrel==3
	assert civs_m==0 if typben!=1
	drop I_conyuge
	* Create dummies at the ind level
	bys id_m month isapre: egen partner_fem = max((gender==2 & (codrel==2 | (codrel==1 & civs==2))))
	replace partner_fem = . if gender==2 | inlist(codrel,0,3,4) | conyuge==0
	gen child = 1 if codrel==3
	gen partner = 1 if civs==2
	* Prepare to merge
	
	if inlist("`filename'","ind_fam") {
		keep if control!=9
		preserve
			keep id_m id_b isapre
			duplicates drop
			bys id_m id_b: egen ni_fam = count(isapre)
			tempfile isapre_fam
			save `isapre_fam'
		restore
		preserve
			local file_pb = regexr("`filename'","fam","pbon")
			use id_m id_b isapre using "..\..\..\derived\clean\output\\`file_pb'.dta", clear
			duplicates drop
			bys id_m id_b: egen ni_pb = count(isapre)
			merge 1:1 id_m id_b isapre using `isapre_fam'			
			bys id_m id_b: egen n_pb  = max(cond(ni_pb ,ni_pb,-99))
			bys id_m id_b: egen n_fam = max(cond(ni_fam,ni_fam,-99))
			forval x=1/3 {
				bys id_m id_b: egen _m`x' = max(cond(_merge==`x',1,0))
			}
			gen _tag = (n_fam==2 & _m3 & _m2 & _merge!=3)
			drop if _tag
			gen     isapre_ok = isapre if n_fam==2 & n_pb==1
			replace isapre_ok = 99 if n_f==2 & n_p>1
			keep id_m id_b isapre_ok
			duplicates drop
			isid id_m id_b
			tempfile isapre_pb
			save `isapre_pb'
		restore
		
		merge m:1 id_b id_m using `isapre_pb', keep(1 3) nogen
		bys id_m id_b: egen n_i = count(isapre)
		assert inlist(n_i,1,2)
		keep if n_i==1 | (n_i==2 & isapre==isapre_ok & !mi(isapre_ok))
		isid id_m id_b
		keep id_m id_b control salaried ti partner_fem partner child civs typben codrel region munici dod_m pais_m	
	}
	if "`filename'" == "agg_fam" {
		keep if hiv==1
		keep id_m id_b month isapre salaried ti partner_fem partner child civs typben codrel region munici dod_m pais_m	
	}
	save "..\temp\\`filename'.dta", replace
end

main
