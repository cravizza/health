clear all
set more off

program main
	use "..\..\..\derived\clean\output\pb_groupby_month.dta", clear
	drop if gender==2 //decode gender , generate(Gender)
	gen Month = mofd(date(string(month),"YM"))
	format %tm Month
	drop month index
	create_gender_code_dummies
	foreach x in all female male code2s code2f code_03 code_01 code_09 {
		seasonality , filter(`x')
	}
end

capture program drop seasonality
program seasonality
syntax, filter(varname)
	preserve
		collapse (sum) claims=isapre if `filter'==1, by(Month) 
		replace claims = claims/1000
		lab var claims "Thousands of health services"
		
		gen Calendar_Month = month(dofm(Month))	
		gen Year           = year(dofm(Month))	
				
		qui reg claims i.Year // di %9.2f e(r2)
		local r2y: di %9.2f e(r2)
		qui reg claims i.Calendar_Month
		local r2m:  di %9.2f e(r2)
		qui reg claims i.Year i.Calendar_Month
		local r2ym:  di %9.2f e(r2)
		di "R-squared, year only FE:      0" + `r2y'
		di "R-squared, month only FE:     0" + `r2m'
		di "R-squared, year and month FE: 0" + `r2ym'
		
		qui reg claims ibn.Calendar_Month i.Year, nocons // reg claims ib1.Calendar_Month i.Year
		
		local coefplot_opts = " vertical baselevels yline(0, lc(black) lp(shortdash)) " + ///
							  " xtitle(Calendar_Month) graphregion(color(white)) bgcolor(white) "	
		set graphics off
		coefplot, `coefplot_opts'  drop(*.Year)  		///
			xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11" 12 "12") 
		graph export "..\output\seas_m_`filter'_coefplot.pdf", replace
		
		tw line claims Month, lc(blue) , ///
			tline(2013m1 2014m1 2015m1 2016m1 2017m1, lc(black) lp(dash)) ///
			tlab(#7) ylab(#5) xsiz(8) ///
			graphregion(color(white)) bgcolor(white) 
		graph export "..\output\seas_m_`filter'_trend.pdf", replace
			
		drop Month
		local lab_claims "`: var lab claims'"
			qui reshape wide claims, i(Calendar_Month) j(Year)
			forvalues y = 2012/2017 {
				lab var claims`y' "`y'"
			}
			tw  (line claims2012 Calendar_Month, lc(black)   lp(dash)         )  ///
				(line claims2013 Calendar_Month, lc(blue)    lp(shortdash)    )  ///
				(line claims2014 Calendar_Month, lc(lime)    lp(dash_dot)     )  ///
				(line claims2015 Calendar_Month, lc(magenta) lp(shortdash_dot))  ///
				(line claims2016 Calendar_Month, lc(orange)  lp(longdash)     )  ///
				(line claims2017 Calendar_Month, lc(red)     lp(".__")        ), ///
				ytitle("`lab_claims'") xlab(1(1)12) ylab(#3) legend(symx(6) c(6)) ///
				graphregion(color(white)) bgcolor(white) 	
			graph export "..\output\seas_m_`filter'_year.pdf", replace
		 set graphics on
	restore
end

program create_gender_code_dummies
	gen     female = (gender==0)
	lab var female "`: lab gender 0'"
	gen     male   = (gender==1)
	lab var male   "`: lab gender 1'"
	gen all = 1
	
	decode code2, g(code2c)
	gen code2s = inlist(code2c,"61","40","50","62","43","73")
	gen code2f = inlist(code2c,"03","01","04","06","09","17","08","12","18")

	foreach x in "01" "03" "04" "06" "08" "09" "12" "17" "18" {
		gen code_`x' = (code2c=="`x'") if code2f==1
	}
	lab var code_03 "Lab tests"
	lab var code_01 "Doctor visit"
	lab var code_04 "Images"
	lab var code_06 "Physical therapy"
	lab var code_08 "Anatomia patologica"
	lab var code_09 "Psyc./Psyq. visit"
	lab var code_12 "Oftalmology"
	lab var code_17 "Cardiology"
	lab var code_18 "Gastroenterology"
end
			
main
