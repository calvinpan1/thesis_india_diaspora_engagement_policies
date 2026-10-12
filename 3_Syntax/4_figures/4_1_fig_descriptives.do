*********************************************************************************
/*	TITLE:		4_1_fig_descriptives
*	PURPOSE:	Descriptive figures for FDI, diasporas, and DEPs by Indian state.
*				Figures 5.2-5.7: FDI projects, value, and jobs (also Fig 6.1)
*				Figure 5.8: Gujarati diaspora in its 10 biggest metros
*				Figures 5.9-5.10: diaspora population by state
*				Figures 5.11-5.14, 8.2: DEPs over time (also Figs 6.2, 8.1)
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0402
*	UPDATED:	2026_1012
*	CALLS UPON:	"${rawdata}/fdi_extracts/2_2_fdi_state_year_top50.csv"
*				"${gendata}/1_1_acs_india_microdata.dta"
*				"${gendata}/2_1_top50_metros.dta"
*				"${gendata}/2_4_s4_allgen_all.dta"
*				"${gendata}/2_3_deps_state_year.dta"
*	PRODUCES:	Figures:	"${figures}/4_1_fig5_*.png", "${figures}/4_1_fig8_2_*.png"
*				Tables:		No
*				Datasets:	No
*	CONTENTS:	0: Start log file, graph font
*				1: Program that draws one line per state
*				2: Figures 5.2-5.7, FDI by state
*				3: Figure 5.8, Gujarati diaspora by metro
*				4: Figures 5.9-5.10, diaspora by state
*				5: Figures 5.11-5.14 and 8.2, DEPs
*				6: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/4_1_fig_descriptives.log", replace text name(stage)

	// Matches the thesis font. Falls back to Stata's default if not installed.
	capture graph set window fontface "CMU Serif"

********
*
*	1. Program that draws one line per state
*
********

	// Expects data with indian_state ("Andhra Pradesh", ...), year, and the
	// variable to plot. Three styles:
	//	allstates:	adds an "All states" total line (Fig 5.7)
	//	allindia:	adds an all-India total, split at 2014 when Andhra Pradesh
	//				drops out so the line doesn't fake a drop (Figs 5.2, 5.6)
	//	statesonly:	just the 8 states (Figs 5.3-5.5, 5.9-5.11)

	capture program drop plot_by_state
	program define plot_by_state
		syntax , VAR(name) TITLE(string) YTITLE(string) FILE(string) STYLE(string) ///
			[AUTOXLABEL]

		// Default ticks every other year, or let Stata pick (Fig 5.11)
		local xlabel "2005(2)2017"
		if "`autoxlabel'" != "" local xlabel ""
		local states `""Andhra Pradesh" "Gujarat" "Karnataka" "Kerala" "Maharashtra" "Punjab" "Tamil Nadu" "West Bengal""'

		preserve
			**Extra total lines

				if "`style'" == "allstates" {
					tempfile total
					collapse (sum) `var', by(year)
					gen indian_state = "All states"
					save `total'
					restore, preserve
					append using `total'
					local extra `""All states""'
				}
				if "`style'" == "allindia" {
					tempfile pre post
					collapse (sum) `var', by(year)
					gen indian_state = "All India observations (through 2013)"
					replace `var' = . if year > 2013
					save `pre'
					restore, preserve
					collapse (sum) `var', by(year)
					gen indian_state = "All India observations (2015-2017)"
					replace `var' = . if year < 2015
					save `post'
					restore, preserve
					append using `pre' `post'
					local extra `""All India observations (through 2013)" "All India observations (2015-2017)""'
				}

			**One line per group, legend in the same order

				local lines ""
				local legend ""
				local i = 0
				foreach s in `extra' `states' {
					local ++i
					local lines `"`lines' (line `var' year if indian_state == "`s'", sort)"'
					local legend `"`legend' `i' "`s'""'
				}

				local cols = cond("`style'" == "statesonly", 4, 3)
				local legsize = cond("`style'" == "allindia", "8pt", "9pt")

				graph twoway `lines', ///
					title("`title'", size(12pt)) ///
					ytitle("`ytitle'", size(12pt)) ///
					xtitle("Year", size(12pt)) ///
					xlabel(`xlabel', labsize(10pt)) ///
					ylabel(, labsize(10pt) angle(horizontal)) ///
					legend(order(`legend') position(6) ring(1) cols(`cols') size(`legsize') region(lstyle(none))) ///
					graphregion(color(white))
				graph export "${figures}/`file'", replace
		restore
	end

********
*
*	2. Figures 5.2-5.7: FDI by state, top-50 diaspora metros only
*
********

	import delimited using "${rawdata}/fdi_extracts/2_2_fdi_state_year_top50.csv", clear varnames(1)

	**Figures 5.4, 5.5, 5.7 (Andhra Pradesh shown as 0 after 2013)

		// Value and jobs are states only: a total line would dwarf every state
		plot_by_state, var(capital_real_all) style(statesonly) ///
			title("FDI project value over time (top 50 metros only)") ytitle("Real capital investment") ///
			file(4_1_fig5_4_fdi_value_by_state.png)
		plot_by_state, var(jobs_all) style(statesonly) ///
			title("All FDI jobs created over time (top 50 metros only)") ytitle("All FDI jobs created") ///
			file(4_1_fig5_5_fdi_jobs_by_state.png)
		plot_by_state, var(fdi_projects_consgoods) style(allstates) ///
			title("Consumer goods FDI projects over time (top 50 metros only)") ytitle("Consumer goods FDI projects") ///
			file(4_1_fig5_7_fdi_consumer_goods_by_state.png)

	**Figures 5.2 (= 6.1), 5.3, 5.6 (Andhra Pradesh line stops in 2013)

		replace fdi_projects_all = . if indian_state == "Andhra Pradesh" & year >= 2014
		replace fdi_projects_ict = . if indian_state == "Andhra Pradesh" & year >= 2014

		plot_by_state, var(fdi_projects_all) style(allindia) ///
			title("FDI projects over time (top 50 metros only)") ytitle("FDI projects") ///
			file(4_1_fig5_2_fdi_projects_by_state.png)
		plot_by_state, var(fdi_projects_all) style(statesonly) ///
			title("FDI projects over time (top 50 metros only)") ytitle("FDI projects") ///
			file(4_1_fig5_3_fdi_projects_by_state_no_total.png)
		plot_by_state, var(fdi_projects_ict) style(allindia) ///
			title("ICT FDI projects over time (top 50 metros only)") ytitle("ICT FDI projects") ///
			file(4_1_fig5_6_fdi_ict_projects_by_state.png)

********
*
*	3. Figure 5.8: Gujarati diaspora in its 10 biggest metros
*
********

	use "${gendata}/2_4_s4_allgen_all.dta", clear
	keep if languaged == 3115	// Gujarati
	collapse (sum) n_people, by(year met2013)

	**Find the 10 metros with the most Gujaratis over 2005-2017

		preserve
			collapse (sum) total = n_people, by(met2013)
			gsort -total
			keep in 1/10
			keep met2013
			tempfile top10
			save `top10'
		restore
		merge m:1 met2013 using `top10', keep(match) nogen

	**One line per metro, labeled by metro code

		levelsof met2013, local(metros)
		local lines ""
		local legend ""
		local i = 0
		foreach m of local metros {
			local ++i
			local lines `"`lines' (line n_people year if met2013 == `m', sort)"'
			local legend `"`legend' `i' "Metro `m'""'
		}

		graph twoway `lines', ///
			title("Gujarati diaspora in Sample 3 top 50-metro sample: top 10 metros", size(12pt)) ///
			ytitle("Estimated population", size(12pt)) ///
			xtitle("Year", size(12pt)) ///
			xlabel(2005(2)2017, labsize(10pt)) ///
			ylabel(, labsize(10pt) angle(horizontal)) ///
			legend(order(`legend') position(6) ring(1) cols(2) size(8pt) region(lstyle(none))) ///
			graphregion(color(white))
		graph export "${figures}/4_1_fig5_8_gujarati_top10_metros.png", replace

********
*
*	4. Figures 5.9-5.10: diaspora population by state, top-50 metros
*
********

	**Program: diaspora count by state-year for one definition of diaspora

		capture program drop diaspora_by_state
		program define diaspora_by_state
			syntax , KEEPIF(string)

			use "${gendata}/1_1_acs_india_microdata.dta", clear
			merge m:1 met2013 using "${gendata}/2_1_top50_metros.dta", keep(match) nogen
			keep if `keepif'
			drop if languaged == 4003 & inrange(year, 2014, 2017)
			collapse (sum) n_people = perwt, by(year languaged)

			gen indian_state = ""
			replace indian_state = "Kerala"			if languaged == 4004
			replace indian_state = "Tamil Nadu"		if languaged == 4005
			replace indian_state = "Gujarat"		if languaged == 3115
			replace indian_state = "Karnataka"		if languaged == 3130
			replace indian_state = "Maharashtra"	if languaged == 3114
			replace indian_state = "Punjab"			if languaged == 3113
			replace indian_state = "Andhra Pradesh"	if languaged == 4003
			replace indian_state = "West Bengal"	if languaged == 3112
			drop languaged

			// Every state-year shows up, with 0 if nobody's there
			fillin indian_state year
			replace n_people = 0 if missing(n_people)
			replace n_people = . if indian_state == "Andhra Pradesh" & year >= 2014
		end

	**Figure 5.9: first-gen (born in India), all 8 languages

		diaspora_by_state, keepif(firstgen_india & lang_first)
		plot_by_state, var(n_people) style(statesonly) ///
			title("First-gen all people (18+) over time (top 50 metros only)") ytitle("Estimated population") ///
			file(4_1_fig5_9_firstgen_diaspora_by_state.png)

	**Figure 5.10: all generations, all 8 languages

		// Includes Bengali speakers of any birthplace, as in the thesis figure.
		// (The all-gen regression sample drops Bengali, see Table 5.2.)
		diaspora_by_state, keepif(lang_first)
		plot_by_state, var(n_people) style(statesonly) ///
			title("Migrant stock over time (top 50 metros only)") ytitle("Estimated migrant stock") ///
			file(4_1_fig5_10_allgen_diaspora_by_state.png)

********
*
*	5. Figures 5.11-5.14 and 8.2: DEPs
*
********

	use "${gendata}/2_3_deps_state_year.dta", clear
	replace indian_state = proper(indian_state)

	**Figure 5.11 (= 6.2): total DEPs by state

		preserve
			keep if inrange(year, 2005, 2017)
			plot_by_state, var(total_deps) style(statesonly) autoxlabel ///
				title("Total DEPs over time by state") ytitle("Total DEPs") ///
				file(4_1_fig5_11_total_deps_by_state.png)
		restore

	**Figure 5.12: economic vs non-economic DEPs, all states stacked

		preserve
			keep if inrange(year, 2000, 2017)
			collapse (sum) total_non_econ total_econ, by(year)
			gen total_stack = total_non_econ + total_econ

			twoway ///
				(area total_stack year, sort color(cranberry%30) lcolor(cranberry)) ///
				(area total_econ year, sort color(navy%35) lcolor(navy)), ///
				title("Composition of DEPs: Economic vs Non-Economic (2000-2017)", size(12pt)) ///
				ytitle("Number of Policies", size(12pt)) ///
				xtitle("Year", size(12pt)) ///
				xlabel(2000(5)2017, labsize(10pt)) ///
				ylabel(, labsize(10pt) angle(horizontal)) ///
				legend(order(1 "total_non_econ" 2 "total_econ") ///
					position(6) ring(1) cols(2) size(9pt) region(lstyle(none))) ///
				graphregion(color(white))
			graph export "${figures}/4_1_fig5_12_econ_vs_nonecon_deps.png", replace
		restore

	**Category labels for the remaining figures ("total_state_bureaucracy" -> "State Bureaucracy")

		local nonecon total_symbolic total_religious_cultural total_citizenship total_state_bureaucracy total_abroad
		local econ total_networks total_info total_advantages
		foreach v in `nonecon' `econ' {
			local lab_`v' = proper(subinstr(subinstr("`v'", "total_", "", 1), "_", " ", .))
		}

	**Figure 8.2: economic DEP types over time, all states

		preserve
			keep if inrange(year, 2000, 2017)
			collapse (sum) `econ', by(year)
			local lines ""
			local legend ""
			local i = 0
			foreach v of local econ {
				local ++i
				local lines `"`lines' (line `v' year, sort)"'
				local legend `"`legend' `i' "`lab_`v''""'
			}
			graph twoway `lines', ///
				title("Economic DEP types over time (2000-2017)", size(12pt)) ///
				ytitle("Number of Policies", size(12pt)) ///
				xtitle("Year", size(12pt)) ///
				xlabel(2000(5)2017, labsize(10pt)) ///
				ylabel(, labsize(10pt) angle(horizontal)) ///
				legend(order(`legend') position(6) ring(1) cols(3) size(9pt) region(lstyle(none))) ///
				graphregion(color(white))
			graph export "${figures}/4_1_fig8_2_econ_dep_types.png", replace
		restore

	**Figures 5.13 and 5.14 (= 8.1): DEP categories by state in 2017

		keep if year == 2017
		foreach group in nonecon econ {
			local legend ""
			local i = 0
			foreach v of local `group' {
				local ++i
				local legend `"`legend' `i' "`lab_`v''""'
			}
			egen double sort_total = rowtotal(``group'')

			local title = cond("`group'" == "econ", "Breakdown of Economic DEPs by State (2017)", ///
				"Breakdown of Non-Economic DEPs by State (2017)")
			local file = cond("`group'" == "econ", "4_1_fig5_14_econ_deps_by_state_2017.png", ///
				"4_1_fig5_13_nonecon_deps_by_state_2017.png")

			graph hbar (asis) ``group'', ///
				over(indian_state, sort(sort_total) descending label(labsize(10pt))) ///
				stack ///
				title("`title'", size(12pt)) ///
				ytitle("State", size(12pt)) ///
				blabel(none) ///
				legend(order(`legend') position(6) ring(1) cols(3) size(9pt) region(lstyle(none))) ///
				graphregion(color(white))
			graph export "${figures}/`file'", replace
			drop sort_total
		}

********
*
*	6. Close log file
*
********

	log close stage
