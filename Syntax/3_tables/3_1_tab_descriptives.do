*********************************************************************************
/*	TITLE:		3_1_tab_descriptives
*	PURPOSE:	Table 1: number of US metro x Indian state x year observations
*				in each of the four main samples.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0402
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/2_4_s1_firstgen_highed.dta"
*				"${gendata}/2_4_s3_firstgen_all.dta"
*				"${gendata}/2_4_s4_allgen_all.dta"
*	PRODUCES:	Figures:	No
*				Tables:		"${tables}/3_1_tab1_samples_by_n.tex"
*				Datasets:	No
*	CONTENTS:	0: Start log file
*				1: Table 1, samples by number of observations
*				2: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/3_1_tab_descriptives.log", replace text name(stage)

********
*
*	1. Table 1: Samples by number of observations
*
********

	**Count rows in each sample (one row = one metro x state x year)

		// Samples 1 and 2 share a diaspora definition and only differ in which
		// FDI they count, so they have the same observations
		foreach s in s1_firstgen_highed s3_firstgen_all s4_allgen_all {
			use "${gendata}/2_4_`s'.dta", clear
			local n_`s' = _N
		}

	**Write the table

		file open tab using "${tables}/3_1_tab1_samples_by_n.tex", write replace text
		file write tab "\begin{table}[htbp]" _n
		file write tab "\centering" _n
		file write tab "\caption{Samples by number of observations}" _n
		file write tab "\label{tab:samples_by_n}" _n
		file write tab "\begin{tabularx}{\textwidth}{@{}l Y r@{}}" _n
		file write tab "\hline" _n
		file write tab "Sample & Description & Distinct metro $\times$ state $\times$ year observations \\" _n
		file write tab "\hline" _n
		file write tab "Sample 1 & First-gen, high-edu, ICT FDI & `n_s1_firstgen_highed' \\" _n
		file write tab "Sample 2 & First-gen, high-edu, all FDI & `n_s1_firstgen_highed' \\" _n
		file write tab "Sample 3 & First-gen, all people, all FDI & `n_s3_firstgen_all' \\" _n
		file write tab "Sample 4 & All-gen, all people, all FDI & `n_s4_allgen_all'*\\" _n
		file write tab "\hline" _n
		file write tab "\multicolumn{3}{@{}>{\RaggedRight\arraybackslash}p{\dimexpr\linewidth-2\tabcolsep\relax}@{}}{\footnotesize *Note: Sample 4 is smaller because it excludes West Bengal (we are unable to make reliable inferences about Bengali speakers without a birthplace of India, as most Bengali-Americans are born in Bangladesh).} \\" _n
		file write tab "\end{tabularx}" _n
		file write tab "" _n
		file write tab "\end{table}" _n
		file close tab

********
*
*	2. Close log file
*
********

	log close stage
