//==============================================================================
//	Threshold Regression & Quantile Estimation Model
//==============================================================================
//	Written	by Herman Sahni, Baldwin Wallace University
//	version: 12/04/2019
//------------------------------------------------------------------------------
// This stata code reproduces the results of the following article:
// Sahni, H., Nsiah, C., and Fayissa, B. (2020) "The African Economic Growth 
// Experience and Tourism Receipts: A Threshold Analysis and Quantile Regression 
// Approach," Tourism Economics (online). DOI: 10.1177/1354816620908688
//==============================================================================
clear all 
capture log close 
set more off 

//==============================================================================
// CREATE LOG FILE
//==============================================================================
log using "C:\data\tourism\tourism_threshold", replace
	cd "C:\data\tourism" 

program mean
	summarize ‘1’, meanonly
	display " mean = " r(mean)
end
// mean varname 

//==============================================================================
// SET ALL GLOBAL MACROS 
//==============================================================================
	global startyear = 2002  
	global endyear   = 2015  
	global bootstrp  = 1000  
	
//	DEPENDENT VARIABLE 
	global depvar "pcigp" // GDP per capita growth/100 (annual) 

//	MAIN INDEPENDENT VARIABLE 
	global indvar "trec2gdp" //  Tourism/GDP ratio 

//	LIST OF CONTROL VARIABLES 
	local cvars     gfcf2gdp     /// Gross fixed capital formation/GDP 
					govex2gdp    /// Govt. final consumption exp/GDP 			
					semiloginfla /// Semi-log transformation of Infla rate 
					popgp        /// Population growth (annual %)
					ntotp        /// Net barter terms of trade index/100 
					ntotpsq      /// Square-root of terms of trade 
					tradep       /// Trade/GDP 
					log_meansch  /// Mean schooling (years) 		
					log_pcicol   /// Lag of Log(GDP per capita)
					log_polity2  /// Political regime index 		
					log_civtot   /// Political instability index 

	global ctrlvars "`cvars'" // array of control variables 





use finaldat , clear // contains the balanced panel of all African countries


//==============================================================================
//	DATA RESTRICTIONS
//==============================================================================

	keep if inrange(year, $startyear , $endyear) 
	keep ccode CountryName year $depvar $indvar $ctrlvars 

//==============================================================================
// set panel variables 
//==============================================================================

	xtset ccode year 
	tsset ccode year 

//==============================================================================
//	DESCRIBE DATA 
//==============================================================================

	xtdescribe // list available time-series, by country 
	
	xtpatternvar, gen(pattern) // list available time-series, count 
		tab pattern 
		
	nmissing // list missing obs, by variable 
	npresent // list non-missing obs, by variable 

	levelsof CountryName // list the countries in the final sample

//==============================================================================
//	SUMMARIZE ALL VARIABLES 
//==============================================================================

	sum $depvar $indvar $ctrlvars // PRELIMINARY SUMMARY 

//==============================================================================
//	OPTIMAL NUMBER OF THRESHOLDS - SET TO 3
//==============================================================================
	xthreg $depvar $ctrlvars , rx($indvar) qx($indvar) thnum(3) bs($bootstrp $bootstrp $bootstrp) grid(400) trim(0.05 0.05 0.05) nobslog vce(robust)	

//==============================================================================
//	XTHREG SPECIFICATION - SINGLE THRESHOLD MODEL
//==============================================================================
	xthreg $depvar $ctrlvars , rx($indvar) qx($indvar) thnum(1) bs($bootstrp) grid(400) trim(0.05) nobslog vce(robust)	
	
	matrix c = e(Thrss) // store the threshold matrix 
	matrix list c 
	
	di _n "{p}Threshold.{p_end}"
	gen c1 = c[1,1] // obtain the single threshold value from the threshold matrix
	di _n c1 

	global thresholdvalue = c1 // store the single threshold value 
	di _n "{p}Threshold is ...{p_end}"
	di    "$thresholdvalue" 

//==============================================================================
//	CREATE PRE-THRESHOLD & POST-THRESHOLD VARIABLES 
//==============================================================================
	gen threshold1 = $indvar if $indvar <= c1  
	replace threshold1 = 0    if $indvar >  c1  
	replace threshold1 = .    if missing($indvar) 
	label variable threshold1 "Threshold level: <= `c1'"  

	gen threshold2 = $indvar if $indvar >  c1
	replace threshold2 = 0    if $indvar <= c1   
	replace threshold2 = . if missing($indvar) 
	label variable threshold2 "Threshold level: > `c1'"  	

//==============================================================================
//	XTRIFREG SPECIFICATION 
//==============================================================================
	// threshold model
	xtrifreg $depvar $ctrlvars threshold1 threshold2 , /// 
	                           fe i(ccode) quantile(0.25) reps($bootstrp) 

	xtrifreg $depvar $ctrlvars threshold1 threshold2 , /// 
	                           fe i(ccode) quantile(0.50) reps($bootstrp) 

	xtrifreg $depvar $ctrlvars threshold1 threshold2 , /// 
	                           fe i(ccode) quantile(0.75) reps($bootstrp) 

	// no threshold model
	xtrifreg $depvar $ctrlvars $indvar , /// 
	                           fe i(ccode) quantile(0.25) reps($bootstrp) 

	xtrifreg $depvar $ctrlvars $indvar , /// 
	                           fe i(ccode) quantile(0.50) reps($bootstrp) 

	xtrifreg $depvar $ctrlvars $indvar , /// 
	                           fe i(ccode) quantile(0.75) reps($bootstrp) 

//==============================================================================
//	QUANTILE PLOT - XTQREG 
//==============================================================================
	local quantiles 10 20 30 40 50 60 70 80 90  // K quantiles that you care about
	local models1 ""                            // names of K quantile models for coefplot to graph 
	local models2 ""                            // names of K quantile models for coefplot to graph 
	local xlabel  ""                            // for x-axis labels
	local j=1                                   // counter for quantiles

	foreach q of numlist `quantiles' {
		xtrifreg $depvar $ctrlvars threshold1 threshold2 , /// 
	                           fe i(ccode) quantile(0.`q') reps($bootstrp) 

		nlcom (me_tu1:_b[threshold1]), post
		estimates store me_tu1`q' 
			local models1 `"`models1' me_tu1`q' ||  "' 

	
		xtrifreg $depvar $ctrlvars threshold1 threshold2 , /// 
	                           fe i(ccode) quantile(0.`q') reps($bootstrp) 

		nlcom (me_tu2:_b[threshold2]), post
		estimates store me_tu2`q'
			local models2 `"`models2' me_tu2`q' ||  "' 
		
		local xlabel  `"`xlabel' `j++' "Q{sub:`q'}""'
	} 
	
	di "`models1'" 
	di "`models2'" 
	di `"`xlabel'"'

	local strx1 = "Tourism/GDP <= " + string(c1) 
	di "`strx1'"
	
	local strx2 = "Tourism/GDP > " + string(c1) 
	di "`strx2'"
	
	coefplot `models1' , vertical  pstyle(p3) bycoefs byopts(xrescale) xlab(none) ///  
                    xlabel(`xlabel', add) title(`strx1')  /// 
                    ylabel(-0.50(0.25)2.0, angle(horizontal) format(%9.2f))   ///  
                    ytitle("Coefficient {stSymbol:d}{sub:1}") mcolor(black)   ///
					recast(line) lwidth(*2) ciopts(recast(rline) lpattern(dash)) 

		graph save threshold1 , replace
		graph export "C:\data\tourism\threshold\threshold1.png", as(png) replace 
		
	coefplot `models2' , vertical  pstyle(p4) bycoefs byopts(xrescale) xlab(none) ///  
                    xlabel(`xlabel', add) title(`strx2')   /// 
                    ylabel(-0.50(0.25)2.0, angle(horizontal) format(%9.2f))   ///  
                    ytitle("Coefficient {stSymbol:d}{sub:2}") mcolor(black)   /// 
					recast(line) lwidth(*2) ciopts(recast(rline) lpattern(dash)) 

		graph save threshold2 , replace
		graph export "C:\data\tourism\threshold\threshold2.png", as(png) replace

//==============================================================================
//	HOUSE KEEPING 
//==============================================================================
/*
local list "finaldat"
foreach f of local list {
    mi erase "`f'"
}
*/
********************************************************************************/
********** CLOSE OUTPUT
log close
