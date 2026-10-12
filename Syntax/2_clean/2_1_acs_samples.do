*********************************************************************************
/*	TITLE:		2_1_acs_samples
*	PURPOSE:	Turns the person-level ACS file into diaspora counts by US metro x
*				language x year, one file per sample definition in the paper,
*				and ranks each language's metros so later files can keep the
*				top 50.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0401
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/1_1_acs_india_microdata.dta"
*	PRODUCES:	Figures:	No
*				Tables:		No
*				Datasets:	"${gendata}/2_1_s*.dta" (one per sample)
*							"${gendata}/2_1_top50_metros.dta"
*	CONTENTS:	0: Start log file
*				1: Program that builds one sample
*				2: Build every sample used in the paper
*				3: Top-50 metro list for the descriptive figures
*				4: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/2_1_acs_samples.log", replace text name(stage)

********
*
*	1. Program that builds one sample
*
********

	// keepif:	who counts as diaspora in this sample
	// natif:	who counts toward the "national Indian diaspora" in each metro
	//			(only used by the H0 tables, Tables 3 and A13)
	// Andhra Pradesh (Telugu) is dropped for 2014-2017 everywhere because the
	// state split in two in 2014.

	capture program drop build_sample
	program define build_sample
		syntax , NAME(string) KEEPIF(string) NATIF(string)

		use "${gendata}/1_1_acs_india_microdata.dta", clear
		gen byte ap_split = languaged == 4003 & inrange(year, 2014, 2017)

		**National Indian diaspora per metro-year

			preserve
				keep if `natif'
				collapse (sum) total_indian_diaspora_pop = perwt, by(year met2013)
				tempfile nat_total
				save `nat_total'
			restore

		**Diaspora per metro x language x year

			keep if `keepif' & !ap_split
			collapse (sum) n_people = perwt, by(year state met2013 languaged)
			merge m:1 year met2013 using `nat_total', nogen keep(match master)

		**Rank each language's metros by total diaspora over 2005-2017

			preserve
				collapse (sum) total_n_people = n_people, by(languaged met2013)
				gsort languaged -total_n_people met2013
				by languaged: gen metro_rank = _n
				keep languaged met2013 metro_rank
				tempfile ranks
				save `ranks'
			restore
			merge m:1 languaged met2013 using `ranks', nogen

		order year state met2013 languaged n_people total_indian_diaspora_pop metro_rank
		compress
		save "${gendata}/2_1_`name'.dta", replace
	end

********
*
*	2. Build every sample used in the paper
*
********

	// Sample numbers follow the old cleanup files so they match my notes.
	// "lang_first" = all 8 state languages, "lang_all" = drops Bengali.

	**Samples 1-4 (all ages), used in Table 1 and the H0/baseline tables

		build_sample, name("s1_firstgen_highed") ///
			keepif("firstgen_india & lang_first & higher_ed == 1") ///
			natif("firstgen_india & higher_ed == 1")

		build_sample, name("s3_firstgen_all") ///
			keepif("firstgen_india & lang_first") ///
			natif("firstgen_india")

		build_sample, name("s4_allgen_all") ///
			keepif("lang_all") ///
			natif("lang_all & !ap_split")

	**Same samples, age 25 and up (the headline specs in Chapter 7)

		build_sample, name("s1_firstgen_highed_25plus") ///
			keepif("firstgen_india & lang_first & higher_ed == 1 & age >= 25") ///
			natif("firstgen_india & higher_ed == 1 & age >= 25")

		build_sample, name("s3_firstgen_all_25plus") ///
			keepif("firstgen_india & lang_first & age >= 25") ///
			natif("firstgen_india & age >= 25")

		build_sample, name("s4_allgen_all_25plus") ///
			keepif("lang_all & age >= 25") ///
			natif("lang_all & age >= 25 & !ap_split")

	**ICT deeper cuts (Tables 12-13, A16-A24)

		build_sample, name("s24_allgen_highed_25plus") ///
			keepif("lang_all & higher_ed == 1 & age >= 25") ///
			natif("lang_all & higher_ed == 1 & age >= 25 & !ap_split")

		build_sample, name("s25_firstgen_all_ict_25plus") ///
			keepif("firstgen_india & lang_first & ict_worker & age >= 25") ///
			natif("firstgen_india & lang_first & ict_worker & age >= 25 & !ap_split")

		build_sample, name("s27_firstgen_highed_ict_25plus") ///
			keepif("firstgen_india & lang_first & higher_ed == 1 & ict_worker & age >= 25") ///
			natif("firstgen_india & lang_first & higher_ed == 1 & ict_worker & age >= 25 & !ap_split")

		build_sample, name("s28_allgen_highed_ict_25plus") ///
			keepif("lang_all & higher_ed == 1 & ict_worker & age >= 25") ///
			natif("lang_all & higher_ed == 1 & ict_worker & age >= 25 & !ap_split")

********
*
*	3. Top-50 metro list for the descriptive figures
*
********

	// Any metro that is top 50 for at least one language in Sample 4. The FDI
	// and diaspora descriptive figures in Chapter 5 only count these metros.
	use "${gendata}/2_1_s4_allgen_all.dta", clear
	keep if metro_rank <= 50
	keep met2013
	duplicates drop
	save "${gendata}/2_1_top50_metros.dta", replace

********
*
*	4. Close log file
*
********

	log close stage
