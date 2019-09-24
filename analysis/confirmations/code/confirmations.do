/* **** ANEXO 4 *** https://www.minsal.cl/sites/default/files/files/GPCVIH.pdf
_____________________________________________________________________________________
CODE	|					INGRESO 	TARinicio 	TARexito	Frequency
0306169	| Elisa VIH				X
		| Recuento de Iinf CD4	X			X			X		3-6 months
0306069	| Carga viral VIH (CV)	X			X			X		3-6 months
0305063	| HLA-B*5701 Test					X					Genetic     //0801860-42
0301045	| Hemograma y VHS		X			X			X		1st, 3-6 months
0302075	| Perfil bioquimico		X			X			X		6-12 months
		| Lipidos 				X			X			X		6-12 months
0302076	| Pruebas hepaticas		X			X			X		1st, 3rd, 6-12 months
		| Glicemia				X			X			
0302023	| Creatininemia			X			X			X		Yearly
0309022	| Orina completa		X			X			X		Yearly
		| VDRL o RPR			X			X			X		Yearly
		| HBsAg y anti VHB		X			X			X		Yearly
0306081	| Serologia VHC			X								Depending on risk
		| IgG Toxoplasma gondii	X			
		| Serologia Chagas		X 			
0401009	| Rx torax				X			
		| PPD					X			
		| PAP, women			X						X		6-12 months?
_____________________________________________________________________________________*/
clear all
set more off

program main
	qui do "..\globals.do"
	use "..\..\..\derived\clean\output\hiv_conf.dta", clear
	clean_confirmations
	save "..\temp\confirmations.dta", replace
	
	use "..\temp\confirmations.dta", clear
	keep id_b Week_hiv Week_co
	duplicates drop
	save "..\temp\confirmations_list.dta", replace
	
	use "..\temp\confirmations.dta", clear
	plot_tests_after_HIV_test

end

program plot_tests_after_HIV_test	
	sum  t_hiv_pb if c_post==1 & inrange(t_hiv_pb,-50,50), det //
	hist t_hiv_pb if c_post==1 & inrange(t_hiv_pb,-50,50), ${wb} w(1) d frac
	graph export "../output/weeks_HIV_post.pdf", replace
	hist t_hiv_pb if c_post==1 & n_post==1 & t_hiv_pb<50 , ${wb} w(1) d frac
	graph export "../output/weeks_HIV_post_first.pdf", replace
	
	count if t_hiv_pb==0
	local n0 = r(N)
	count if c_post==1 & n_post==1 & t_hiv_pb<13
	local n1 = int(r(N)/`n0'*10000)/100
	di "Individuals with first tests within 12 weeks of HIV test: " `n1' "%"
	
	sum  t_hiv_pb if c_lin==1, det
	hist t_hiv_pb if c_lin==1, ${wb} w(1) d frac
	graph export "../output/weeks_lin.pdf", replace

	sum  t_hiv_pb if c_tar==1, det
	hist t_hiv_pb if c_tar==1, ${wb} w(1) d frac
	graph export "../output/weeks_tar.pdf", replace
end

capture program drop clean_confirmations
program clean_confirmations
	drop index
	todate date     , p(yyyymmdd) f(%td) g(date_pb)	
	todate date_conf, p(yyyymmdd) f(%td) g(date_co)
	drop date date_conf
	* Drop if confirmation date is earlier than sample
	sum id_b if date_co==td(01jan1800)
	drop if id_b==r(mean)
	drop if date_co<td(01jan2012)
	* Keep if had an HIV test
	bys id_b (date_pb id_m): egen n_hiv = total(c_hiv)
	drop if n_hiv==0
	* Find hiv date closest to confirmation event and keep those <=0
	gen t_hiv_co0 = date_pb - date_co if c_hiv==1
	bys id_b (date_pb id_m): egen date_hiv = max(cond(t_hiv_co0<=0,date_pb,.))
	bys id_b (date_pb id_m): egen date_hiv2 = min(cond((t_hiv_co0>0)&(!mi(t_hiv_co0)),date_pb,.))
	replace date_hiv = date_hiv2 if mi(date_hiv)
	format %td date_hiv
	drop date_hiv2

	bys id_b (t_hiv_co0 id_m): replace t_hiv_co0 = t_hiv_co0[1] if mi(t_hiv_co0)
	gen t_hiv_co = date_hiv-date_co
	lab var t_hiv_co "Days between HIV test and confirmation event"
	gen t_hiv_pb = date_pb - date_hiv
	lab var t_hiv_pb  "Days between HIV test and health service"
	hist t_hiv_co if inrange(t_hiv_co,-200,100) & date_pb==date_hiv, ${wb} w(1) d frac legend(off) ///
		addplot(pci 0 -60 .04 -60,lc(red) || pci 0 0 .04 0,lc(red))
	graph export "../output/days_HIV_confirmation.pdf", replace
	
	bys id_b (date_pb id_m): egen seq_id0 = seq()
	count if seq_id0 ==1
	local n0 = r(N)
	count if seq_id0 ==1 & inrange(t_hiv_co,-60,0)
	local n1 = int(r(N)/`n0'*10000)/100
	di "Individuals with HIV test within 60 days of confirmation: " `n1' "%"
	
	drop seq_id0 t_hiv_co0
	keep if inrange(t_hiv_co,-60,0)
	rename code7 code7num	
	gen code7 = string(code7num,"%07.0f")
	drop code7num
	merge m:1 code7 using "D:\Personal Directory\Catalina\Google_Drive\Projects\health_shock\codes\dic_codes_all.dta", keep(1 3) nogen
	gen c_doc = inlist(code_type,"docvisit","spevisit") | inlist(code7,${code_gyn},"0307011") //venosa
	gen c_chk = inlist(code7,${code_pan}) | inlist(code7,${code_pap}) | inlist(code7,${code_psa}) |  inlist(code_type,"prevscre")
	gen c_hos = (code_type=="hospital")
	gen c_tar = inlist(code7,${code_tar})
	gen c_cvi = inlist(code7,${code_cvi})
	gen Week = wofd(date_pb)
	gen Week_hiv = wofd(date_hiv) //date_hiv
	gen Week_co  = wofd(date_co) //date_hiv
	format %tw Week_hiv Week Week_co
	format %tw Week_hiv Week	
	gen post_Week   = Week - Week_hiv
	assert !mi(Week)
	sort id_b id_m date_pb
	drop date_*
	collapse  (max) c_* (firstnm) post_Week Week_hiv Week_co, by(id_b Week)
	gen t_hiv_pb = Week - Week_hiv
	lab var t_hiv_pb  "Weeks between HIV test and health service"
	isid id_b Week
	gen c_post = max(c_lin,c_cvi,c_tar)
	bys id_b (Week): gen n_lin  = sum(c_lin)  if c_lin==1  & t_hiv_pb>=0
	bys id_b (Week): gen n_cvi  = sum(c_cvi)  if c_cvi==1  & t_hiv_pb>=0
	bys id_b (Week): gen n_tar  = sum(c_tar)  if c_tar==1  & t_hiv_pb>=0
	bys id_b (Week): gen n_post = sum(c_post) if c_post==1 & t_hiv_pb>=0
end

main

