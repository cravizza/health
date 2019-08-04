/* 
This file creates derived dataset
*/
clear all
set more off

program main
	qui do ..\globals.do
	*enrolled
	foreach filename in  "hiv_fam" "hiv_did_fam" "hiv_es_p_fam" {
		clean_families, filename(`filename')
	}
	clean_confirmations	
	
	use "..\..\..\derived\clean\output\hiv_conf.dta", clear
	clean_pbon_time	
	save ..\temp\hiv_pbon_conf.dta, replace
	
	use "..\..\..\derived\clean\output\hiv_pbon.dta", clear
	merge m:1 id_b id_m using ..\temp\hiv_enr.dta, nogen keep(3)
	clean_pbon_time
	keep if date_hiv==date_pb & n_hiv_test==1
	drop n_hiv_test date_hiv
	create_demo_vars
	create_health_vars
	* Code groups
	merge m:1 code7 using "D:\Personal Directory\Catalina\Google_Drive\Projects\health_shock\codes\dic_codes_all.dta", keep(1 3)
	* Outcomes
	foreach x in "docvisit" "spevisit" "hospital" "prevscre" "labblood" "laburine" "diagther" "surgery" "drcancer" "imaging" {
		gen y_`x' = (code_type == "`x'")	
	}
	save ..\temp\hiv_pbon.dta, replace
	
	keep if i_hiv==1
	drop i_hiv code*
	create_hiv_vars
	merge m:1 id_m id_b month isapre using ..\temp\hiv_fam.dta      , keep(1 3) nogen
	merge m:1 id_m id_b              using ..\temp\hiv_conf_date.dta, keep(1 3) nogen
	gen married = (partner==1) if child!=1 & inlist(civs,1,2)
	replace married = 2 if child!=1 & civs==0
	label define married 0 "Single" 1 "Married" 2 "Unknown"
	label values married married
	replace child = 0 if typben==0
	replace child = . if age_male!=1
	label define child 0 "Main insured" 1 "Dependent"
	label values child child
	save ..\temp\hiv_tests.dta, replace
	
	clean_es_tables, file_name("hiv_did")
	clean_es_tables, file_name("hiv_es_p")
end

capture program drop clean_es_tables
program              clean_es_tables
syntax, file_name(str)
	use "..\..\..\derived\clean\output\\`file_name'.dta", clear
	clean_pbon_time	
	create_demo_vars
	local file_name = "hiv_es_p"
	merge m:1 id_b id_m using ..\temp\\`file_name'_enr.dta, nogen keep(3)
	merge m:1 id_b id_m using ..\temp\\`file_name'_fam.dta, nogen // keep(3)
	if "`file_name'" == "hiv_did" {
		bys id_m id_b: egen date_hivm = min(date_hiv) if date_hiv>=td(${hiv5_Day_R})
	}
	else if "`file_name'" == "hiv_es_p" {
		bys id_m id_b: egen date_hivm = min(date_hiv) if date_hiv>=mdy(month(td(${hiv5_Day_R})),day(td(${hiv5_Day_R})),year(td(${hiv5_Day_R}))-1)
	}
	bys id_m id_b (date_hivm):  replace date_hivm = date_hivm[1] if mi(date_hivm)
	format %td date_hivm
	bys id_m id_b : egen n_hiv_tests = max(n_hiv_test)
	drop if  mi(date_hivm) & control==0
	assert (!mi(date_hivm) & control==0) | (mi(date_hivm) & control==1)
	* Code groups
	merge m:1 code7 using "D:\Personal Directory\Catalina\Google_Drive\Projects\health_shock\codes\dic_codes_all.dta", keep(1 3)
	* Outcomes
	foreach x in "docvisit" "spevisit" "hospital" "prevscre" "labblood" "laburine" "diagther" "surgery" "drcancer" "imaging" "psychias" {
		gen y_`x' = (code_type == "`x'")
	}
	save ..\temp\\`file_name'.dta, replace
end

capture program drop clean_pbon_time
program              clean_pbon_time
	drop  index
	duplicates drop
	decode date, g(temp_date)
	gen date_pb  = date(temp_date,"YMD")
	gen date_hiv = date_pb if code7=="0306169"
	bys id_m id_b isapre month (date_hiv): replace date_hiv = date_hiv[1] if date_hiv==.
	bys id_m id_b isapre month  date_hiv : egen n_hiv_test = total(code7=="0306169")
	format %td date_pb date_hiv date
	gen Week = wofd(date_pb)
	format %tw Week	
	gen weekno = week(dofw(Week))
	gen Month = mofd(date_pb)
	format %tm Month
	gen Quarter = qofd(dofm(Month))
	format %tq Quarter
	gen Calendar_Month = month(dofm(Month))	
	gen Year    = year(dofm(Month))
	drop date temp_date
end

capture program drop create_demo_vars
program              create_demo_vars
	* Gender
	keep if gender!=2
	lab drop gender
	lab def gender 0 "Female" 1 "Male"
	lab val gender gender
	gen male    = 1 if gender==1
	gen female  = 1 if gender==0 & pregnant==0
	lab var male   "Men"
	lab var female "Non-pregnant women"
	* Age groups
	gen age_18_45 = (inrange(age,18,45))
	gen age_20_35 = (inrange(age,20,35))
	local start_list = "18 25 31 41"
	local   end_list = "24 30 40 50"
	gen age_male =.
	gen age_female =.
	local N = `: word count `start_list''
	local age_groups = ""
	forv x = 1(1)`N' {
		local s1: word `x' of `start_list'
		local e1: word `x' of   `end_list'
		local age_groups = `"`age_groups'"' + `" `x' "`s1'_`e1'" "'
		replace   age_male = `x' if gender==1 & inrange(age,`s1',`e1')
		replace age_female = `x' if gender==0 & inrange(age,`s1',`e1')
	}
	capture label drop age_groups
	label define age_groups `age_groups'
	label values age_male    age_groups
	label values age_female  age_groups	
	local start_a_list = "15 20 25 30 35 40 45 50"
	local   end_a_list = "19 24 29 34 39 44 59 60"
	gen age_a_male =.
	gen age_a_female =.
	local N = `: word count `start_list''
	local age_a_groups = ""
	forv x = 1(1)`N' {
		local s1: word `x' of `start_a_list'
		local e1: word `x' of   `end_a_list'
		local age_a_groups = `"`age_a_groups'"' + `" `x' "`s1'_`e1'" "'
		replace   age_a_male = `x' if gender==1 & inrange(age,`s1',`e1')
		replace age_a_female = `x' if gender==0 & inrange(age,`s1',`e1')
	}
	capture label drop age_a_groups
	label define age_a_groups `age_a_groups'
	label values age_a_male    age_groups
	label values age_a_female  age_groups
	* Regions
	gen     proreg_13 = 13 if proreg==13
	replace proreg_13 = 1  if proreg!=13
	replace proreg_13 = .  if proreg==0
	label define proreg_13 13 "Metropolitan region" 1 "Other regions"
	label values proreg_13 proreg_13
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
	bys id_m id_b (date_pb): gen test_n = _n
	gen     int_2ndtest = Week-Week[_n-1] if test_n==2
	egen    test_N      = max(test_n), by(id_m id_b)
	replace test_n      = 3 if test_n>3
	label define test_n 1 "First time" 2 "Second time" 3 "3+"
	label values test_n test_n
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
	assert civs_m==0 if typben!=1
	drop I_conyuge
	* Create dummies at the ind level
	bys id_m month isapre: egen partner_fem = max((gender==2 & (codrel==2 | (codrel==1 & civs==2))))
	replace partner_fem = . if gender==2 | inlist(codrel,0,3,4) | conyuge==0
	gen child = 1 if codrel==3
	gen partner = 1 if civs==2
	* Prepare to merge
	
	if inlist("`filename'","hiv_did_fam","hiv_es_p_fam") {
		keep if control!=9
		preserve
			keep id_m id_b isapre
			duplicates drop
			bys id_m id_b: egen ni_fam = count(isapre)
			//rename isapre isapre_fam
			tempfile isapre_fam
			save `isapre_fam'
		restore
		preserve
			local filen = regexr("`filename'",substr("`filename'",-4,.),"")
			use id_m id_b isapre using "..\..\..\derived\clean\output\\`filen'.dta", clear
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
		keep id_m id_b control partner_fem partner child civs typben codrel region munici dod_m pais_m	
	}
	if "`filename'" == "hiv_fam" {
		keep if hiv==1
		keep id_m id_b month isapre partner_fem partner child civs typben codrel region munici dod_m pais_m	
	}
	save "..\temp\\`filename'.dta", replace
end

capture program drop clean_confirmations
program              clean_confirmations
	use "..\..\..\derived\clean\output\hiv_ges.dta", clear
	drop index
	gen Month = mofd(date(date),"YMD")
	format %tm Month
	duplicates drop
	ds gessol id_reg gesid, not
	duplicates drop `r(varlist)', force
	keep if inlist(event,0) // keep confirmed cases (suspicion=3)
	keep if Month > ym(2012,1)
	gsort id_b id_m Month -date // keep last confirmation of the first month
	duplicates  drop id_b id_m, force
	isid id_m id_b
	rename date conf_date
	keep id_m id_b conf_date
	save ..\temp\hiv_conf_date.dta, replace
end

capture program drop enrolled
program              enrolled
	use "..\..\..\derived\clean\output\hiv_did_enr.dta", clear
	drop index
	duplicates drop
	bys id_m id_b: egen n_m = count(month)
	drop if n_m<24
	/* * Consecutive months
	egen id = group(id_m id_b)
	gen Month = mofd(date(string(month),"YM"))
	format %tm Month
	drop month
	xtset id Month
	tsfill, full
	sort id Month
	bys id (Month) n_m: gen ni = _n
	gen _seq = .
	replace _seq = cond((n_m==. & L.n_m!=.)|(L.n_m==. & n_m!=.), 1, L._seq + 1)
	replace _seq = ni if mi(_seq)
	by id (Month): gen long _spell = cond(_seq, sum(_seq == 1), 0)
	by id: egen _Mspell = max(_spell)
	drop if _Mspell>2 */
	keep id_m id_b 
	duplicates drop
	gen enr = 1
	save ..\temp\hiv_did_enr.dta, replace
	
	use "..\..\..\derived\clean\output\hiv_es_p_enr.dta", clear
	drop index
	duplicates drop
	bys id_m id_b: egen n_m = count(month)
	drop if n_m<24
	keep id_m id_b 
	duplicates drop
	gen enr = 1
	save ..\temp\hiv_es_p_enr.dta, replace
	
	use "..\..\..\derived\clean\output\hiv_enr.dta", clear
	drop index
	bys id_m id_b: egen n_m = count(month) //58.31%=72
	gen enr = (n_m==72)	
	forvalues x=2012/2017 {
		local m_s = `x'*100
		local m_e = (`x'+1)*100
		di "Year `x'"
		bys id_m id_b: egen n_m`x'pre = count(month) if inrange(month,`m_s',`m_e')
		replace n_m`x'pre = 0 if mi(n_m`x'pre)
		bys id_m id_m: egen n_m`x' = max(n_m`x'pre)
		drop n_m`x'pre
	}
	tab enr
	gen enr_7_12 = (inrange(n_m2017,7,12) & inrange(n_m2016,7,12) & inrange(n_m2015,7,12) & inrange(n_m2014,7,12) & inrange(n_m2013,7,12) & inrange(n_m2012,7,12))
	tab enr if enr_7_12==1
	gen enr5 = (n_m2016==12 & n_m2017==12)
	
	drop month n_m2012 n_m2013 n_m2014 n_m2015
	duplicates drop
	save ..\temp\hiv_enr.dta, replace
end

main
