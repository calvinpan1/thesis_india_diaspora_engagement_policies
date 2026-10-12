*********************************************************************************
/*	TITLE:		4_3_fig_budgets
*	PURPOSE:	Figure 4: DEP budgets by state, 2005-2017, in 2023 rupees with
*				an approximate US dollar axis on the right.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0405
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/2_3_dep_budgets_state_year.dta"
*	PRODUCES:	Figures:	"${figures}/4_3_fig4_dep_budgets_by_state.png"
*				Tables:		No
*				Datasets:	No
*	CONTENTS:	0: Start log file, graph font
*				1: Convert units
*				2: Figure 4
*				3: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/4_3_fig_budgets.log", replace text name(stage)

	capture graph set window fontface "CMU Serif"

********
*
*	1. Convert units
*
********

	use "${gendata}/2_3_dep_budgets_state_year.dta", clear

	gen double budget_cr = nri_budget_2023inr / 10000000	// rupees -> crores

	// Rough USD axis: crores of 2023 rupees -> millions of 2026-ish dollars.
	// FRED EXINUS (Feb 2026) = 90.7458 INR per USD. FRED GDPDEF annual means:
	// 2023 = 122.38175, latest full year (2025) = 128.96375.
	local usd_m_per_crore = (10000000 / 90.7458) / 1000000 * (128.96375 / 122.38175)
	gen double budget_usd_m = budget_cr * `usd_m_per_crore'

	// Only the four states with positive DEP budgets get a line
	foreach s in andhra kerala punjab tamil {
		local name = cond("`s'" == "andhra", "Andhra Pradesh", cond("`s'" == "tamil", "Tamil Nadu", proper("`s'")))
		gen budget_`s' = budget_cr if state == "`name'"
		gen usd_`s' = budget_usd_m if state == "`name'"
	}

********
*
*	2. Figure 4: DEP budgets
*
********

	// The four invisible lines on axis 2 are only there to scale the dollar axis
	twoway ///
		(connected budget_andhra year, sort lcolor(navy)       mcolor(navy)       msymbol(circle)   msize(small) lwidth(medthick) yaxis(1)) ///
		(connected budget_kerala year, sort lcolor(orange_red) mcolor(orange_red) msymbol(diamond)  msize(small) lwidth(medthick) yaxis(1)) ///
		(connected budget_punjab year, sort lcolor(purple)     mcolor(purple)     msymbol(square)   msize(small) lwidth(medthick) yaxis(1)) ///
		(connected budget_tamil  year, sort lcolor(gold)       mcolor(gold)       msymbol(triangle) msize(small) lwidth(medthick) yaxis(1)) ///
		(connected usd_andhra year, sort lcolor(none) mcolor(none) msymbol(none) lwidth(none) yaxis(2)) ///
		(connected usd_kerala year, sort lcolor(none) mcolor(none) msymbol(none) lwidth(none) yaxis(2)) ///
		(connected usd_punjab year, sort lcolor(none) mcolor(none) msymbol(none) lwidth(none) yaxis(2)) ///
		(connected usd_tamil  year, sort lcolor(none) mcolor(none) msymbol(none) lwidth(none) yaxis(2)), ///
		title("DEP Budgets by State Over Time", size(14pt)) ///
		subtitle("Left axis: 2023 INR crores; right axis: approx. USD millions", size(10pt)) ///
		xtitle("Year", size(11pt)) ///
		ytitle("Budget (2023 INR crores)", size(11pt) axis(1)) ///
		ytitle("Approx. budget (USD millions, 2026 proxy)", size(11pt) axis(2)) ///
		xlabel(2005(5)2020, labsize(8pt)) ///
		ylabel(0(100)500, axis(1) labsize(8pt) angle(horizontal) format(%9.0f) grid glcolor(gs14)) ///
		ylabel(, axis(2) labsize(8pt) angle(horizontal) format(%9.1f)) ///
		yscale(range(0 500) axis(1)) ///
		yscale(axis(2) alt) ///
		legend(order(1 "Andhra Pradesh" 2 "Kerala" 3 "Punjab" 4 "Tamil Nadu") ///
			rows(1) size(8pt) position(6) ring(1) region(lstyle(none))) ///
		graphregion(color(white)) ///
		plotregion(color(white) margin(medium))
	graph export "${figures}/4_3_fig4_dep_budgets_by_state.png", replace

********
*
*	3. Close log file
*
********

	log close stage
