*********************************************************************************
/*	TITLE:		1_1_acs_clean
*	PURPOSE:	Reads the raw IPUMS ACS extract once and keeps only the people
*				the thesis ever uses: anyone born in India, plus anyone who
*				speaks one of the Indian state languages (or Nepali, for the
*				birthplace check in Chapter 4). Everything downstream starts
*				from this much smaller file.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0401
*	UPDATED:	2026_1012
*	CALLS UPON:	"${rawdata}/ipums/usa_00014.dta" (download it yourself, see README)
*	PRODUCES:	Figures:	No
*				Tables:		No
*				Datasets:	"${gendata}/1_1_acs_india_microdata.dta"
*	CONTENTS:	0: Start log file
*				1: Read only the rows and columns we need
*				2: Build person-level indicators
*				3: Save and close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/1_1_acs_clean.log", replace text name(stage)

********
*
*	0. Language codes used everywhere
*
********

	// IPUMS LANGUAGED codes for each Indian state's dominant language
	//	4004 Malayalam (Kerala)			4005 Tamil (Tamil Nadu)
	//	3115 Gujarati (Gujarat)			3130 Kannada (Karnataka)
	//	3114 Marathi (Maharashtra)		3113 Punjabi (Punjab)
	//	4003 Telugu (Andhra Pradesh)	3112 Bengali (West Bengal)
	//	4011 Nepali (only used for the birthplace check figure)
	global state_langs	"4004, 4005, 3115, 3130, 3114, 3113, 4003, 3112"

********
*
*	1. Read only the rows and columns we need
*
********

	// Filtering inside -use- means Stata never holds all 62 million rows in
	// memory, which is most of the speedup over the old cleanup file
	use year statefip met2013 perwt age bpld languaged educd occ1990 ///
		using "${rawdata}/ipums/usa_00014.dta" ///
		if inrange(year, 2005, 2017) & met2013 != 0 ///
		& (bpld == 52100 | inlist(languaged, ${state_langs}, 4011)), clear

	rename statefip state

********
*
*	2. Build person-level indicators
*
********

	gen byte firstgen_india = bpld == 52100		// born in India

	// ICT occupations, 1990 occupation codes (computer scientists, engineers,
	// programmers, technicians)
	gen byte ict_worker = inlist(occ1990, ///
		229, 308, ///
		64, 65, 66, 67, 68, ///
		213, 214, 215, 233, ///
		69, 73, 78, 83, ///
		114, 115, 116, 127, 128, 129, 133, 153)

	gen byte higher_ed = educd >= 101 if !missing(educd)	// bachelor's or more

	// First-gen samples use all 8 state languages. All-gen samples drop Bengali,
	// since most US Bengali speakers are from Bangladesh, not West Bengal.
	gen byte lang_first = inlist(languaged, ${state_langs})
	gen byte lang_all = inlist(languaged, 4004, 4005, 3115, 3130, 3114, 3113, 4003)

********
*
*	3. Save and close log file
*
********

	compress
	save "${gendata}/1_1_acs_india_microdata.dta", replace

	tab year
	count

	log close stage
