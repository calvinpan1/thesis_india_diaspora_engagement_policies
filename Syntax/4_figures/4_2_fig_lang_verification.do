*********************************************************************************
/*	TITLE:		4_2_fig_lang_verification
*	PURPOSE:	Online Appendix Figures A4-A7:
*				where US speakers of four languages were born. Checks whether a
*				language really points to an Indian state, or mostly to another
*				country (Bengali -> Bangladesh, Tamil -> Sri Lanka, etc.)
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0331
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/1_1_acs_india_microdata.dta"
*	PRODUCES:	Figures:	"${figures}/4_2_figA4_punjabi_birthplace.png"
*							"${figures}/4_2_figA5_tamil_birthplace.png"
*							"${figures}/4_2_figA6_bengali_birthplace.png"
*							"${figures}/4_2_figA7_nepali_birthplace.png"
*				Tables:		No
*				Datasets:	No
*	CONTENTS:	0: Start log file, graph font
*				1: Speakers by birthplace and year
*				2: One figure per language
*				3: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/4_2_fig_lang_verification.log", replace text name(stage)

	capture graph set window fontface "CMU Serif"

********
*
*	1. Speakers by birthplace and year
*
********

	use "${gendata}/1_1_acs_india_microdata.dta", clear
	collapse (sum) n_people = perwt, by(year languaged bpld)
	gen byte us_born = bpld <= 12092		// US states, territories, and "US, n.s."
	tempfile speakers
	save `speakers'

********
*
*	2. One figure per language
*
********

	// language code, name, birthplace code of the other country, its name, figure
	local figs `" "3113 Punjabi 52140 Pakistan A4" "4005 Tamil 52150 Sri_Lanka A5" "3112 Bengali 52110 Bangladesh A6" "4011 Nepali 52400 Nepal A7" "'

	foreach f of local figs {
		tokenize `f'
		local code `1'
		local lang `2'
		local other_bpl `3'
		local other = subinstr("`4'", "_", " ", .)
		local fignum `5'

		use `speakers', clear
		keep if languaged == `code'

		gen birthplace = 4						// other countries
		replace birthplace = 1 if bpld == 52100	// India
		replace birthplace = 2 if bpld == `other_bpl'
		replace birthplace = 3 if us_born
		collapse (sum) n_people, by(year birthplace)

		twoway ///
			(line n_people year if birthplace == 1, sort) ///
			(line n_people year if birthplace == 2, sort) ///
			(line n_people year if birthplace == 3, sort) ///
			(line n_people year if birthplace == 4, sort), ///
			title("`lang' speakers by birthplace over time", size(12pt)) ///
			ytitle("Estimated number of speakers", size(12pt)) ///
			xtitle("Year", size(12pt)) ///
			xlabel(, labsize(10pt)) ///
			ylabel(, labsize(10pt) angle(horizontal)) ///
			legend(order(1 "India" 2 "`other'" 3 "US" 4 "Other countries") ///
				position(6) ring(1) cols(2) size(10pt) region(lstyle(none))) ///
			graphregion(color(white)) ///
			plotregion(margin(medium))
		graph export "${figures}/4_2_fig`fignum'_`=lower("`lang'")'_birthplace.png", replace
	}

********
*
*	3. Close log file
*
********

	log close stage
