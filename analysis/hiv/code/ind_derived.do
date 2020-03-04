clear all
set more off

program main
	qui do ..\globals.do

	use ..\temp\ind_pbon.dta, clear
	create_hs_events, date_vars(date_pb date_hiv)
	save ..\temp\ind_pbon_hs_events.dta, replace
	
	use  ..\temp\ind_pbon_hs_events.dta, clear
	create_event_vars
	save ..\temp\ind_pbon_event.dta, replace
	
	preserve
		keep if hs_n_nc==1 & hs_hiv_t==0 & all==1
		isid id_b
		keep id_b date_hiv control gender age_all* *bund* married income_am ti* civs*
		save ..\temp\ind_event_idb.dta, replace
		drop id_b date_hiv
		save ..\temp\ind_event.dta, replace
	restore
	
	use ..\temp\ind_pbon_event.dta, clear
	create_balanced_panel
	save ..\temp\ind_did.dta, replace

end

capture program drop create_balanced_panel
program              create_balanced_panel	
	assert !mi(date_hiv) & !mi(id_b) & !mi(id_m)
	assert inlist(control,0,1)
	* New vars
	encode region, g(regionid)
	encode munici, g(municiid)
	bys id_m id_b date_pb: egen n_pb = count(isapre)
	replace civs=4 if inlist(civs,3)
	gen Week_hiv   = wofd(hs_hiv_start) //date_hiv
	format %tw Week_hiv
	gen Month_hiv  = mofd(hs_hiv_start) //date_hiv
	format %tm Month_hiv
	* Sample
	drop age_*male code*
	drop if hs_hiv_t==0 // exclude any servs on the event of the HIV test
	keep if !mi(age_all)
	* Balanced panel
	local controls = " age* ti* civs N regionid gender "
	local y_vars = "y_docvisit     y_spevisit          y_prevscre        y_diagther " ///
				 + "y_surgery      y_hospital          y_examslab        y_psychias"
	local ylabs = `""Doctor visit" "Specialist visit"  "Preventive care" "Diagnosis/therapy" "' ///
				+ `""Surgery"      "Hospitalization"   "Lab tests"       "Mental health""'
	foreach v of varlist `y_vars' { 
		gen max_`v' = `v'
		gen sum_`v' = `v'
		drop `v'
	}
	sort id_b id_m date_pb
	drop date_*
	collapse (sum) sum_*  (max) max_* (mean) control (firstnm) `controls' Month* Week_hiv ///
		, by(id_m id_b Week)
	assert inlist(control,0,1) & !mi(id_b) & !mi(id_m)
	isid id_b Week
	qui xtset id_b Week
	tsfill, full
	xtset id_b Week
	foreach x of varlist sum_* max_* {
		replace `x' = 0 if mi(`x')
	}
	bys id_b (Week): carryforward control age* ti* civs N regionid gender id_m Week_hiv, replace
	gen nWeek = -Week
	bys id_b (nWeek): carryforward control age* ti* civs N regionid gender id_m Week_hiv, replace back
	* Relative time variable
	gen post_Week   = Week - Week_hiv 	//gen post_Month  = Month - Month_hiv
	assert !mi(Week)
	gen post_static = (Week > Week_hiv) if inrange(post_Week,-12,12) //date_pb!=date_hiv & 
end

capture program drop create_event_vars
program              create_event_vars
	* Create dummies
	gen c_lin = inlist(code7,${code_lin})
	gen c_std = inlist(code7,${code_std1}) | inlist(code7,${code_std2})
	gen c_doc = inlist(code_type,"docvisit","spevisit") | inlist(code7,${code_gyn},"0307011") //venosa
	gen c_chk = inlist(code7,${code_pan}) | inlist(code7,${code_pap}) | inlist(code7,${code_psa}) |  inlist(code_type,"prevscre")
	gen c_oth = (c_std==0 & c_chk==0 & c_doc==0 & code7!=${code_hiv})
	gen c_hiv = code7==${code_hiv}
	gen c_not = (hs_hiv_t==0 & hs_n==1)
	gen c_hos = (code_type=="hospital")
	* Indicator for service use a year before HIV test (LYI_*) and at HIV test event (I_*)
	foreach x of varlist c_* {
		local subs_`x' = substr("`x'",-3,.)
		gen pre_`subs_`x'' = (`x'==1 & inrange(date_pb,hs_hiv_start-365,hs_hiv_start-1))
		if "`x'"=="c_not" {
			replace pre_`subs_`x'' = 1 if `x'==1 & pre_`subs_`x''==0
		}
		bys id_b (hs_n  date_pb): egen LYI_`subs_`x'' = max(pre_`subs_`x'')
		drop pre_`subs_`x''
		bys id_b  hs_n (date_pb): egen   I_`subs_`x'' = max(`x')
		drop `x'
	}	
	* Create indicators for bundle of services (LYbund_* and bund_*) and label	
	gen       bund_hiv = (  I_std==0 &   I_chk==0 & I_oth==0 & hs_hiv_t==0)
	lab var   bund_hiv "HIV test only"
	gen     LYbund_not = (LYI_not==1)
	lab var LYbund_not "Not used"
	gen       bund_std = (  I_std==1 &   I_chk==0 & hs_hiv_t==0)
	gen     LYbund_std = (LYI_std==1 | LYI_hiv==1) & LYI_chk==0 
	lab var   bund_std "STDs tests"
	lab var LYbund_std "STDs tests"
	gen       bund_chk = (  I_std==0 &   I_chk==1 & hs_hiv_t==0)
	gen     LYbund_chk = (LYI_std==0 & LYI_chk==1 &  LYI_hiv==0)
	lab var   bund_chk "Check-up tests"
	lab var LYbund_chk "Check-up tests"
	gen       bund_s_c = (  I_std==1 &   I_chk==1 & hs_hiv_t==0)
	gen     LYbund_s_c = (LYI_std==1 & LYI_chk==1 &  LYI_hiv==1)
	lab var   bund_s_c "STDs & check-up"
	lab var LYbund_s_c "STDs & check-up"
	gen       bund_oth = (  I_std==0 &   I_chk==0 &   I_oth==1 & hs_hiv_t==0)
	gen     LYbund_oth = (LYI_std==0 & LYI_chk==0 & LYI_oth==1 &  LYI_hiv==0)
	lab var   bund_oth "Other" 
	lab var LYbund_oth "Other"
	gen       bund = 1 if   bund_hiv==1
	gen     LYbund = 1 if LYbund_not==1
	replace   bund = 2 if   bund_std==1
	replace LYbund = 2 if LYbund_std==1
	replace   bund = 3 if   bund_chk==1
	replace LYbund = 3 if LYbund_chk==1
	replace   bund = 4 if   bund_s_c==1
	replace LYbund = 4 if LYbund_s_c==1
	lab define bund 1 "`:var lab bund_hiv'" 2 "`:var lab bund_std'" 3 "`:var lab bund_chk'" 4 "`:var lab bund_s_c'"
	lab values bund   bund
	lab define LYbund 1 "`:var lab LYbund_not'" 2 "`:var lab bund_std'" 3 "`:var lab bund_chk'" 4 "`:var lab bund_s_c'"
	lab values LYbund LYbund
	lab var   bund "Bundle of health services used"
	lab var LYbund "Health services use previous year"
	* Income
	sum ti if hs_n_nc==1 & hs_hiv_t==0 & all==1 & inrange(ti,1,1850000), det
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
	* Age, civs, and income group dummies
	foreach v in "tibin" "age_all" "civs" {
		levelsof `v', l(list_`v')
		local Na `: word count `list_`v'''
		forv x = 1(1)`Na' {
			gen     `v'_`x' = (`v'==`x')
			lab var `v'_`x' "`:lab (`v') `x''"
		}
	}	
	* Tables
	foreach x of varlist I_* {
		table control `x' if hs_n_nc==1 & date_pb==date_hiv & all==1
	}		
end


capture program drop create_hs_events
program              create_hs_events	
syntax, date_vars(varlist)
	preserve
		bys id_m id_b date_pb: egen seq = seq()
		keep if seq==1 //one obs per date
		keep id_m id_b date_* control
		isid date_pb id_b
		bys id_b      (date_pb): gen hs_days_pre = date_pb - date_pb[_n-1]
		bys id_b      (date_pb): gen       n1 = _n
		bys id_b      (date_pb): replace   n1 = n1[_n-1] if inrange(hs_days_pre,0,10) //rolling replacement all in a group
		bys id_b n1   (date_pb): egen hs_n_nd = seq() //consecutive numbering of each date in event
		bys id_b               : gen     hs_n = sum(hs_n_nd) if hs_n_nd==1 //consecutive numbering of events
		bys id_b      (date_pb): replace hs_n = hs_n[_n-1]   if hs_n_nd!=1 //fill hs_n
		drop n1
		bys id_b hs_n (date_pb): egen hs_start = min(date_pb)
		bys id_b hs_n (date_pb): egen hs_end   = max(date_pb)
		format %td hs_start hs_end
		gen hs_days = hs_end - hs_start
		lab var hs_days "Number of days of health event"
		* Tag if HIV test health service event starts before the campaign date
		gen     _I = (hs_start>=td(${hiv5_Day_R}))     if date_pb==date_hiv & control==0
		replace _I = (hs_start>=td(${hiv5_Day_R})-365) if date_pb==date_hiv & control==1
		* Tag if HIV test is taken more than r(p99) days after start of health service event
		gen _d = date_pb - hs_start if date_pb==date_hiv
		sum _d if _I==1 & date_pb==date_hiv, det //p99=21days=3weeks
		replace _I = 0 if _d>r(p99) & _I==1 & date_pb==date_hiv
		drop _d
		bys id_b (_I): replace _I = _I[1] if mi(_I)
		table control _I if date_pb==date_hiv
		* Run in stata 15 and replace *.10 by %10
		local c16: di td(${hiv5_Day_R})-365
		local c17: di td(${hiv5_Day_R})
		tw (hist hs_start if _I==1 & date_pb==date_hiv, ${wb} w(1) lc(green) fc(green*.10)) ///
		   (hist hs_end   if _I==1 & date_pb==date_hiv, ${wb} w(1) lc(red)   fc(red*.10)) ///
		   (pci 0 `c16' .02 `c16',lc(red) ) ( pci 0 `c17' .02 `c17',lc(red)),  legend(off)
		
		sum  hs_days if hs_n_nd==1 & _I==1, det
		hist hs_days if hs_n_nd==1 & _I==1 & hs_days<r(p99), ${wb} w(1) //in general
		hist hs_days if hs_n_nd==1 & _I==1 & date_pb==date_hiv, ${wb} w(1) //hiv test event
		drop hs_n_nd
		* Events relative to HIV test event
		gen hs_hiv = hs_n if date_pb==date_hiv
		bys id_b (hs_hiv): replace hs_hiv = hs_hiv[1] if mi(hs_hiv)
		assert !mi(hs_hiv)
		sort id_b date_pb
		gen hs_hiv_t = hs_n - hs_hiv
		drop hs_days_pre hs_hiv
		bys id_b (hs_n date_pb): egen hs_hiv_start = min(cond(hs_hiv_t==0,hs_start,.))
		format %td hs_hiv_start
		tempfile hs_events
		save `hs_events'
	restore
	merge m:1 id_b id_m `date_vars' using `hs_events', assert(3) nogen
	bys id_b hs_n (date_pb code7): egen hs_n_nc = seq() //consecutive numbering of each claim in event
	keep if _I==1
	drop _I
end

main
