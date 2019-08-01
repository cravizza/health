/* 
This file analyzes 2017 campaign
*/
clear all
set more off

program main
	qui do ..\globals.do
	create_sample
	*keep if N<4 & m>201415
	
	global controls = " civs N municiid regionid "
	use ..\temp\hiv_did_dates.dta, clear
	drop if date_hivm2>=td(10Sep2017)
	local timew = "Week"
	local timem = "Month"
	local tmax  = "max"
	local tsum  = "sum"
	local rvar  = "age_a_male"
	local yvars = "y_docvisit      y_spevisit          y_prevscre        y_diagther " ///
	            + "y_surgery       y_hospital          y_labblood        y_laburine   y_imaging"
	local ylabs = `""Doctor visit" "Specialist visit"  "Preventive care" "Diagnosis/therapy" "' ///
	            + `""Surgery"      "Hospitalization"   "Blood test"      "Urine test" "Imaging""'
	
	set graphics off
	es_dynamic, time(`timew') r_var(`rvar') y_vars(`yvars') type(`tmax')
	es_dynamic, time(`timem') r_var(`rvar') y_vars(`yvars') type(`tmax')
	es_dynamic, time(`timew') r_var(`rvar') y_vars(`yvars') type(`tsum')
	es_dynamic, time(`timem') r_var(`rvar') y_vars(`yvars') type(`tsum')
	set graphics on
	
	es_static, r_var(`rvar') y_vars(`yvars') type(`tmax') y_labs(`"`ylabs'"')
	es_static, r_var(`rvar') y_vars(`yvars') type(`tsum') y_labs(`"`ylabs'"')
end

capture program drop es_static
program              es_static	
syntax, r_var(varname) y_vars(varlist) type(str) y_labs(str)
	preserve
		drop if mi(post_static) // exclude any services on the day of the test
		drop if mi(`r_var')
		sort id_b id_m date_pb `r_var'
		collapse (`type') `y_vars' (mean) control (firstnm) `r_var' ${controls} date_hivm2 ///
			, by(id_m id_b post_static)
		assert !mi(id_b) & !mi(id_m) & ! mi(post)
		* Create a balanced panel (w/all controls) and fill w/zero if no service
		egen id = group(id_m id_b)
		xtset id post
		tsfill, full
		xtset id post
		foreach x in control `r_var' N civs municiid regionid {
			replace `x' = -99 if mi(`x')
			bys id: egen _temp = max(`x')
			replace `x' = _temp if `x'==-99
			drop _temp
		}
		foreach x in `y_vars' {
			replace `x' = 0 if mi(`x')
		}
		* Run regressions and create locals
		local FE0 = ""
		rename post P
		local FE1 = " i.region"
		local FE2 = " i.munici"
		local words: word count `y_vars'
		forval w = 1/`words' {
			local y: word `w' of `y_vars'
			replace `y' = 0 if mi(`y')
			forval x=0/2 { 
				qui reg `y' P i.`r_var' i.civs i.N `FE`x''
				local `w'_Pb_`x': di %5.4f _b[P]
				local `w'_Pp_`x': di %5.3f (2*ttail(e(df_r), abs(_b[P]/_se[P])))
				qui sum `y' if P==0
				local `w'_avg : di %5.4f `r(mean)'
			}
		}
		forval w = 1/`words' {
			local y: word `w' of `y_vars'
			local lab_`w':  word `w' of `y_labs'
			di "`y' : `lab_`w'' ***"
			forval x=0/2 {
				di "``w'_Pb_`x''  (``w'_Pp_`x'') "
			}
		}
		* Create table
		file open myfile using "..\output\es_`type'_`r_var'.tex", write replace
		file write myfile  "\begin{threeparttable}" ///
						_n "\begin{tabular}{@{}l|c|ccc@{}} \hline\hline"  ///
						_n " Outcomes & Pre mean & (1) & (2) & (3) \\ \hline"
		forval w = 1/`words' {
			local lab_`w':  word `w' of `y_labs'
			file write myfile _n " `lab_`w'' & ``w'_avg' &  ``w'_Pb_0'  &  ``w'_Pb_1'  &  ``w'_Pb_2'  \\ " ///
							  _n "           &           & (``w'_Pp_0') & (``w'_Pp_1') & (``w'_Pp_2') \\ " 
		}
		file write myfile _n "\hline Region FE & & No & Yes & No  \\ " ///
						  _n " Municipality FE & & No & No  & Yes \\ " ///
						  _n "\hline\hline" _n "\end{tabular}"
		file close myfile
	restore
end

capture program drop es_dynamic
program              es_dynamic	
syntax, time(varname) r_var(varname) y_vars(varlist) type(str)
	preserve
		drop if date_hivm == date_pb // exclude any servs on the day of the test
		drop if mi(`r_var')
		sort id_b id_m date_pb `r_var'
		collapse (`type') `y_vars' (mean) control (firstnm) `r_var' ${controls} Week ///
			, by(id_m id_b post_`time')
		assert !mi(id_b) & !mi(id_m) & ! mi(post)
		* Create a balanced panel (w/all controls) and fill w/zero if no service
		egen id = group(id_m id_b)
		qui xtset id post
		tsfill, full
		xtset id post
		foreach x in control `r_var' ${controls} {
			replace `x' = -99 if mi(`x')
			bys id: egen _temp = max(`x')
			replace `x' = _temp if `x'==-99
			drop _temp
		}
		foreach x in `y_vars' {
			replace `x' = 0 if mi(`x')
		}
		* Panel span: Week=(-25,13); Month=(-7,4); drop first and last of graphs
		if "`time'"=="Week" {
			replace post=-25 if post<-24
			replace post= 13 if post> 12
			local cp_drop = "1.i_post 39.i_post" // 39=25+13+1
			gen `time'no = week(dofw(Week))
		}
		else if "`time'"=="Month" {
			replace post=-7 if post<-6
			replace post= 4 if post> 3
			local cp_drop = "1.i_post 12.i_post"
			local cp_xlab = ""
			gen `time'no = month(dofw(Week))
		}
		* Create post indicator with labels, and labels for Week plot
		qui sum post
		local N = r(max) - r(min) + 1
		gen i_post = post - r(min) + 1
		forval x = 1/`N' {
			qui sum post if i_post==`x'
			local post_labs = `"`post_labs' "' + `" `x' "`r(mean)'" "'
		}
		capture lab drop labs
		label define post_labs `post_labs'
		label values i_post  post_labs
		if "`time'"=="Week" {
			forval i = 1/39 {
				if mod(`i',4)==1 { // yields labs every 4 dates
					qui sum post if i_post==`i'+1
					local cp_labs = `"`cp_labs'"' + `" `i' "`r(mean)'" "'
				}
			}
			local cp_xlab = `"xlab(`cp_labs')"'
		}
		* Run regressions and create plots
		qui sum i_post if post==0
		local x0 = `r(mean)' - 0.5 - 1 // -1 since we drop first coefficient
		local coefplot_opts = " vertical baselevels ${wb} yli(0, lc(gs12)) " ///
		       + " xline(`x0', lc(black) lp(dot)) mc(midgreen) ciopts(lc(midgreen))"
		foreach outcome in `y_vars' {
			reg `outcome' i.i_post i.`r_var' i.civs i.N i.region i.`time'no
			coefplot, `coefplot_opts' xtitle("`time_label'")  `cp_xlab' ///
				drop(_cons `cp_drop' *.`r_var' *.civs *.N *.regionid *.`time'no)
			graph export ../output/es_`type'_`time'_`r_var'_`outcome'.pdf, replace
		}
	restore
end

capture program drop create_sample
program              create_sample	
	use ..\temp\hiv_did.dta, clear
	rename date_hivm date_hivm2
	gen Week_hivm = wofd(date_hivm2)
	format %tw Week_hivm
	gen Month_hivm = mofd(date_hivm2)
	format %tm Month_hivm
	* Time variable
	gen post_Week   = Week  - Week_hivm
	gen post_Month  = Month - Month_hivm
	gen post_static = (date_pb > date_hivm2) if date_pb!=date_hivm2 & inrange(post_Week,-12,12)
	* Subsample
	keep if gender==1 & pregnant==0
	assert !mi(id_b) & !mi(id_m) & ! mi(post_Week)
	encode region, g(regionid)
	encode munici, g(municiid)
	bys id_m id_b date_pb: egen n_pb = count(isapre)
	replace civs=0 if inlist(civs,.,3,4)
	save ..\temp\hiv_did_dates.dta, replace
end

main
