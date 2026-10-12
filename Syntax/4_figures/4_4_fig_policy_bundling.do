*********************************************************************************
/*	TITLE:		4_4_fig_policy_bundling
*	PURPOSE:	Figures on DEP co-adoption and adoption timing.
*				Figure 5.15: how many policy pairs fall in each Jaccard range
*				Figure 5.16 (= 6.3): when each state created a diaspora admin unit
*				Unnumbered figure after Figure 8.2: adoption timing for the
*				informational DEPs
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0412
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/3_2_policy_pair_jaccard.dta" (made by 3_2_tab_policy_bundling.do)
*				"${gendata}/2_3_dep_turnons_long.dta"
*	PRODUCES:	Figures:	"${figures}/4_4_fig5_15_jaccard_distribution.png"
*							"${figures}/4_4_fig5_16_admin_unit_timing.png"
*							"${figures}/4_4_fig8_x_info_policy_timing.png"
*				Tables:		No
*				Datasets:	No
*	CONTENTS:	0: Start log file
*				1: Figure 5.15, Jaccard distribution
*				2: Program for adoption-timing dot plots
*				3: Figure 5.16, diaspora admin unit timing
*				4: Unnumbered figure after 8.2, informational DEP timing
*				5: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/4_4_fig_policy_bundling.log", replace text name(stage)

********
*
*	1. Figure 5.15: Policy-pair Jaccard distribution
*
********

	use "${gendata}/3_2_policy_pair_jaccard.dta", clear

	gen byte jaccard_bin = floor(jaccard * 10)
	replace jaccard_bin = 9 if jaccard_bin == 10	// put exactly 1.0 in the top bin
	collapse (count) pair_count = jaccard, by(jaccard_bin)

	label define jaccard_bin ///
		0 "0.0-0.1" 1 "0.1-0.2" 2 "0.2-0.3" 3 "0.3-0.4" 4 "0.4-0.5" ///
		5 "0.5-0.6" 6 "0.6-0.7" 7 "0.7-0.8" 8 "0.8-0.9" 9 "0.9-1.0"
	label values jaccard_bin jaccard_bin

	twoway bar pair_count jaccard_bin, ///
		barwidth(.8) ///
		xlabel(0(1)9, valuelabel angle(45)) ///
		ytitle("Number of policy pairs") ///
		xtitle("Jaccard range") ///
		title("Policy-pair Jaccard distribution") ///
		graphregion(color(white))
	graph export "${figures}/4_4_fig5_15_jaccard_distribution.png", replace width(3200) height(2000)

********
*
*	2. Program for adoption-timing dot plots
*
********

	// One row per state, a dot at the year it first adopted the policy.
	// Expects indian_state and first_year. "Never", "Pre-2005" and
	// "Post-2017" get their own spots on the axis unless ADMINUNIT is set.

	capture program drop timing_plot
	program define timing_plot
		syntax , TITLE(string) NAME(name) [ADMINUNIT]

		gen yorder = .
		local i = 0
		foreach s in "karnataka" "kerala" "maharashtra" "west bengal" ///
			"andhra pradesh" "gujarat" "punjab" "tamil nadu" {
			local ++i
			replace yorder = `i' if indian_state == "`s'"
		}
		local ylab `"1 "Karnataka" 2 "Kerala" 3 "Maharashtra" 4 "West Bengal" 5 "Andhra Pradesh" 6 "Gujarat" 7 "Punjab" 8 "Tamil Nadu""'

		if "`adminunit'" != "" {
			gen plot_year = cond(missing(first_year), 1994, first_year)
			twoway ///
				(scatter yorder plot_year if !missing(first_year), msymbol(O) msize(medlarge) mcolor(green) mfcolor(green)) ///
				(scatter yorder plot_year if missing(first_year), msymbol(X) msize(medlarge) mcolor(red)), ///
				xline(2005, lpattern(solid) lcolor(blue)) ///
				xline(2017, lpattern(solid) lcolor(blue)) ///
				xscale(range(1994 2025)) ///
				xlabel(1994 "Never" 1995(5)2025, angle(35) labsize(vsmall)) ///
				yscale(range(0.5 8.5)) ///
				ylabel(`ylab', angle(0) noticks labsize(small)) ///
				xtitle("") ytitle("") ///
				title("`title'", size(small)) ///
				legend(off) ///
				graphregion(color(white)) plotregion(margin(small)) ///
				xsize(8.2) ysize(4.2) name(`name', replace)
		}
		else {
			// Filled dot = adopted 2005-2017, open dot = outside the sample years
			gen byte inside = inrange(first_year, 2005, 2017)
			gen plot_year = first_year
			replace plot_year = 2003 if missing(first_year)
			replace plot_year = 2004 if first_year < 2005
			replace plot_year = 2018 if first_year > 2017 & !missing(first_year)
			twoway ///
				(scatter yorder plot_year if inside, msymbol(O) msize(medlarge) mcolor(green) mfcolor(green)) ///
				(scatter yorder plot_year if !inside & !missing(first_year), msymbol(Oh) msize(medlarge) mcolor(green) mfcolor(none)) ///
				(scatter yorder plot_year if missing(first_year), msymbol(X) msize(medlarge) mcolor(red)), ///
				xline(2005, lpattern(dash) lcolor(gs12)) ///
				xline(2017, lpattern(dash) lcolor(gs12)) ///
				xscale(range(2003 2018)) ///
				xlabel(2003 "Never" 2004 "Pre-2005" 2005(5)2015 2017 "2017" 2018 "Post-2017", angle(35) labsize(vsmall)) ///
				yscale(range(0.5 8.5)) ///
				ylabel(`ylab', angle(0) noticks labsize(small)) ///
				xtitle("") ytitle("") ///
				title("`title'", size(small)) ///
				legend(off) ///
				graphregion(color(white)) plotregion(margin(small)) ///
				xsize(7.5) ysize(4.2) name(`name', replace)
		}
	end

	**First year each state has each policy (any year in the data, not just 2005-2017)

		use "${gendata}/2_3_dep_turnons_long.dta", clear
		keep if item_type == "policy"
		collapse (min) first_year = year if value > 0, by(item indian_state)
		tempfile first_years
		save `first_years'

		// Every state, so states that never adopt still get a row
		use "${gendata}/2_3_dep_turnons_long.dta", clear
		keep indian_state
		duplicates drop
		tempfile states
		save `states'

********
*
*	3. Figure 5.16 (= 6.3): Diaspora admin unit adoption timing
*
********

	use `first_years', clear
	keep if item == "diaspora_admin_unit"
	merge 1:1 indian_state using `states', nogen

	// Kerala (1996) and Gujarat (1998) set theirs up before the DEP data starts
	replace first_year = 1996 if indian_state == "kerala"
	replace first_year = 1998 if indian_state == "gujarat"

	timing_plot, title("Diaspora Admin Unit Adoption Timing") name(admin_unit) adminunit
	graph export "${figures}/4_4_fig5_16_admin_unit_timing.png", replace width(4200) height(2550)

********
*
*	4. Unnumbered figure after Figure 8.2: informational DEP timing
*
********

	// Every informational policy that any state ever adopts, one panel each
	use "${gendata}/2_3_dep_turnons_long.dta", clear
	keep if category == "total_info" & item_type == "policy"
	bysort item: egen ever = max(turned_on)
	keep if ever
	by item: keep if _n == 1
	sort item_order		// panels in DEP-data order, not alphabetical
	local info_policies ""
	forvalues i = 1/`=_N' {
		local info_policies `info_policies' `=item[`i']'
	}

	local panels ""
	foreach p of local info_policies {
		use `first_years', clear
		keep if item == "`p'"
		merge 1:1 indian_state using `states', nogen
		local title = proper(subinstr("`p'", "_", " ", .))
		timing_plot, title("`title'") name(g_`p')
		local panels `panels' g_`p'
	}

	graph combine `panels', ///
		cols(2) imargin(vsmall) ///
		title("Policy Adoption Timing: Total Info", size(medsmall)) ///
		note("Open circles = pre-2005/post-2017 adoption; X = never treated", size(vsmall)) ///
		graphregion(color(white) margin(small)) ///
		xsize(14) ysize(8.5)
	graph export "${figures}/4_4_fig8_x_info_policy_timing.png", replace width(4200) height(2550)
	graph drop _all

********
*
*	5. Close log file
*
********

	log close stage
