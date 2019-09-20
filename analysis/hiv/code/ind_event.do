/*
This code follows: https://stats.idre.ucla.edu/stata/faq/how-can-i-make-a-bar-graph-with-error-bars/
meanwrite = b_mean (for control 1 and 2)
sesrace   = `v'_tc // to position the bars 
race      = `v'
hiwrite   = b_ci_u
lowrite   = b_ci_l
https://www.researchgate.net/post/How_can_I_show_significant_differences_in_the_proportion_of_a_binary_variable_between_more_than_2_categories
*/
clear all
set more off

program main
	qui do ..\globals.do
	
	* Distribution trend
	use ..\temp\ind_pbon.dta, clear
	keep if date_pb==date_hiv & all==1
	drop code* copay pro* typreg isapre planty date_hiv
	duplicates drop
	duplicates drop id_b, force
	isid id_b
	qui sum ti, det
	egen tibin = cut(ti), at(`r(p1)'(50000)`r(p99)')
	qui sum tibin
	replace tibin = `r(max)' if !mi(ti) & ti>2800000
	gen tibin2 = tibin if inrange(tibin,50001,1850000) // 74.3 UF 2016 ~ 1904234.7 CLP
	lab var tibin  "Taxable income, monthly CLP"
	lab var tibin2 "Taxable income, monthly CLP"
	trend_by_var, by_var(age)
	trend_by_var, by_var(tibin)
	trend_by_var, by_var(tibin2)
	
	* Bar graphs
	use ..\temp\ind_event.dta, clear
	sort control
	replace control=2 if control==0
	label define control 0 "" 2 "`:lab (control) 0'", modify
	local list_dummies_bund = "bund_hiv bund_std bund_chk bund_s_c"
	local list_dummies_LYbund = "LYbund_not LYbund_std LYbund_chk LYbund_s_c"
	local list_dummies_age_all = "age_all_1 age_all_2 age_all_3 age_all_4"
	local list_dummies_tibin   = "  tibin_1   tibin_2   tibin_3   tibin_4"
	
	foreach varname in "bund" "LYbund" "age_all" "tibin" {
		bar_graph, v(`varname') list_dummies_v(`list_dummies_`varname'')
	}
end

capture program drop trend_by_var
program trend_by_var
syntax, by_var(str)	
	preserve
		collapse (count) tst=gender if !mi(`by_var'), by(`by_var' control)
		egen to_tst = total(tst), by(control)
		gen  sh_tst = tst/to_tst
		lab var sh_tst "Share of testers"
		qui sum sh_tst
		
		tw (connect sh_tst `by_var' if control==1, mc(purple)   lc(purple)   lp(dash)) ///
		   (connect sh_tst `by_var' if control==0, mc(midgreen) lc(midgreen) lp(longdash)) ///
			, ${wb} legend(order(1 "2016" 2 "2017") symx(6) c(2)) 
			graph export "..\output\ind_sh_`by_var'.pdf", replace
	restore
end

capture program drop bar_graph
program              bar_graph
syntax, v(varname) list_dummies_v(str) [restr(str) add_fn(str)]
	preserve
		capture keep if `restr'
		gen b_mean = .
		gen b_ci_u = .
		gen b_ci_l = .
		gen b_N = .
		gen b_pv = .
		levelsof `v', l(list_`v')
		foreach x in `list_`v'' {
			local I_v: word `x' of `list_dummies_v'
			di "_______________________________________________________________________________________"
			di "_______________________________________________________________________________________"
			di " --- `x'. `I_v' : `:lab (`v') `x''"
			forv c = 0/1 {
				local c1 = `c' + 1
				local restr = " if control==`c1'"
				qui ci `I_v' `restr', binomial
				qui replace b_mean = r(mean) `restr' & `v'==`x'
				qui replace b_ci_u = r(ub)   `restr' & `v'==`x'
				qui replace b_ci_l = r(lb)   `restr' & `v'==`x'
				qui replace    b_N = r(N)    `restr' & `v'==`x'
			}
			prtest `I_v', by(control)
			local pv_`x' : di %5.4f 2*(1-normal(abs(r(z))))
			qui replace b_pv = 2*(1-normal(abs(r(z)))) if `v'==`x' //get pv from z
		}
		gen     `v'_tc = control     if `v'==1
		replace `v'_tc = control + 3 if `v'==2
		replace `v'_tc = control + 6 if `v'==3
		replace `v'_tc = control + 9 if `v'==4

		keep control* b_* `v'_tc `v'
		duplicates drop
		qui sum b_mean
		local rmax = ceil(r(max)*10)/10
		local rtic = `rmax'/4

		twoway (bar b_mean `v'_tc if control==1, col(purple)) ///
			   (bar b_mean `v'_tc if control==2, col(green)) ///
			   (rcap b_ci_u b_ci_l `v'_tc, col(black)), ///
			   ${wb} ylab(0(`rtic')`rmax') ///
			   legend(row(1) order(1 "`:lab (control) 1'" 2 "`:lab (control) 2'")) ///
			   xlab(1.5 `""`:lab (`v') 1'" "[`pv_1']""'  4.5 `""`:lab (`v') 2'" "[`pv_2']""' ///
					7.5 `""`:lab (`v') 3'" "[`pv_3']""' 10.5 `""`:lab (`v') 4'" "[`pv_4']""', noticks) ///
			   ytitle("Share") xtitle("")
		graph export "..\output\ind_event_bar_`v'`add_fn'.pdf", replace	
	restore
end

main
