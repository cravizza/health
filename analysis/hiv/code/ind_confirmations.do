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
	rename Week_hiv Week_hiv_co  //hiv date inferred from confirmations
	gen Week_hiv = wofd(date_hiv)
	format %tw Week_hiv Week Week_co Week_hiv
	* Keep people likely to have been confirmed as a result of the observed HIV test
	drop if !mi(Week_hiv_co) & Week_hiv_co<Week_hiv
	drop if !mi(Week_hiv_co) & Week_hiv_co-Week_hiv>=12 //control has jump from 8 to 18 weeks
	assert !mi(Week)
	sort id_b id_m date_pb
	drop date_*
	collapse (mean) control (firstnm) Week_hiv Week_co, by(id_b)
	gen t_hiv_pb = Week_co - Week_hiv
	lab var t_hiv_pb  "Weeks between HIV test and health service"
	isid id_b
	gen confirmed = !mi(Week_co)
	* Test of proportions
	tabulate control confirmed, row
	prtest confirmed, by(control)	
	local pv : di %04.2f 2*(1-normal(abs(r(z))))
	local sh0: di %04.2f r(P_1)*100
	local sh1: di %04.2f r(P_2)*100
    di "\item Share of confirmed in control, 2016 = `sh1'\%, with `r(N_2)' individuals"
	di "\item Share of confirmed in treatment, 2017 = `sh0'\%, with `r(N_1)' individuals"
	di "\item Two-sample test of proportions: p-value `pv'"
	* Run in stata 15 and replace *.10 by %10
	hist t_hiv_pb , ${wb} w(1) by(control) freq // Weeks until confirmation
	tw (hist t_hiv_pb if control==1, ${wb} freq w(1) lc(purple) fc(purple%30)) ///
	   (hist t_hiv_pb if control==0, ${wb} freq w(1) lc(green)  fc(green%30)) ///
	   , xti("Weeks between HIV test and confirmation event") ///
		 yti("Number of confirmation events") xlab(0(2)12) ylab(0(2)10) ///
		 legend(order(1 "Control, 2016" 2 "Treatment, 2017") symx(6)) 
	graph export "../output/conf_weeks_HIV_co.pdf", replace
		
	bys id_b: gen c_post = max(c_lin,c_cvi,c_tar) if t_hiv_pb>=0
	tabulate confirmed c_post if t_hiv_pb==0 // DOES NOT WORK
	hist t_hiv_pb if c_post==1 & inrange(t_hiv_pb,0,12), ${wb} w(1) d frac by(control)
	* Test equality of duiscrete distributions
	preserve
		keep if !mi(Week_co)
		collapse (count) t = id_b, by(t_hiv_pb control)

		reshape wide t, i(t_hiv_p) j(control)
		replace t0=0 if mi(t0)
		//replace t1=0 if mi(t1)
		drop if t_hiv_pb==9 // because it's a zero in the expected frequency (crashes)

		levelsof t_hiv_p , l(lweeks)
		forval x=1/`r(r)' {
			local t_0 = t0[`x']
			local l0  = "`l0' `t_0' "
			local t_1 = t1[`x']
			local l1  = "`l1' `t_1' "
		}
		mgofi `l0' / `l1', mc ks freq nolr nodots
		local pks : di %04.3f `r(p_ksmirnov)'
		di "The p-value of the discrete Kolmorgorov-Smirnov test is `pks' "
		di "Exact p-values for small samples are computed using Monte Carlo simulation"
	restore
end

main

