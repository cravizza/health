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
	
	incidence_plot, time(Month)
	
	use ..\temp\hiv_tests.dta, clear
	es_2017, time(Week) r_var(male) window(15)	
	
	keep if enr==1
	trend_year
	sb_test, campaign(5) time(Week) r_var(male)
	foreach byvar in test_n age_male married copay_gr proreg_13 {
		trends_by_var, time(Week) r_var(male)  by_var(`byvar')
	}
	
/*	use ..\temp\hiv_pbon.dta, clear
	keep if male==1 & enr==1
	sb_test, campaign(1) time(Week) r_var(i_hemogra)
	sb_test, campaign(5) time(Week) r_var(i_hemogra)
	sb_test, campaign(1) time(Week) r_var(i_syphili)
	sb_test, campaign(5) time(Week) r_var(i_syphili)
	trends_by_var, time(Week)  r_var(male)      by_var(tests1)
	trends_by_var, time(Week)  r_var(male)      by_var(tests2)
	interval_test_conf
*/
	set graphics on
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
		keep if enr==1
		collapse (count) tests=age (first) Year if `r_var'==1, by(`time')
		lab var tests "Number of tests"
		tw line tests `time' if inrange(Year,2016,2017), ${wb} ${hiv5_`time'_tlinelab} lc(midgreen)
		graph export ../output/trend5_`r_var'_`time'.pdf, replace
		gen  `time'no = week(dofw(`time'))
		gen t = cond(inrange(Week,tw(${hiv5_launch})-`window',tw(${hiv5_launch})+`window'),`time' - tw(${hiv5_launch}) + `window' + 1,0)
		gen b = Week - tw(2012w1)

		reg tests b i.t i.`time'no i.Year
		local window =15
		local N = 2*`window' + 1
		local modN = floor(`N'/4) // because I want labs only on five dates
		forval i = 1/`N' {
			if mod(`i',`modN')==1 {
				qui sum Week if t==`i'
				local ti : di %tw `r(mean)'
				local labs = `"`labs'"' + `" `i' "`ti'" "'
			}
		}
		lab def t_labs  `labs'
		lab val t      t_labs
		local xl = `window'+0.5		

		coefplot, vertical ${wb} drop(_cons *.Year *.`time'no b) ciopts(lc(midgreen)) ///
			mc(midgreen) xtitle("`time_label'") ///
			xlabel(`labs') xline(`xl', lc(black) lp(dash))	
		graph export ../output/es5_`r_var'_`window'_`time'.pdf, replace
		* Create table with and without trend
		local FE1 = " b"
		forval x=1/1 { 
			reg tests `FE`x'' i.t i.`time'no i.Year
			foreach v in "_cons" `FE`x'' { //T I
				local `v'_`x'b: di %5.2f _b[`v']
				local `v'_`x'p: di %5.3f (2*ttail(e(df_r), abs(_b[`v']/_se[`v'])))
				local `v'_`x'p = "(``v'_`x'p')"
			}
			forval yy = 1/`N' {
				local t`yy'_`x'b: di %5.2f _b[`yy'.t]
				local t`yy'_`x'p: di %5.3f (2*ttail(e(df_r), abs(_b[`yy'.t]/_se[`yy'.t])))
				local t`yy'_`x'p = "(`t`yy'_`x'p')"
			}			
		}
		local vars = "_cons b "
		local lab__cons = "Constant"
		local lab_b     = "Trend"
		forval yy = 1/31 {
			local c = `yy' - 16
			local vars = "`vars'" + " t`yy'"
			qui sum `time' if t==`yy'
			local lab_t`yy' : di %tw `r(mean)' 
			local lab_t`yy' = char(36) + " c_{`c'} " + char(36) + ": `lab_t`yy''"
		}
		file open myfile using "..\output\es5_`r_var'_`window'_`time'.tex", write replace
		file write myfile "\begin{threeparttable}" ///
						_n "\begin{tabular}{@{}r|rr@{}} \hline\hline"  ///
						_n " & \multicolumn{2}{c}{(1)} \\ " ///
						_n " & Coeff. & p-value \\ \hline"
		foreach v in `vars' {
			file write myfile _n " `lab_`v'' & ``v'_1b'  & ``v'_1p' \\ "
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
		keep if inrange(Year,2016,2017)
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
		tw  `sh_plot', ${wb} ${hiv5_`time'_tlinelab} legend(order(`labs') symx(6) c(`N'))	
		graph export "..\output\trend_sh_`by_var'_`r_var'_`time'.pdf", replace	
	restore
end

capture program drop incidence_plot
program              incidence_plot
syntax, time(str)
	use ..\temp\hiv_conf_date.dta, clear
	gen Week = wofd(date(conf_date),"YMD")
	format %tw Week 
	gen Month = mofd(date(conf_date),"YMD")
	format %tm Month 
	gen Quarter = qofd(dofm(Month))
	preserve
		collapse (count) tests=id_b, by(`time') 
		lab var tests "Number of HIV confirmations"
		tw line tests `time', lc(midgreen) ${wb} ${hiv_`time'_tlinelab} ylab(#3)
		graph export "..\output\trend_conf_`time'.pdf", replace
	restore
end

program interval_test_conf
	use "..\..\..\derived\clean\output\hiv_tests.dta", clear
	drop  index
	duplicates drop
	gen Month = mofd(date(string(month)),"YM")
	format %tm Month
	keep  id_b id_m date Month
	rename date test_date
	sort  id_b id_m test_date
	duplicates drop id_b id_m Month, force // 0.6% obs dropped // duplicates tag id_b id_m Month, g(tag)
	isid id_b id_m Month

	merge m:1 id_m id_b using ..\temp\hiv_conf_date.dta, keep(1 3) nogen

	gen conf_week = wofd(date(conf_date),"YMD")
	gen test_week = wofd(date(test_date),"YMD")
	format %tw *_week

	gen interval_w = (conf_week-test_week)
	gen interval_d = date(conf_date,"YMD") - date(test_date,"YMD")
end

program trend_year
	preserve
		collapse (count) tst=gender if male==1 & age_18_45==1, by(age Year)  
		lab var tst "Number of HIV tests"
		tw (line tst age if Year==2016, lc(orange)   lp(dash)) ///
		   (line tst age if Year==2017, lc(midgreen) lp(longdash)) ///
			, ${wb} legend(order(1 "2016" 2 "2017") symx(6) c(2))			 
			graph export "..\output\trend_yr_age_18_45_male_by_year.pdf", replace
	restore
	preserve
		keep if inrange(Week,tw(2016w31),tw(2016w34)) | inrange(Week,tw(2017w31),tw(2017w34))
		collapse (count) tst=gender if male==1 & age_18_45==1, by(age Year)  
		lab var tst "Number of HIV tests"
		tw (line tst age if Year==2016, lc(orange)   lp(dash)) ///
		   (line tst age if Year==2017, lc(midgreen) lp(longdash)) ///
			, ${wb} legend(order(1 "2016" 2 "2017") symx(6) c(2))			 
			graph export "..\output\trend_yr_age_18_45_male_by_yearweek.pdf", replace
	restore
end

main

