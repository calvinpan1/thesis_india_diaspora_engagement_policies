*********************************************************************************
/*	TITLE:		0_master
*	PURPOSE:	Runs the whole replication package in order, from the raw
*				IPUMS extract through every table and figure in the thesis.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_1012
*	UPDATED:	2026_1012
*	CALLS UPON:	Every do file in 3_Syntax/
*	PRODUCES:	Everything in 4_Generated_Datasets/, 5_Log_Files/, and
*				6_Tables_and_Figures/
*	CONTENTS:	0: Set paths and options
*				1: Install packages
*				2: Stage 1, build the ACS microdata (slow, only runs once)
*				3: Stage 2, clean and merge
*				4: Stage 3, tables
*				5: Stage 4, figures
*
*	HOW TO RUN:	Open Stata, cd into the replication_package folder, then
*				do "3_Syntax/0_master.do"
*/
*********************************************************************************

	clear all
	set more off
	version 18

********
*
*	0. Set paths and options
*
********

	**Root folder

		// Works as long as Stata's working directory is the replication_package
		// folder. If not, paste the full path in here instead.
		global root "`c(pwd)'"

		capture confirm file "${root}/3_Syntax/0_master.do"
		if _rc {
			di as error "Can't find 3_Syntax/0_master.do from `c(pwd)'."
			di as error "cd into the replication_package folder and try again."
			exit 601
		}

	**Folder globals (every other do file uses these)

		global rawdata		"${root}/2_Raw_Data"
		global syntax		"${root}/3_Syntax"
		global gendata		"${root}/4_Generated_Datasets"
		global logs			"${root}/5_Log_Files"
		global tables		"${root}/6_Tables_and_Figures/tables"
		global figures		"${root}/6_Tables_and_Figures/figures"

	**Switches

		// Stage 1 reads the 2.2 GB IPUMS file (about 10 seconds). Leave this
		// at 0 and it only runs when its output doesn't exist yet. Set to 1 to
		// force a rebuild.
		global force_stage1 0

		// Set to 0 to skip package installs once they're on your machine.
		global install_packages 1

		// The thesis PPML tables accidentally left out one DEP (origin ID for
		// non-citizens), see 3_3_tab_ppml.do. 0 reproduces the thesis, 1 adds it.
		global include_origin_id 0

********
*
*	1. Install packages
*
********

	if ${install_packages} {
		foreach pkg in ftools reghdfe ppmlhdfe {
			capture which `pkg'
			if _rc ssc install `pkg', replace
		}
		// ftools needs a one-time compile of its mata library
		capture ftools, compile
	}

********
*
*	2. Stage 1: build the ACS microdata (slow, only runs once)
*
********

	capture confirm file "${gendata}/1_1_acs_india_microdata.dta"
	if _rc | ${force_stage1} {
		do "${syntax}/1_build/1_1_acs_clean.do"
	}
	else {
		di as text "Stage 1 output already exists, skipping. Set force_stage1 to 1 to rebuild."
	}

********
*
*	3. Stage 2: clean and merge
*
********

	do "${syntax}/2_clean/2_1_acs_samples.do"
	do "${syntax}/2_clean/2_2_fdi_clean.do"	// skips itself without the licensed fDi files
	do "${syntax}/2_clean/2_3_deps_clean.do"
	do "${syntax}/2_clean/2_4_merge_samples.do"

********
*
*	4. Stage 3: tables
*
********

	do "${syntax}/3_tables/3_1_tab_descriptives.do"
	do "${syntax}/3_tables/3_2_tab_policy_bundling.do"
	do "${syntax}/3_tables/3_3_tab_ppml.do"

********
*
*	5. Stage 4: figures
*
********

	do "${syntax}/4_figures/4_1_fig_descriptives.do"
	do "${syntax}/4_figures/4_2_fig_lang_verification.do"
	do "${syntax}/4_figures/4_3_fig_budgets.do"
	do "${syntax}/4_figures/4_4_fig_policy_bundling.do"
	do "${syntax}/4_figures/4_5_fig_sectoral.do"
	do "${syntax}/4_figures/4_6_fig_investor_names.do"

	di as result "All done. Tables are in 6_Tables_and_Figures/tables, figures in 6_Tables_and_Figures/figures."
