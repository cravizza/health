clear all
set more off

program main
	qui do ..\globals.do
	global controls = " civs N regionid "	
	local rvar = "age_all"
	use ..\temp\ind_did.dta, clear
	set graphics off
	did_dynamic, time(Week) r_var(`rvar')
	set graphics on
end


capture program drop did_dynamic
program              did_dynamic	
syntax, time(varname) r_var(varname)
	preserve
	
		if substr("`r_var'",-3,1) == "all" {
			local controls = "${controls}" + " gender"
		}
		else {
			local controls = "${controls}"
		}
		* Panel span: Week=(-25,13); Month=(-7,4); drop first and last of graphs
		replace post_Week=-25 if post_Week<-24
		replace post_Week= 13 if post_Week> 12
		local cp_drop = "1.i_inte 39.i_inte" // 39=25+13+1
		gen `time'no = week(dofw(Week))
		* Create post indicator with labels, and labels for Week plot
		gen treat = (control==0)
		qui sum post_`time'
		local N = r(max) - r(min) + 1
		gen i_post = post_`time' - r(min) + 1
		gen i_inte = i_post * treat
		forval x = 1/`N' {
			qui sum post_`time' if i_post==`x'
			local post_labs = `"`post_labs' "' + `" `x' "`r(mean)'" "'
		}
		capture lab drop labs
		label define post_labs `post_labs'
		label values i_post  post_labs
		label values i_inte  post_labs
		if "`time'"=="Week" {
			forval i = 1/39 {
				if mod(`i',4)==1 { // yields labs every 4 dates
					qui sum post_Week if i_post==`i'+1
					local cp_labs = `"`cp_labs'"' + `" `i' "`r(mean)'" "'
				}
			}
			local cp_xlab = `"xlab(`cp_labs')"'
		}
		* Run regressions and create plots
		local words: word count `controls'
		forval w = 1/`words' {
			local y: word `w' of `controls'
			local i_controls = "`i_controls'" + " i." + "`y'"
		}
		qui sum i_post if post_`time'==0
		local x0 = `r(mean)' - 0.5 - 1 // -1 since we drop first coefficient
		local coefplot_opts = " vertical baselevels ${wb} yli(0, lc(gs12)) " ///
		       + " xline(`x0', lc(black) lp(dot)) mc(midgreen) ciopts(lc(midgreen))"
		foreach outcome of varlist max_* {
			reg `outcome' i.treat i.i_post ib26.i_inte i.`r_var' `i_controls' i.`time'no
			coefplot, `coefplot_opts' xtitle("`time_label'")  `cp_xlab' ///
				drop(_cons *.treat *.i_post `cp_drop' *.`r_var' *.civs *.N_hiv_test *.regionid *.gender *.`time'no)
			graph export ../output/did_`time'_`r_var'_`outcome'.pdf, replace
		}
	restore
end

main
