/* 
This file creates derived dataset
*/
clear all
set more off

program main
	qui do ..\globals.do
	foreach filename in  "predict_fam" {
		clean_families, filename(`filename')
	}
	
	use ..\temp\predict_fam.dta, clear
	keep id_m id_b
	sort id_m id_b
	duplicates drop id_b, force
	tempfile add_idm
	save `add_idm'
	
	use ..\temp\predict_fam.dta, clear
	sort id_m id_b
	duplicates drop id_b, force	
	merge 1:1 id_b id_m using `add_idm', keep(3) nogen
	tempfile predict_fam
	save `predict_fam'
	
	use ..\temp\ind_fam.dta, clear
	keep if control==0
	tempfile treat_fam
	save `treat_fam'
	
	use "..\..\..\derived\clean\output\predict_idb.dta", clear
	merge m:1 id_b      using `add_idm', keep(3) nogen
	merge m:1 id_b id_m using `predict_fam', keep(3) nogen
	merge m:1 id_b id_m using `treat_fam', keep(1 3) nogen
	rename gender gender_num
	replace predict=0 if mi(predict)
	merge m:1 id_b predict     using ..\..\..\derived\clean\output\predict_ly0.dta, keep(1 3) nogen
	drop index
	rename predict campaign
	replace campaign=0 if mi(campaign)
	isid id_b campaign
	lab define campaign 1 "2017, campaign" 0 "2016, no campaign"
	lab values campaign campaign
	
	foreach v of varlist I_* {
		replace `v' = 0 if mi(`v')
	}
	drop gender
	rename gender_num gender
	
	save ..\temp\predict_temp.dta, replace
	use  ..\temp\predict_temp.dta, clear
	
	create_demo_vars
	
	* Income
	sum ti if inrange(ti,1,1850000), det
	gen     tibin = 1 if ti==0
	replace tibin = 2 if inrange(ti,`r(min)',`r(p50)')
	replace tibin = 3 if inrange(ti,`r(p50)',`r(max)')
	replace tibin = 4 if ti>`r(max)'
	lab define tibin 1 "Zero" 2 "Below median" 3 "Above median" 4 "Max TI and above"
	lab values tibin tibin
	* Civs
	replace civs = 3 if civs==4
	replace civs = 4 if inlist(civs,.,0)
	lab define civs 1 "Single" 2 "Married" 3 "Other" 4 "Unknown"
	lab values civs civs
	
	* New vars
	encode region, g(regionid)
	encode munici, g(municiid)
	replace civs=4 if inlist(civs,3)
	
	* Regression
	logit tester I_*  i.civs i.regionid i.tibin i.age_all i.gender if campaign==0
	capture drop p_tester
	predict p_tester
	lab var p_tester "Testers' estimated probability of getting HIV test"
	qui sum p_tester  if tester==1
	local rM = ceil(`r(max)'/0.01)*0.01
	hist p_tester if tester==1, by(campaign, note("")) scheme(s1color) subtitle(, fcolor(white)) ///
		 xlab(0(0.04)`rM') xsize(8)
	graph export ..\output\predict_tester.pdf, replace
	cquantile p_tester if tester==1, by(campaign) gen(pt_0 pt_1)
	qui sum pt_1
	local rM = ceil(`r(max)'/0.01)*0.01
	qqplot pt_0 pt_1, mc(midgreen) xsize(5) ysize(5) ${wb} xlab(0(0.04)`rM') ylab(0(0.04)`rM')
	graph export ..\output\predict_tester_qq.pdf, replace
	ksmirnov p_tester if tester==1 & p_tester<0.054, by(campaign) //99%sample
	local r_p: di %5.4f `r(p)'
	local r_D: di %5.4f `r(D)'
	di "Two-sample Kolmogorov-Smirnov test for equality of distribution functions: p-value = `r_p'"
	di "The largest difference between the distribution functions in any direction is `r_D'"
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


capture program drop create_demo_vars
program              create_demo_vars
	* Gender
	lab drop gender
	lab def gender 0 "Female" 1 "Male"
	lab val gender gender
	gen male    = 1 if gender==1
	gen female  = 1 if gender==2
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

main


