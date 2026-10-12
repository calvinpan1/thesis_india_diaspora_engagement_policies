*********************************************************************************
/*	TITLE:		4_6_fig_investor_names
*	PURPOSE:	Figure 2: share of projects, unique investors, and capital
*				that come from investors with possibly Indian names.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0402
*	UPDATED:	2026_1012
*	CALLS UPON:	"${rawdata}/fdi_extracts/2_2_investor_name_shares.csv"
*	PRODUCES:	Figures:	"${figures}/4_6_fig2_indian_name_shares.png"
*				Tables:		No
*				Datasets:	No
*	CONTENTS:	0: Start log file
*				1: Figure 2
*				2: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/4_6_fig_investor_names.log", replace text name(stage)

********
*
*	1. Figure 2: Diaspora vs non-diaspora shares
*
********

	import delimited using "${rawdata}/fdi_extracts/2_2_investor_name_shares.csv", clear varnames(1)

	// "diaspora" sits on top
	gen status_order = cond(diaspora_status == "diaspora", 1, 2)

	graph hbar project_share investor_share capital_share, ///
		over(diaspora_status, sort(status_order) descending label(labsize(medsmall))) ///
		title("Diaspora vs non-diaspora shares") ///
		ytitle("Percent") ///
		legend(order(1 "Projects" 2 "Unique investors" 3 "Capital") rows(1)) ///
		blabel(bar, format(%4.1f) position(outside)) ///
		graphregion(color(white))
	graph export "${figures}/4_6_fig2_indian_name_shares.png", replace width(2400)

********
*
*	2. Close log file
*
********

	log close stage
