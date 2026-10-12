*********************************************************************************
/*	TITLE:		2_4_merge_samples
*	PURPOSE:	Joins each diaspora sample to FDI project counts and DEPs, giving
*				one analysis file per sample: US metro x Indian state x year,
*				top-50 metros for each language only.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0401
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/2_1_s*.dta"
*				"${rawdata}/fdi_extracts/2_2_fdi_counts_metro_language_year.csv"
*				"${gendata}/2_3_deps_state_year.dta"
*	PRODUCES:	Figures:	No
*				Tables:		No
*				Datasets:	"${gendata}/2_4_s*.dta" (one per sample)
*	CONTENTS:	0: Start log file
*				1: FDI counts as a Stata file
*				2: Merge each sample
*				3: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/2_4_merge_samples.log", replace text name(stage)

********
*
*	1. FDI counts as a Stata file
*
********

	import delimited using "${rawdata}/fdi_extracts/2_2_fdi_counts_metro_language_year.csv", ///
		clear varnames(1)
	tempfile fdi
	save `fdi'

********
*
*	2. Merge each sample
*
********

	local samples s1_firstgen_highed s3_firstgen_all s4_allgen_all ///
		s1_firstgen_highed_25plus s3_firstgen_all_25plus s4_allgen_all_25plus ///
		s24_allgen_highed_25plus s25_firstgen_all_ict_25plus s27_firstgen_highed_ict_25plus ///
		s28_allgen_highed_ict_25plus

	foreach s of local samples {

		use "${gendata}/2_1_`s'.dta", clear
		keep if metro_rank <= 50	// each language's top 50 US metros

		**FDI projects from that metro to that language's home state

			merge m:1 year met2013 languaged using `fdi', keep(master match) nogen
			foreach v of varlist fdi_projects_* {
				replace `v' = 0 if missing(`v')		// no row means no projects
			}

		**DEPs in the home state that year

			gen indian_state = ""
			replace indian_state = "kerala"			if languaged == 4004
			replace indian_state = "tamil nadu"		if languaged == 4005
			replace indian_state = "gujarat"		if languaged == 3115
			replace indian_state = "karnataka"		if languaged == 3130
			replace indian_state = "maharashtra"	if languaged == 3114
			replace indian_state = "punjab"			if languaged == 3113
			replace indian_state = "andhra pradesh"	if languaged == 4003
			replace indian_state = "west bengal"	if languaged == 3112

			merge m:1 indian_state year using "${gendata}/2_3_deps_state_year.dta", ///
				keep(master match) nogen

		// Row order doesn't change the math, but a few thin-data PPML models
		// that never really converge (e.g. Life Sciences FDI) give different
		// numbers if it changes. Sorting on a unique key keeps every run identical.
		sort languaged met2013 year state
		compress
		save "${gendata}/2_4_`s'.dta", replace

		di as text "`s': " _N " metro x state x year rows"
	}

********
*
*	3. Close log file
*
********

	log close stage
