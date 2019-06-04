/*
ETS plots
*/
clear all
set more off

program main
	qui do ..\globals.do	
	local options `"${wb} legend(c(4) symx(6)) ytitle("Number of new cases")"'
	local path_dis = "D:\Personal Directory\Catalina\Derived\"
	
	import excel using "`path_dis'diseases.xlsx", clear  sh("total") first
	time_and_labs
	
	qui sum syph_n
	local lmax = ceil(`r(max)'/500)*500
	tw (line aidshiv_n Year, lc(midgreen)) (line syph_n Year, lc(purple)) (line gono_n Year, lc(orange)) if !mi(syph_n) ///
		, `options' ylab(0(1000)`lmax')
	graph export ..\output\ets_all.pdf, replace

	import excel using "`path_dis'diseases.xlsx", clear  sh("gender") first
	time_and_labs
	
	qui sum syph_n
	local lmax = ceil(`r(max)'/500)*500
	tw (line aidshiv_n Year if gender==1, lc(midgreen)) ///
	   (line aidshiv_n Year if gender==2, lc(orange) ) if !mi(syph_n) ///
	  , `options' ylab(0(700)`lmax') legend(on order(1 "Men" 2 "Women"))
	graph export ..\output\ets_aidshiv_gender.pdf, replace
	tw (line syph_n Year if gender==1, lc(midgreen)) ///
	   (line syph_n Year if gender==2, lc(orange)) if !mi(syph_n) ///
	  , `options' ylab(0(700)`lmax') legend(on order(1 "Men" 2 "Women"))
	graph export ..\output\ets_syph_gender.pdf, replace
	
	import excel using "`path_dis'diseases.xlsx", clear  sh("age_gr") first
	time_and_labs
	
	qui sum aidshiv_n
	local lmax = ceil(`r(max)'/200)*200
	tw (line aidshiv_n Year if age_gr=="20_24", lc(orange)) ///
	   (line aidshiv_n Year if age_gr=="25_29", lc(midgreen)) ///
	   (line aidshiv_n Year if age_gr=="30_34", lc(cranberry)) ///
	   (line aidshiv_n Year if age_gr=="35_39", lc(midblue)) ///
	   , `options' ylab(0(250)`lmax') ///
	   legend(on order(1 "20-24" 2 "25-29" 3 "30-34" 4 "35-39"))
	graph export ..\output\ets_aidshiv_age_gr.pdf, replace
	qui sum syph_n
	local lmax = ceil(`r(max)'/200)*200
	tw (line syph_n Year if age_gr=="20_24", lc(orange)) ///
	   (line syph_n Year if age_gr=="25_29", lc(midgreen)) ///
	   (line syph_n Year if age_gr=="30_34", lc(cranberry)) ///
	   (line syph_n Year if age_gr=="35_39", lc(midblue)) ///
	   , `options' ylab(0(250)`lmax') ///
	   legend(on order(1 "20-24" 2 "25-29" 3 "30-34" 4 "35-39"))
	graph export ..\output\ets_syph_age_gr.pdf, replace
end	
		
program time_and_labs
	gen Year = year(date(string(year),"Y"))
	local list_vars = "aids gono syph"
	local list_labs "HIV/AIDS Gonorrhea Syphilis"
	forval i = 1/3 {
		local v1: word `i' of `list_vars'
		local l1: word `i' of `list_labs'
		qui ds `v1'*
		local list`i' = "`r(varlist)'"
		foreach x in `list`i'' {
			lab var `x' "`l1'"
		}
	}
end

main
