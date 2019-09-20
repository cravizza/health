/* 
This file analyzes tests
- r_var : restrict to subsample such  that r_var is equal to 1
- by_var : used to create plot with trends by this var
*/
clear all
set more off

program main
	qui do ..\globals.do
	
	set graphics off	
	use ..\temp\agg_hiv.dta, clear
	es_2017_table, time(Week) window(15)
	es_2017, time(Week) r_var(male) window(15)
	es_2017, time(Week) r_var(female) window(15)
	es_2017, time(Week) r_var(all) window(15)
	
	//trend_year
	sb_test, campaign(5) time(Week) r_var(all)
	
	foreach byvar in married less_than_yr initiation income_am age_all {
		trends_by_var, time(Week) r_var(all)  by_var(`byvar')
	}
//	trends_by_var, time(Week) r_var(female) by_var(age_female)
//	trends_by_var, time(Week) r_var(all) by_var(age_all)
	
/*	use ..\temp\agg_pbon.dta, clear
	keep if male==1
	sb_test, time(Week) r_var(i_hemogra) campaign(5)
	sb_test, time(Week) r_var(i_syphili) campaign(5)
	es_2017, time(Week) r_var(i_hemogra) window(15)	
	es_2017, time(Week) r_var(i_syphili) window(15)	
	trends_by_var, time(Week) r_var(male) by_var(tests1)
	trends_by_var, time(Week) r_var(male) by_var(tests2)
*/
	set graphics on
end

capture program drop es_2017_table
program              es_2017_table
syntax, time(varname) window(int)
	foreach r_var in all male female {
		preserve
			collapse (count) tests=age (first) Year if `r_var'==1, by(`time')
			gen `time'no = week(dofw(`time'))
			gen t = cond(inrange(Week,tw(${hiv5_`time'_L})-`window',tw(${hiv5_`time'_L})+`window'),`time' - tw(${hiv5_`time'_L}) + `window' + 1,0)
			gen b = Week - tw(2012w1)
			* Create table with trend
			reg tests b i.t i.`time'no i.Year
			foreach v in "_cons" "b" {
				local `r_var'_`v'_b: di %5.2f _b[`v']
				local `r_var'_`v'_p: di %5.3f (2*ttail(e(df_r), abs(_b[`v']/_se[`v'])))
				local `r_var'_`v'_p = "(``r_var'_`v'_p')"
			}
			local T = 2*`window' + 1
			forval t = 1/`T' {
				local `r_var'_t`t'_b: di %5.2f _b[`t'.t]
				local `r_var'_t`t'_p: di %5.3f (2*ttail(e(df_r), abs(_b[`t'.t]/_se[`t'.t])))
				local `r_var'_t`t'_p = "(``r_var'_t`t'_p')"
			}
			local vars = "_cons b "
			forval t = 1/`T' {
				local c = `t' - 16
				local vars = "`vars'" + " t`t'"
				qui sum `time' if t==`t'
				local lab_t`t' : di %tw `r(mean)' 
				local lab_t`t' = char(36) + " c_{`c'} " + char(36) + ": `lab_t`t''"
			}
		restore
	}
	local lab__cons = "Constant"
	local lab_b     = "Trend"
	file open myfile using "..\output\es5_table_`window'_`time'.tex", write replace
	file write myfile "\begin{threeparttable}" ///
					_n "\begin{tabular}{@{}r|rr|rr|rr@{}} \hline\hline"  ///
					_n " & \multicolumn{2}{c|}{(1) All} & \multicolumn{2}{c|}{(2) Men} & " ///
					   " \multicolumn{2}{c}{(3) Women} \\ " ///
					_n " & Coeff. & p-value  & Coeff. & p-value & Coeff. & p-value \\ \hline"
	foreach v in `vars' {
		file write myfile _n " `lab_`v'' & `all_`v'_b'  & `all_`v'_p' & " ///
			"`male_`v'_b'  & `male_`v'_p'  & `female_`v'_b'  & `female_`v'_p' \\ "
	}
	file write myfile _n "\hline\hline" _n "\end{tabular}"
	file close myfile
end

capture program drop es_2017
program es_2017
syntax, time(varname) r_var(varname) window(int)
	preserve
		collapse (count) tests=age (first) Year if `r_var'==1, by(`time')
		lab var tests "Number of tests"
		tw line tests `time' if inrange(Year,2016,2017), ${wb} ${hiv5_`time'_tlinelab} lc(midgreen)
		graph export ../output/trend5_`r_var'_`time'_all.pdf, replace
	restore
	preserve
		collapse (count) tests=age (first) Year if `r_var'==1, by(`time')
		lab var tests "Number of tests"
		tw line tests `time' if inrange(Year,2016,2017), ${wb} ${hiv5_`time'_tlinelab} lc(midgreen)
		graph export ../output/trend5_`r_var'_`time'.pdf, replace
		gen  `time'no = week(dofw(`time'))
		gen t = cond(inrange(Week,tw(${hiv5_`time'_L})-`window',tw(${hiv5_`time'_L})+`window'),`time' - tw(${hiv5_`time'_L}) + `window' + 1,0)
		gen b = Week - tw(2012w1)

		reg tests b i.t i.`time'no i.Year
		local T = 2*`window' + 1
		local modT = floor(`T'/4) // because I want labs only on five dates
		forval i = 1/`T' {
			if mod(`i',`modT')==1 {
				qui sum Week if t==`i'
				local ti : di %tw `r(mean)'
				local labs = `"`labs'"' + `" `i' "`ti'" "'
			}
		}
		lab def t_labs  `labs'
		lab val t      t_labs
		local xl = `window'+0.5
		local x2 = `window'-0.5
		local x3 = `window'-1.5
		coefplot, vertical ${wb} drop(_cons *.Year *.`time'no b) ciopts(lc(midgreen)) ///
			mc(midgreen) xtitle("`time_label'") ///
			xlabel(`labs') xline(`xl', lc(black) lp(dash))	 xline(`x2' `x3', lc(gs8) lp(shortdash))
		graph export ../output/es5_`r_var'_`window'_`time'.pdf, replace
		* Create table with trend 
		reg tests b i.t i.`time'no i.Year
		foreach v in "_cons" "b" {
			local `v'_b: di %5.2f _b[`v']
			local `v'_p: di %5.3f (2*ttail(e(df_r), abs(_b[`v']/_se[`v'])))
			local `v'_p = "(``v'_p')"
		}
		forval t = 1/`T' {
			local t`t'_b: di %5.2f _b[`t'.t]
			local t`t'_p: di %5.3f (2*ttail(e(df_r), abs(_b[`t'.t]/_se[`t'.t])))
			local t`t'_p = "(`t`t'_p')"
		}			
		local vars = "_cons b "
		local lab__cons = "Constant"
		local lab_b     = "Trend"
		forval t = 1/`T' {
			local c = `t' - 16
			local vars = "`vars'" + " t`t'"
			qui sum `time' if t==`t'
			local lab_t`t' : di %tw `r(mean)' 
			local lab_t`t' = char(36) + " c_{`c'} " + char(36) + ": `lab_t`t''"
		}
		file open myfile using "..\output\es5_`r_var'_`window'_`time'.tex", write replace
		file write myfile "\begin{threeparttable}" ///
						_n "\begin{tabular}{@{}r|rr@{}} \hline\hline"  ///
						_n " & \multicolumn{2}{c}{(1)} \\ " ///
						_n " & Coeff. & p-value \\ \hline"
		foreach v in `vars' {
			file write myfile _n " `lab_`v'' & ``v'_b'  & ``v'_p' \\ "
		}
		file write myfile _n "\hline\hline" _n "\end{tabular}"
		file close myfile		
	restore
end

capture program drop sb_test
program              sb_test
syntax, campaign(int) time(varname) r_var(varname)
	local hiv1 = " if inrange(Week,tw(2012w1) ,tw(2013w45))"
	local hiv2 = " if inrange(Week,tw(2013w1) ,tw(2015w20))"
	local hiv3 = " if inrange(Week,tw(2014w1) ,tw(2015w45))"
	local hiv4 = " if inrange(Week,tw(2015w25),tw(2017w15))"
	local hiv5 = " if inrange(Week,tw(2016w1) ,tw(2017w52))"
	local lhiv: word `campaign' of ${hiv_`time'}
	preserve
		collapse (count) tests=age if `r_var'==1 & !mi(`time'), by(`time')
		gen  `time'no = week(dofw(`time'))
		qui reg tests i.`time'no
		predict resid, residuals
		gen deseason = _b[_cons] + resid
		sort `time'
		isid `time'
		gen  `time'_id = _n
		
		tsset `time'
		local bv_intercept = ", cons"
		local bv_slope     = "Week_id"
		local bv_both      = "Week_id, cons"
		foreach x in intercept slope both {
			reg deseason Week_id `hiv`campaign''
			
			capture drop Wtest
			estat sbsingle, breakvars(`bv_`x'') gen(Wtest) trim(15)
			local bd "`r(breakdate)'"
			local pv: di %9.4f `r(p)'
			sum Wtest
			local nx = `r(max)' + 2.7
			qui sum Week if !mi(Wtest)
			local ny = `r(min)' + int((`r(max)'-`r(min)')*0.32)
			
			tw line Wtest Week if !mi(Wtest), ${wb} lc(midgreen) tline(`lhiv', lc(black) lp(dash)) ///
				tline(`bd', lp("##-##-") lc(red)) ttext(`nx' `ny' "Break date: `bd'""p-value:`pv'" ///
				 , place(sw) box just(center) margin(l+1 t+1 b+1 r+2) width(35) )
			graph export "..\output\sb_`campaign'_`r_var'_`time'_`x'.pdf", replace
		}
	restore	
end

capture program drop trends_by_var
program              trends_by_var
syntax, time(varname) r_var(varname) by_var(str)
	preserve
		keep if inrange(Year,2016,2017) & month!=201712 //issue ti & civs
		collapse (count) tests=age if `r_var'==1 & !mi(`by_var'), by(`time' `by_var')
		egen total_tests = total(tests), by(`time')
		gen  sh_tests    = tests/total_tests
		lab var    tests "Number of tests"
		lab var sh_tests "Share of tests"
		qui levelsof `by_var', local(list_`by_var')
		local N = `: word count `list_`by_var'''
		forv x = 1(1)`N' {
			local x1: word `x' of `list_`by_var''
			local c1: word `x' of ${list_lc}
			local lev_plot = "`lev_plot'" + " (line    tests `time' if `by_var'==`x1', lc(`c1')) "
			local  sh_plot =  "`sh_plot'" + " (line sh_tests `time' if `by_var'==`x1', lc(`c1')) "
			local labs = `"`labs'"' + `" `x' "`: label (`by_var') `x1''" "'
		}
		tw `lev_plot', ${wb} ${hiv5_`time'_tlinelab} legend(order(`labs') symx(6) c(`N'))			
		graph export "..\output\trend_lv_`by_var'_`r_var'_`time'.pdf", replace	
		tw  `sh_plot', ${wb} ${hiv5_`time'_tlinelab} legend(order(`labs') symx(6) c(`N')) ylab(0(0.25)1)
		graph export "..\output\trend_sh_`by_var'_`r_var'_`time'.pdf", replace	
	restore
end

program trend_year
	preserve
		collapse (count) tst=gender if male==1 & age_18_45==1, by(age Year)  
		lab var tst "Number of HIV tests"
		qui sum tst
		local maxr = ceil(`r(max)'/200)*200
		local maxI = `maxr'/4
		tw (line tst age if Year==2016, lc(purple)   lp(dash)) ///
		   (line tst age if Year==2017, lc(midgreen) lp(longdash)) ///
			, ${wb} legend(order(1 "2016" 2 "2017") symx(6) c(2)) ylab(0(`maxI')`maxr')
			graph export "..\output\trend_yr_age_18_45_male_by_year.pdf", replace
	restore
	local wS = "w12 w31"
	local wE = "w28 w47"
	forv x = 1/2 {
		local ws: word `x' of `wS'
		local we: word `x' of `wE'
		preserve
			keep if inrange(Week,tw(2016`ws'),tw(2016`we')) | inrange(Week,tw(2017`ws'),tw(2017`we'))
			collapse (count) tst=gender if male==1 & age_18_45==1, by(age Year)  
			lab var tst "Number of HIV tests"
			qui sum tst
			local maxr = ceil(`r(max)'/50)*50
			local maxI = `maxr'/5
			tw (line tst age if Year==2016, lc(purple)   lp(dash)) ///
			   (line tst age if Year==2017, lc(midgreen) lp(longdash)) ///
				, ${wb} legend(order(1 "2016" 2 "2017") symx(6) c(2)) ylab(0(`maxI')`maxr')
				graph export "..\output\trend_yr_age_18_45_male_by_year_`ws'`we'.pdf", replace
		restore
	}
end

main

