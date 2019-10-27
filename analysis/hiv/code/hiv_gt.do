/*
Google trends plots
*/
clear all
set more off

program main
	qui do ..\globals.do
	local path_gt = "D:\Personal Directory\Catalina\Derived\gt\"
	
	import delimited using "`path_gt'gt_hiv_sifilis0.csv", clear  varnames(2) 
	clean_raw_gt
	rename vihsidachile vihsidachile0 
	rename sifilischile sifilischile0
	tempfile vih0
	save `vih0'
	import delimited using "`path_gt'gt_hiv_sifilis.csv", clear  varnames(2) 
	clean_raw_gt
	merge 1:1 Week using `vih0', nogen
	scale_var, scale_var(sifilischile)
	scale_var, scale_var(vihsidachile)
	tempfile vihsifilis
	save    `vihsifilis'

	import delimited using "`path_gt'gt_hivsifexam0.csv", clear  varnames(2) 
	clean_raw_gt
	rename examenvihexamensidatestelisachil vihexam0
	rename examensifilisvdrlchile sifexam0
	tempfile vihexam0
	save `vihexam0'

	import delimited using "`path_gt'gt_hivsifexam.csv", clear  varnames(2) 
	clean_raw_gt
	rename examenvihexamensidatestelisachil vihexam
	rename examensifilisvdrlchile sifexam
	merge 1:1 Week using `vihexam0', nogen
	scale_var, scale_var(vihexam)
	scale_var, scale_var(sifexam)

	merge 1:1 Week using `vihsifilis', nogen assert(3)

	lab var vihexam "HIV/AIDS + testing"
	lab var sifexam "Syphilis + testing"
	lab var vihsidachile "HIV/AIDS"
	lab var sifilischile "Syphilis"
	sort Week
	keep if inrange(Week,tw(2016w1),tw(2018w1))
	tw (line vihexam Week, lc(midgreen)) (line sifexam Week, lc(purple)) ///
		, ${wb} ${hiv5_Week_tlinelab} yt("Google trends index") // legend(on order(1))
	graph export ..\output\gt_vihexamen_Week.pdf, replace
	tw (line vihsida Week, lc(midgreen)) (line sifilis Week, lc(purple)) ///
		, ${wb} ${hiv5_Week_tlinelab} yt("Google trends index")
	graph export ..\output\gt_vihsifilis_Week.pdf, replace
	
	import delimited using "`path_gt'gt_hiv_sifilis_032018.csv", clear  varnames(2) 
	clean_raw_gt
	tempfile vihsifilis
	save    `vihsifilis'

	import delimited using "`path_gt'gt_hivsifexam_032018.csv", clear  varnames(2) 
	clean_raw_gt
	rename examenvihexamensidatestelisachil vihexam
	rename examensifilisvdrlchile sifexam

	merge 1:1 Week using `vihsifilis', nogen assert(3)
	
	lab var vihexam "HIV/AIDS + testing"
	lab var sifexam "Syphilis + testing"
	lab var vihsidachile "HIV/AIDS"
	lab var sifilischile "Syphilis"
	sort Week
	//keep if inrange(Week,tw(2016w1),tw(2018w1))
	tw (line vihexam Week, lc(midgreen)) (line sifexam Week, lc(purple)) ///
		, ${wb} ${hiv5_Week_tlinelab} yt("Google trends index") // legend(on order(1))
	graph export ..\output\gt_vihexamen_Week_032018.pdf, replace
	tw (line vihsida Week, lc(midgreen)) (line sifilis Week, lc(purple)) ///
		, ${wb} ${hiv5_Week_tlinelab} yt("Google trends index")
	graph export ..\output\gt_vihsifilis_Week_032018.pdf, replace
end

program clean_raw_gt
	gen Week = wofd(date(week,"YMD"))
	format %tw Week
	drop if Week==Week[_n+1]
	drop week
end

program scale_var
syntax, scale_var(varname)
	gen dd = `scale_var' / `scale_var'0
	sum dd
	replace `scale_var' = int(`r(mean)'*`scale_var'0) if !mi(`scale_var'0)
	drop dd `scale_var'0
end

main
 
