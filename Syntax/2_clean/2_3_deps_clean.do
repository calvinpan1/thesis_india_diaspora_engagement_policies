*********************************************************************************
/*	TITLE:		2_3_deps_clean
*	PURPOSE:	Cleans my hand-coded diaspora engagement policy (DEP) data and the
*				DEP budget data into state-year panels, and flags the year each
*				policy switches on in each state (used for the bundling tables
*				and adoption-timing figures).
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0412
*	UPDATED:	2026_1012
*	CALLS UPON:	"${rawdata}/public/deps_state_year.csv"
*				"${rawdata}/public/dep_budgets_state_year.csv"
*	PRODUCES:	Figures:	No
*				Tables:		No
*				Datasets:	"${gendata}/2_3_deps_state_year.dta"
*							"${gendata}/2_3_dep_turnons_long.dta"
*							"${gendata}/2_3_dep_budgets_state_year.dta"
*	CONTENTS:	0: Start log file
*				1: DEP state-year panel
*				2: Policy turn-ons, one row per state x year x policy
*				3: DEP budgets
*				4: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/2_3_deps_clean.log", replace text name(stage)

********
*
*	1. DEP state-year panel
*
********

	import delimited using "${rawdata}/public/deps_state_year.csv", clear varnames(1)

	rename state indian_state
	replace indian_state = lower(trim(itrim(indian_state)))
	rename total_citizenship_participation total_citizenship
	rename total_state_bureaucratic total_state_bureaucracy

	**Recompute the totals under the final taxonomy

		// The spreadsheet totals were typed in by hand. Recomputing them makes
		// sure they match the taxonomy in Appendix D, where diaspora
		// conferences count as symbolic.
		// Overwrites a total in place (egen can't), so its column stays put
		capture program drop retotal
		program define retotal
			syntax varname, FROM(varlist)
			tempvar sum
			egen double `sum' = rowtotal(`from')
			replace `varlist' = `sum'
		end

		retotal total_symbolic, from(diaspora_day expat_awards ///
			diaspora_affinity_proclamation media_coverage_extended diaspora_conferences)
		retotal total_info, from(tax_regulatory_guidance project_matching_program ///
			investment_promotion_roadshows single_window_facilitation aftercare_services ///
			entrepreneurship_support)
		retotal total_non_econ, from(total_symbolic total_religious_cultural ///
			total_citizenship total_state_bureaucracy total_abroad)
		retotal total_econ, from(total_networks total_info total_advantages)
		retotal total_deps, from(total_non_econ total_econ)

	// Column order matters: each category total sits right before its
	// policies, and later files use that order to know which policy belongs
	// to which category. -replace- above keeps every column where it was.
	compress
	save "${gendata}/2_3_deps_state_year.dta", replace

********
*
*	2. Policy turn-ons, one row per state x year x policy
*
********

	**Reshape long, keeping column order and each policy's category

		ds indian_state year, not
		local depvars `r(varlist)'
		local order = 0
		local category ""
		tempfile long
		foreach v of local depvars {
			local ++order
			if "`v'" == "total_deps" continue

			// Broad totals (non-econ, econ) reset the category, other totals
			// start a new one, and everything else is a policy in that category
			local type "policy"
			if inlist("`v'", "total_non_econ", "total_econ") {
				local type "broad_total"
				local category ""
			}
			else if substr("`v'", 1, 6) == "total_" {
				local type "category_total"
				local category "`v'"
			}

			preserve
				keep indian_state year `v'
				rename `v' value
				gen item = "`v'"
				gen item_type = "`type'"
				gen category = "`category'"
				gen item_order = `order'
				capture append using `long'
				save `long', replace
			restore
		}
		use `long', clear

	**Flag the year a policy switches on

		// "On" means the state has it this year and didn't the year before
		// (or this is the first year in the data)
		replace value = 0 if missing(value)
		sort item indian_state year
		by item indian_state: gen byte turned_on = value > 0 & ///
			(_n == 1 | value[_n-1] <= 0 | missing(value[_n-1]))

	**Labels for tables and figures

		// "Diaspora Admin Unit", "NRI Police", "Welfare for Returnees", etc.
		gen item_label = proper(subinstr(item, "_", " ", .))
		replace item_label = subinstr(item_label, "Nri ", "NRI ", .)
		replace item_label = subinstr(item_label, " For ", " for ", .)
		replace item_label = "Single-Window Facilitation" if item == "single_window_facilitation"
		replace item_label = "Origin ID for Non-Citizens" if item == "origin_id_non_citizens"

		sort item_order indian_state year
		order indian_state year item item_label item_type category item_order value turned_on
		compress
		save "${gendata}/2_3_dep_turnons_long.dta", replace

********
*
*	3. DEP budgets
*
********

	// Budgets in 2023 rupees. Gujarat (all years), Karnataka 2016-17 and
	// Kerala 2015 are blank because the budget documents weren't available.
	import delimited using "${rawdata}/public/dep_budgets_state_year.csv", clear varnames(1)
	compress
	save "${gendata}/2_3_dep_budgets_state_year.dta", replace

********
*
*	4. Close log file
*
********

	log close stage
