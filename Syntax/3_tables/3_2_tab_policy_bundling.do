*********************************************************************************
/*	TITLE:		3_2_tab_policy_bundling
*	PURPOSE:	Tables on how often DEPs get adopted together (bundling).
*				Online Appendix Table A6: the 10 policy pairs most often adopted together
*				Online Appendix Table A7: every new DEP by state and year, 2005-2017
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0412
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/2_3_dep_turnons_long.dta"
*	PRODUCES:	Figures:	No
*				Tables:		"${tables}/3_2_tabA6_jaccard_top10.tex"
*							"${tables}/3_2_tabA7_dep_turnon_events.tex"
*				Datasets:	"${gendata}/3_2_policy_pair_jaccard.dta"
*	CONTENTS:	0: Start log file
*				1: Jaccard score for every pair of policies
*				2: Table A6, top 10 pairs by Jaccard score
*				3: Table A7, DEP turn-ons by state and year
*				4: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/3_2_tab_policy_bundling.log", replace text name(stage)

********
*
*	1. Jaccard score for every pair of policies
*
********

	// Jaccard = (state-years where both turn on) / (state-years where either
	// turns on). 1 means the two policies always arrive together.

	use "${gendata}/2_3_dep_turnons_long.dta", clear
	keep if item_type == "policy" & inrange(year, 2005, 2017)
	keep indian_state year item turned_on
	tempfile turnons
	save `turnons'

	**Pair every policy with every other policy in the same state-year

		rename (item turned_on) (col_item col_on)
		joinby indian_state year using `turnons'
		rename (item turned_on) (row_item row_on)
		keep if row_item < col_item		// each pair once

		gen byte both = row_on & col_on
		gen byte either = row_on | col_on
		collapse (sum) coadopt_count = both union_count = either, by(row_item col_item)

		gen jaccard = coadopt_count / union_count if union_count > 0
		keep if !missing(jaccard)		// drops pairs where neither ever turns on

	gsort -jaccard -coadopt_count row_item col_item
	save "${gendata}/3_2_policy_pair_jaccard.dta", replace

********
*
*	2. Table A6: Policy Pairs with the Top 10 Highest Jaccard Scores
*
********

	gen rank_jaccard_pair = _n
	keep if rank_jaccard_pair <= 10

	file open tab using "${tables}/3_2_tabA6_jaccard_top10.tex", write replace text
	file write tab "\begin{table}[htbp]" _n
	file write tab "\centering" _n
	file write tab "\footnotesize" _n
	file write tab "\setlength{\tabcolsep}{3pt}" _n
	file write tab "\renewcommand{\arraystretch}{1.08}" _n
	file write tab "\caption{Policy Pairs with the Top 10 Highest Jaccard Scores (Rates of Co-Adoption)}" _n
	file write tab "\label{tab:jaccard_top10}" _n
	file write tab "{\small" _n
	file write tab "\begin{tabular}{r p{2.7cm} p{2.7cm} r r r}" _n
	file write tab "\hline" _n
	file write tab "rank\_jaccard\_pair & row\_item & col\_item & coadopt\_count & union\_count & jaccard \\" _n
	file write tab "\hline" _n
	forvalues i = 1/`=_N' {
		local row = subinstr(row_item[`i'], "_", "\_", .)
		local col = subinstr(col_item[`i'], "_", "\_", .)
		file write tab "`i' & `row' & `col' & `=coadopt_count[`i']' & `=union_count[`i']' & `=string(jaccard[`i'])' \\" _n
	}
	file write tab "\hline" _n
	file write tab "\end{tabular}" _n
	file write tab "}" _n
	file write tab "\end{table}" _n
	file close tab

********
*
*	3. Table A7: Timing and Bundling of New DEPs, 2005-2017
*
********

	**One cell per state-year: "2: Policy A, Policy B" or "0"

		use "${gendata}/2_3_dep_turnons_long.dta", clear
		keep if item_type == "policy" & inrange(year, 2005, 2017)

		// List the policies that switch on, in the same order as the DEP data
		sort indian_state year item_order
		gen list = item_label if turned_on
		by indian_state year: replace list = cond(list[_n-1] == "", list, ///
			cond(list == "", list[_n-1], list[_n-1] + ", " + list)) if _n > 1
		by indian_state year: gen n_on = sum(turned_on)
		by indian_state year: keep if _n == _N

		gen cell = "0"
		replace cell = string(n_on) + ": " + list if n_on > 0

		// Stack each word on its own line inside the cell, but keep the count
		// on the same line as the first word ("2: Diaspora" then "Conferences,")
		replace cell = "\makecell[tl]{" + subinstr(subinstr(cell, " ", "\\", .), ":\\", ": ", 1) + "}" if n_on > 0

		keep indian_state year cell

	**Wide: one row per year, one column per state

		// Andhra Pradesh has no rows after 2013 (state split), so its cells stay blank
		replace indian_state = subinstr(indian_state, " ", "_", .)
		reshape wide cell, i(year) j(indian_state) string

		local states andhra_pradesh gujarat karnataka kerala maharashtra punjab tamil_nadu west_bengal

		file open tab using "${tables}/3_2_tabA7_dep_turnon_events.tex", write replace text
		file write tab "\begin{table}[htbp]" _n
		file write tab "\centering" _n
		file write tab "\caption{Timing and Bundling of New Diaspora Engagement Policies across Indian States, 2005--2017}" _n
		file write tab "\label{tab:dep_turnon_events}" _n
		file write tab "\scriptsize" _n
		file write tab "\setlength{\tabcolsep}{2pt}" _n
		file write tab "\renewcommand{\arraystretch}{1.08}" _n
		file write tab "\begin{tabularx}{\textwidth}{@{}l *{8}{>{\RaggedRight\arraybackslash}X}@{}}" _n
		file write tab "\hline" _n
		file write tab "\textbf{Year}"
		foreach s of local states {
			file write tab " & \textbf{`=proper(subinstr("`s'", "_", " ", .))'}"
		}
		file write tab " \\" _n
		file write tab "\hline" _n
		forvalues i = 1/`=_N' {
			file write tab "`=year[`i']'"
			foreach s of local states {
				file write tab " & `=cell`s'[`i']'"
			}
			file write tab " \\" _n
			file write tab "\hline" _n
		}
		file write tab "\end{tabularx}" _n
		file write tab "" _n
		file write tab "\vspace{0.4em}" _n
		file write tab "\begin{minipage}{0.97\textwidth}" _n
		file write tab "\scriptsize" _n
		file write tab "\textit{Notes:} Entries report diaspora engagement policies (DEPs) that switch on in a given state-year. Cells beginning with a number indicate the count of newly adopted policies, followed by the specific policy names. A value of 0 indicates no new policy adoption in that year. Blank Andhra Pradesh cells in 2014--2017 reflect the state bifurcation period and corresponding coding treatment." _n
		file write tab "\end{minipage}" _n
		file write tab "\end{table}" _n
		file close tab

********
*
*	4. Close log file
*
********

	log close stage
