* Plots
	//global color_list = "blue green red orange gray"
	global list_lp = "longdash dash dash_dot shortdash shortdast_dot solid"
	global list_lc_gray = "gs13 gs11 gs9 gs7 gs5"
	global list_lc = "midgreen purple cranberry midblue orange gray"
	global wb = "graphregion(color(white)) bgcolor(white)"


* Dates and labels HIV
*                                    20121127       20131205       20150605       20151201       20170803
	global hiv_Week_all    = "2012w1 2012w48        2013w49        2015w23        2015w50        2017w31 2018w1"
	global hiv_Week        =        "2012w48        2013w49        2015w23        2015w50        2017w31"
	global hiv_Week_lab            `"2012w48 "(#1)" 2013w49 "(#2)" 2015w23 "(#3)" 2015w50 "(#4)" 2017w31 "(#5)""'
	global hiv_Month_all   = "2012m1 2012m11        2013m12        2015m6         2015m12        2017m8  2018m1"
	global hiv_Month       =        "2012m11        2013m12        2015m6         2015m12        2017m8"
	global hiv_Month_lab           `"2012m11 "(#1)" 2013m12 "(#2)" 2015m6  "(#3)" 2015m12 "(#4)" 2017m8  "(#5)""'
	global hiv_Quarter_all = "2012q1 2012q4         2013q4         2015q3         2015q4         2017q3  2018q1"
	global hiv_Quarter     =        "2012q4         2013q4         2015q3         2015q4         2017q3"
	global hiv_Quarter_lab         `"2012q4  "(#1)" 2013q4  "(#2)" 2015q3  "(#3)" 2015q4  "(#4)" 2017q3  "(#5)""'
	global hiv_Week_tlinelab    = `"tline(${hiv_Week}, lc(black) lp(dash)) tmlab(${hiv_Week_lab}, tp(inside) labs(*0.9) labgap(*.3))"'
	global hiv_Month_tlinelab   = `"tline(${hiv_Month}, lc(black) lp(dash)) tmlab(${hiv_Month_lab}, tp(inside) labs(*0.9) labgap(*.3))"'
	global hiv_Quarter_tlinelab = `"tline(${hiv_Quarter}, lc(black) lp(dash)) tmlab(${hiv_MQuarter_lab}, tp(inside) labs(*0.9) labgap(*.3))"'
	

* Dates 2017 campaign
	global hiv5_Day_R        =  "20Jul2017"
	global hiv5_Day_A        =  "28Jul2017"
	global hiv5_Day_L        =  "03Aug2017"
	global hiv5_Week_R       =  "2017w29"
	global hiv5_Week_A       =  "2017w30"
	global hiv5_Week_L       =  "2017w31"
	global hiv5_Day             "20Jul2017     28Jul2017     03Aug2017"
	global hiv5_Day_lab        `"20Jul2017 "R" 28Jul2017 "A" 03Aug2017 "L""'
	global hiv5_Week         =  "2017w29       2017w30       2017w31"
	global hiv5_Week_lab       `"2017w29   "R" 2017w30   "A" 2017w31 "L""'
	global hiv5_Day_tlinelab    = `"tline(20Jul2017 28Jul2017 03Aug2017, lc(black) lp(dash)) tmlab(${hiv5_Day_lab}, tp(inside) labs(*0.9) labgap(*.3))"'
	global hiv5_Week_tlinelab = `"tline(2017w29 2017w30, lc(gs8) lp(shortdash)) tline(2017w31, lc(black) lp(dash)) tmlab(${hiv5_Week_lab}, tp(inside) labs(*0.9) labgap(*.3))"'
 
