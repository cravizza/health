clear all
set more off

program main
	qui do ..\..\confirmations\globals.do

	use  ..\temp\ind_pbon_hs_events.dta, clear
	merge m:1 id_b using "..\..\confirmations\temp\confirmations_list.dta", keep(1 3) nogen
	* Create vars
	gen c_tar = inlist(code7,${code_tar})
	gen c_cvi = inlist(code7,${code_cvi})
	gen c_lin = inlist(code7,${code_lin})
	rename Week_hiv Week_hiv_co
	gen Week_hiv = wofd(date_hiv)
	format %tw Week_hiv Week Week_co Week_hiv
	* Keep people likely to have been confirmed as a result of the HIV test
	drop if !mi(Week_hiv_co) & Week_hiv_co<Week_hiv
	drop if !mi(Week_hiv_co) & Week_hiv_co-Week_hiv>12 //control has jump from 8 to 18 weeks
	assert !mi(Week)
	sort id_b id_m date_pb
	drop date_*
	collapse  (max) c_* (mean) control (firstnm) Week_hiv Week_co, by(id_b Week)
	gen t_hiv_pb = Week - Week_hiv
	lab var t_hiv_pb  "Weeks between HIV test and health service"
	isid id_b Week
	gen confirmed = !mi(Week_co)
	bys id_b (Week): egen seq = seq()
	* Test of proportions
	tabulate control confirmed if seq==1, row
	prtest confirmed if seq==1, by(control)	
	local pv : di %04.2f 2*(1-normal(abs(r(z))))
	local sh0: di %04.2f r(P_1)*100
	local sh1: di %04.2f r(P_2)*100
    di "\item Share of confirmed in control, 2016 = `sh1'\%, with `r(N_2)' individuals"
	di "\item Share of confirmed in treatment, 2017 = `sh0'\%, with `r(N_1)' individuals"
	di "\item Two-sample test of proportions: p-value `pv'"
	* Run in stata 15 and replace *.10 by %10
	hist t_hiv_pb  if Week_co==Week, ${wb} w(1) by(control) // Weeks until confirmation
	tw (hist t_hiv_pb if control==1 & Week_co==Week, ${wb} w(1) lc(green)  fc(green%30)) ///
	   (hist t_hiv_pb if control==0 & Week_co==Week, ${wb} w(1) lc(purple) fc(purple%30)) ///
	   , legend(off) xti("Weeks between HIV test and confirmation event")
	graph export "../output/conf_weeks_HIV_co.pdf", replace
		
	bys id_b: gen c_post = max(c_lin,c_cvi,c_tar) if t_hiv_pb>=0
	tabulate confirmed c_post if t_hiv_pb==0 // DOES NOT WORK
	hist t_hiv_pb if c_post==1 & inrange(t_hiv_pb,0,12), ${wb} w(1) d frac by(control)
end

main

