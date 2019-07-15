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
	
	use ..\temp\hiv_tests.dta, clear
	keep if enr==1
	hist_copay_age
	testing_and_gt
	forval c = 1/5 {
		sb_test, campaign(`c') time(Week) r_var(male)
	}
	piecewise_fit, time(Week)  r_var(male)
	piecewise_fit, time(Week)  r_var(female)
	sh_lev_plot  , time(Week)  by_var(age_male)
	sh_lev_plot  , time(Week)  by_var(gender)
	
	trends_by_var, time(Week)  r_var(male)  by_var(test_n)
	trends_by_var, time(Week)  r_var(male)  by_var(copay_gr)
	trends_by_var, time(Week)  r_var(male)  by_var(proreg_13)
	trends_by_var, time(Week)  r_var(male)  by_var(married)
	trends_by_var, time(Week)  r_var(male)  by_var(child)

	use ..\temp\hiv_pbon.dta, clear
	keep if male==1 & enr==1
	sb_test, campaign(1) time(Week) r_var(i_hemogra)
	sb_test, campaign(5) time(Week) r_var(i_hemogra)
	sb_test, campaign(1) time(Week) r_var(i_syphili)
	sb_test, campaign(5) time(Week) r_var(i_syphili)
	piecewise_fit, time(Week)  r_var(i_syphili)
	piecewise_fit, time(Week)  r_var(i_hemogra)
	trends_by_var, time(Week)  r_var(male)      by_var(tests1)
	trends_by_var, time(Week)  r_var(male)      by_var(tests2)
	
	incidence_plot, time(Week)
	incidence_plot, time(Month)
	interval_test_conf

	set graphics on
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
		reg deseason Week_id `hiv`campaign''
		
		capture drop Wtest
		estat sbsingle, breakvars(Week_id, cons) gen(Wtest) trim(15)
		local bd "`r(breakdate)'"
		local pv: di %9.4f `r(p)'
		sum Wtest
		local nx = `r(max)' + 2.7
		sum Week if !mi(Wtest)
		local ny = `r(min)' + int((`r(max)'-`r(min)')*0.32)
		
		tw line Wtest Week if !mi(Wtest), ${wb} lc(midgreen) tline(`lhiv', lc(black) lp(dash)) ///
			tline(`bd', lp("##-##-") lc(red)) ttext(`nx' `ny' "Break date: `bd'""p-value:`pv'" ///
			 , place(sw) box just(center) margin(l+1 t+1 b+1 r+2) width(35) )
		graph export "..\output\sb_`campaign'_`r_var'_`time'.pdf", replace
	restore	
end

capture program drop  piecewise_fit
program               piecewise_fit
syntax, r_var(varname) time(varname)
	if !inlist("`time'","Month","Week") {
		di "Error: time() needs to be Week or Month"
		exit
	}
	preserve
		collapse (count) tests2=age if `r_var'==1, by(`time')
		gen  `time'no = week(dofw(`time'))
		lab var tests2 "Number of tests"
		local tw_opts = `"${wb} ${hiv_`time'_tlinelab}"'
		* Trends
		tw line tests2 `time', lc(midgreen) `tw_opts'
		graph export "..\output\trend_`r_var'_`time'.pdf", replace
		* Create constants and slopes for each campaign
		local n_dates: word count ${hiv_`time'_all}
		forval i = 2/ `n_dates' {
			local i0 = `i'-1
			local p  = `i'-2
			local ic0: word `i0' of ${hiv_`time'_all}
			local ic1: word `i'  of ${hiv_`time'_all}
			gen     b_`p' = 0
			if "`time'" == "Month" {
				gen     a_`p' = inrange(`time',tm(`ic0'),tm(`ic1')-1) //MONTH
				replace b_`p' = `time' - tm(`ic0')  if a_`p'==1       //MONTH
			}
			else {
				gen     a_`p' = inrange(Week,tw(`ic0'),tw(`ic1')-1) //WEEK
				replace b_`p' = Week - tw(`ic0')  if a_`p'==1       //WEEK
			}
		}
		* Piecewise reg
		eststo: reg tests2 a_* b_*  i.`time'no, nocons
		esttab using "../output/pw_hiv_`r_var'_`time'.tex", replace label nomti nonumbers ///
			cells("b(fmt(%8.2f) label(Coef.)) se(fmt(%8.2f) label(Std. err.) par)") ///
			starlevels( * 0.10 ** 0.05 *** 0.010) stardetach wide nogaps d(a_0 a_1 a_2 a_3 *.`time'no) compress ///
			stats(N, fmt(%9.0fc) l("Obs.")) nofloat // title(Estimated slopes\vspace{-1ex}) 
		eststo clear 
		predict tests_hat2
		forval x=2/52 {
			gen sum_`x' = _b[`x'.Weekno]
		}
		gen tests = .
		gen tests_hat =  .
		forval x=2/52 {
			replace tests     = tests2      - sum_`x' if Weekno==`x'
			replace tests_hat = tests_hat2  - sum_`x' if Weekno==`x'
		}
		lab var tests "Number of tests (deseas.)"
		lab var tests_hat "Fitted values (deseas.)"
		file open myfile using "../output/pw_test_hiv_`r_var'_`time'.txt", write replace
		qui test a_4 == a_5
		local a_eq:  di %9.4f r(p)
		di "p-value test a_4 == a_5: 0" + `a_eq' 
		file write myfile "\item a\_4==a\_5: `a_eq'" _n
		forvalues x = 0/4 {
			local x1 = `x'+1
			qui test b_`x' == b_`x1'
			local b_eq:  di %9.4f r(p)
			di "p-value test b_`x' == b_`x1': 0" + `b_eq' 
			file write myfile "\item b\_`x'==b\_`x1': `b_eq'" _n
		}
		file close myfile
		* Piecewise plot
		tw  (line tests     `time', lc(midgreen)) (line tests_hat `time', lc(red)), ///
			ytitle("`: var lab tests'") `tw_opts'
		graph export "..\output\pw_hiv_`r_var'_`time'.pdf", replace
	restore
end

capture program drop trends_by_var
program              trends_by_var
syntax, time(varname) r_var(varname) by_var(str)
	preserve
		collapse (count) tests=age if `r_var'==1, by(`time' `by_var') 
		lab var tests "Number of tests"
		qui levelsof `by_var', local(list_`by_var')
		local N = `: word count `list_`by_var'''
		forv x = 1(1)`N' {
			local x1: word `x' of `list_`by_var''
			local l1: word `x' of ${list_lc}
			local line_plot = "`line_plot'" + " (line tests    `time' if `by_var'==`x1', lc(`l1')) "
			local labs = `"`labs'"' + `" `x' "`: label (`by_var') `x1''" "'
		}
		tw `line_plot', ${wb} ${hiv_`time'_tlinelab} ///
			legend(order(`labs') symx(6) c(`N'))			
		graph export "..\output\trend_`by_var'_`r_var'_`time'.pdf", replace		
	restore
end

capture program drop sh_lev_plot
program 	         sh_lev_plot
syntax, by_var(str) time(varname)
	preserve
		collapse (count) tests=age if !mi(`by_var'), by(`time' `by_var') 
		egen total_tests = total(tests), by(`time')
		gen  sh_tests    = tests/total_tests
		
		qui levelsof `by_var', local(list_`by_var')
		local N = `: word count `list_`by_var'''
		forv x = 1(1)`N' {
			local x1: word `x' of `list_`by_var''
			local l1: word `x' of ${list_lp}
			local c1: word `x' of ${list_lc}
			local  sh_plot =  "`sh_plot'" + " (line sh_tests `time' if `by_var'==`x1', lc(`c1')) " //lp(`l1')
			local lev_plot = "`lev_plot'" + " (line tests    `time' if `by_var'==`x1', lc(`c1')) " //lp(`l1')
			local labs = `"`labs'"' + `" `x' "`: label (`by_var') `x1''" "'
		}
		local tw_opts = `"${wb} ${hiv_`time'_tlinelab} "' + ///
				`"ytitle("") legend(order(`labs') symx(6) c(`N'))"'
		tw  `sh_plot' ,  `tw_opts'
		graph export "..\output\shares_`by_var'_`time'.pdf", replace
		tw  `lev_plot' , `tw_opts'
		graph export "..\output\levels_`by_var'_`time'.pdf", replace
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

program hist_copay_age
	qui sum copay if copay!=0, det 
	twoway  (hist copay if gender==1 & copay<=`r(p90)', bin(50) color(green)) ///
			(hist copay if gender==0 & copay<=`r(p90)', bin(50) fcolor(none) lcolor(black)) ///
			, ${wb} legend(order(1 "Male" 2 "Female" ))
	graph export "..\output\hist_copay.pdf", replace	
	twoway (hist age if gender==1, bin(50) color(green)) ///
		   (hist age if gender==0, bin(50) fcolor(none) lcolor(black)) ///
			, ${wb} legend(order(1 "Male" 2 "Female" ))
	graph export "..\output\hist_ages.pdf", replace		

	preserve
		collapse (count) tst=gender if gender==1 & age_18_45==1, by(age Year)  
		lab var tst "Number of HIV tests"
		tw (line tst age if Year==2012, lc(black)  lp(solid))    (line tst age if Year==2013, lc(blue) lp(shortdash_dot)) ///
		   (line tst age if Year==2014, lc(green)  lp(dash_dot)) (line tst age if Year==2015, lc(cyan) lp(shortdash)) ///
		   (line tst age if Year==2016, lc(orange) lp(dash))     (line tst age if Year==2017, lc(red)  lp(longdash)) ///
			, ${wb} legend(order(1 "2012" 2 "2013" 3 "2014" 4 "2015" 5 "2016" 6 "2017") symx(6) c(6))			 
			graph export "..\output\hist_ages_men_by_year.pdf", replace
	restore
end

program testing_and_gt
	preserve
	rename Quarter quarter
	collapse (count) tests=age if gender==1, by(quarter)
	merge 1:1 quarter using "D:\Personal Directory\Catalina\Derived\google_trends_quarter.dta", keep(3)
	*keep if inrange(quarter,yq(2010,1),yq(2015,4))
	
	foreach var in hivaids vih sida testelisa {
		tw (line tests    quarter, lc(blue) ytitle("Number of positive tests")) ///
		   (line gt_`var' quarter, lc(red) lp("-..") yaxis(2) ytitle("Relative search interest", axis(2))) ///
		, ${wb} tline(2010q4 2011q4 2012q4 2013q4 2015q2, lc(black) lp(dash)) tmlab(2010q4 "(a)" ///
		2011q4 "(b)" 2012q4 "(c)" 2013q4 "(d)" 2015q2 "(e)", tp(inside) labs(*0.9) labgap(*.3))
		graph export "..\output\tests_gt_`var'.pdf", replace
	}
	restore
end

main

