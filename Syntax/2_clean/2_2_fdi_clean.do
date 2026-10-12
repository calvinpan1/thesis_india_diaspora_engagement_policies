*********************************************************************************
/*	TITLE:		2_2_fdi_clean
*	PURPOSE:	Cleans the licensed fDi Markets project data and writes small,
*				aggregated extracts that the rest of the package runs on.
*				fDi Markets can't be shared publicly, so this is the only file
*				that touches project-level data. Without the licensed files it
*				skips itself and everything downstream uses the extracts that
*				ship with the package.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0401
*	UPDATED:	2026_1012
*	CALLS UPON:	"${rawdata}/fdi_private/0428.fdi.csv"
*				"${rawdata}/fdi_private/0428.fdi.sectoral.csv"
*				"${rawdata}/fdi_private/0428.fdi.crsp_parent_public.csv"
*				"${rawdata}/fdi_private/investor_name_results.csv"
*				"${gendata}/2_1_top50_metros.dta"
*	PRODUCES:	Figures:	No
*				Tables:		No
*				Datasets:	"${rawdata}/fdi_extracts/2_2_fdi_counts_metro_language_year.csv"
*							"${rawdata}/fdi_extracts/2_2_fdi_state_year_top50.csv"
*							"${rawdata}/fdi_extracts/2_2_fdi_projects_by_cluster.csv"
*							"${rawdata}/fdi_extracts/2_2_investor_name_shares.csv"
*	CONTENTS:	0: Start log file, skip if the licensed data isn't here
*				1: Company flags (public company, project activity)
*				2: Clean projects and build outcome counts
*				3: Extract A, project counts by metro x language x year
*				4: Extract B, state-year totals in top-50 metros
*				5: Extract C, projects by cluster
*				6: Extract D, Indian-name investor shares
*				7: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/2_2_fdi_clean.log", replace text name(stage)

	global fdiraw "${rawdata}/fdi_private"
	global fdiout "${rawdata}/fdi_extracts"

********
*
*	0. Skip if the licensed data isn't here
*
********

	capture confirm file "${fdiraw}/0428.fdi.csv"
	if _rc {
		di as text "No licensed fDi Markets files in Raw_Data/fdi_private/."
		di as text "Skipping, later files use the extracts in Raw_Data/fdi_extracts/."
		log close stage
		exit
	}

********
*
*	1. Company flags (public company, project activity)
*
********

	**Public company: parent matched to CRSP and listed when the project happened

		import delimited using "${fdiraw}/0428.fdi.crsp_parent_public.csv", ///
			clear varnames(1) stringcols(_all)
		keep id public_by_txn_date public_by_exact_crsp_window
		destring id public_by_txn_date public_by_exact_crsp_window, replace force
		replace public_by_txn_date = 0 if missing(public_by_txn_date)
		replace public_by_exact_crsp_window = 0 if missing(public_by_exact_crsp_window)
		bysort id: egen byte public_company = max(public_by_txn_date == 1 | public_by_exact_crsp_window == 1)
		keep id public_company
		duplicates drop id, force

		tempfile public_flags
		save `public_flags'

	**Project activity (manufacturing, sales, R&D, business services)

		import delimited using "${fdiraw}/0428.fdi.sectoral.csv", ///
			clear varnames(1) stringcols(_all)
		keep id activity
		destring id, replace force
		gen activity_clean = lower(trim(itrim(activity)))
		gen byte manufacturing_activity		= activity_clean == "manufacturing"
		gen byte sales_mkt_support_activity	= activity_clean == "sales, marketing & support"
		gen byte design_dev_testing_activity	= activity_clean == "design, development & testing"
		gen byte business_services_activity	= activity_clean == "business services"
		drop activity activity_clean
		duplicates drop id, force

		tempfile activity_flags
		save `activity_flags'

********
*
*	2. Clean projects and build outcome counts
*
********

	import delimited using "${fdiraw}/0428.fdi.csv", clear varnames(1) stringcols(_all)
	destring id, replace force

	merge m:1 id using `public_flags', nogen keep(master match)
	merge m:1 id using `activity_flags', nogen keep(master match)
	foreach v in public_company manufacturing_activity sales_mkt_support_activity ///
		design_dev_testing_activity business_services_activity {
		replace `v' = 0 if missing(`v')
	}

	**Year, source metro, money and jobs

		gen year = year(date(trim(project_date), "MD20Y"))
		keep if inrange(year, 2005, 2017)

		gen met2013 = real(subinstr(trim(itrim(sourcecitymetro2013)), ",", "", .))

		// Strip "$", commas and spaces before converting to numbers
		foreach v in capitalinvestmentreal jobscreated {
			replace `v' = subinstr(subinstr(subinstr(trim(`v'), "$", "", .), ",", "", .), " ", "", .)
			destring `v', replace force
		}

	**Destination state -> its dominant language code

		gen dest = lower(trim(itrim(destinationstate)))
		gen languaged = .
		replace languaged = 4004 if dest == "kerala"
		replace languaged = 4005 if inlist(dest, "tamil nadu", "tamilnadu")
		replace languaged = 3115 if dest == "gujarat"
		replace languaged = 3130 if dest == "karnataka"
		replace languaged = 3114 if dest == "maharashtra"
		replace languaged = 3113 if dest == "punjab"
		replace languaged = 4003 if inlist(dest, "andhra pradesh", "andhra")
		replace languaged = 3112 if inlist(dest, "west bengal", "bengal")
		drop if missing(languaged)
		drop if languaged == 4003 & inrange(year, 2014, 2017)	// AP split in 2014

	**Company size (Tables 9-11, A13-A15, A20-A24)

		// A company is "large" if it's ever public or any of its projects is at
		// or above the 75th percentile of jobs or capital. "Small" is everyone
		// else with at least one jobs or capital number to judge by.
		gen parent_clean = lower(trim(itrim(parent_company)))
		replace parent_clean = "__missing_parent_" + string(id, "%12.0f") if parent_clean == ""
		egen corp_id = group(parent_clean)

		quietly summarize jobscreated, detail
		local p75_jobs = r(p75)
		quietly summarize capitalinvestmentreal, detail
		local p75_capital = r(p75)

		gen byte has_size_info = !missing(jobscreated) | !missing(capitalinvestmentreal)
		gen byte big_project = (jobscreated >= `p75_jobs' & jobscreated < .) ///
			| (capitalinvestmentreal >= `p75_capital' & capitalinvestmentreal < .)

		bysort corp_id: egen byte corp_public = max(public_company == 1)
		bysort corp_id: egen byte corp_has_size_info = max(has_size_info)
		bysort corp_id: egen byte corp_ever_big = max(big_project)

		gen largecompany_75 = .
		replace largecompany_75 = 0 if corp_has_size_info == 1
		replace largecompany_75 = 1 if corp_ever_big == 1 | corp_public == 1
		gen small_company_75 = largecompany_75 == 0 if !missing(largecompany_75)

	**Outcome counts, one row per project

		replace cluster = trim(itrim(cluster))
		gen cluster_clean = lower(cluster)
		gen byte ict = cluster_clean == "ict & electronics"

		gen byte fdi_projects_all				= 1
		gen byte fdi_projects_ict				= ict
		gen byte fdi_projects_profsvc			= cluster_clean == "professional services"
		gen byte fdi_projects_finsvc			= cluster_clean == "financial services"
		gen byte fdi_projects_creative			= cluster_clean == "creative industries"
		gen byte fdi_projects_lifesciences		= cluster_clean == "life sciences"
		gen byte fdi_projects_industrial		= cluster_clean == "industrial"
		gen byte fdi_projects_transportequip	= cluster_clean == "transport equipment"
		gen byte fdi_projects_consgoods			= cluster == "Consumer Goods"
		gen byte fdi_projects_all_mfg			= manufacturing_activity
		gen byte fdi_projects_sales_mkt_support	= sales_mkt_support_activity
		gen byte fdi_projects_design_dev_testing	= design_dev_testing_activity
		gen byte fdi_projects_business_services	= business_services_activity

		// Size-split counts are 0 (not missing) for companies we can't size
		gen byte fdi_projects_all_small75	= small_company_75 == 1
		gen byte fdi_projects_ict_small75	= ict & small_company_75 == 1
		gen byte fdi_projects_all_large75	= largecompany_75 == 1
		gen byte fdi_projects_ict_large75	= ict & largecompany_75 == 1

		tempfile projects
		save `projects'

********
*
*	3. Extract A, project counts by metro x language x year
*
********

	// Counts only. Capital and jobs at this level could pin down single
	// licensed records, so those only go out as state-year totals (Extract B).
	collapse (sum) fdi_projects_*, by(year met2013 languaged)
	drop if missing(met2013)
	sort year met2013 languaged
	export delimited using "${fdiout}/2_2_fdi_counts_metro_language_year.csv", replace

********
*
*	4. Extract B, state-year totals in top-50 metros
*
********

	// Feeds Figures 3 and A8-A12: projects, capital and jobs by Indian state-year,
	// counting only projects from the top-50 diaspora metros
	use `projects', clear
	merge m:1 met2013 using "${gendata}/2_1_top50_metros.dta", keep(match) nogen
	collapse (sum) fdi_projects_all fdi_projects_ict fdi_projects_consgoods ///
		capital_real_all = capitalinvestmentreal jobs_all = jobscreated, by(year languaged)

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

	// Fill in every state-year so states with no projects show up as 0
	fillin indian_state year
	drop _fillin
	foreach v of varlist fdi_projects_* capital_real_all jobs_all {
		replace `v' = 0 if missing(`v')
	}

	order indian_state year
	sort indian_state year
	format capital_real_all jobs_all %20.4f
	export delimited using "${fdiout}/2_2_fdi_state_year_top50.csv", datafmt replace

********
*
*	5. Extract C, projects by cluster
*
********

	// Feeds Figure A25. All projects in the sectoral file, every year.
	import delimited using "${fdiraw}/0428.fdi.sectoral.csv", clear varnames(1) stringcols(_all)
	destring id, replace ignore("$, ") force
	replace cluster = "Missing/Not specified" if trim(cluster) == ""
	collapse (count) n_projects = id, by(cluster)
	gsort -n_projects cluster
	export delimited using "${fdiout}/2_2_fdi_projects_by_cluster.csv", replace

********
*
*	6. Extract D, Indian-name investor shares
*
********

	// Feeds Figure 2. The "Indian name?" column was hand-coded from each
	// project's first listed contact, using a name-origin classifier
	// (Dhingra 2023) and checked in Excel.
	import delimited using "${fdiraw}/investor_name_results.csv", ///
		clear varnames(1) stringcols(_all) bindquote(strict)

	// Only need 4 of the 33 columns, picked by position since the headers are
	// messy: 1 ID, 12 capital, 17 first contact's name, 18 Indian name flag
	unab allvars : _all
	local keepvars
	foreach i in 1 12 17 18 {
		local keepvars `keepvars' `: word `i' of `allvars''
	}
	keep `keepvars'
	rename (`keepvars') (id capital contact indian_name)

	foreach v of varlist _all {
		replace `v' = trim(`v')
	}
	destring capital, replace ignore(",") force

	gen byte indian_led = indian_name == "Y"
	gen diaspora_status = cond(indian_led, "diaspora", "non_diaspora")

	**Share of projects and of capital

		quietly count
		local n_projects = r(N)
		quietly summarize capital, meanonly
		local total_capital = r(sum)

		preserve
			gen byte one = 1
			collapse (sum) n_projects = one capital_total = capital, by(diaspora_status)
			gen project_share = 100 * n_projects / `n_projects'
			gen capital_share = 100 * capital_total / `total_capital'
			tempfile project_shares
			save `project_shares'
		restore

	**Share of unique investors (a person counts as Indian-named if any of their projects is)

		gen investor = lower(trim(contact))
		foreach ch in "." "," "'" {
			replace investor = subinstr(investor, "`ch'", "", .)
		}
		replace investor = itrim(subinstr(investor, "-", " ", .))
		keep if investor != ""

		bysort investor: egen byte investor_indian = max(indian_led)
		by investor: keep if _n == 1
		quietly count
		local n_investors = r(N)

		gen investor_status = cond(investor_indian, "diaspora", "non_diaspora")
		gen byte one = 1
		collapse (sum) n_investors = one, by(investor_status)
		rename investor_status diaspora_status
		gen investor_share = 100 * n_investors / `n_investors'

		merge 1:1 diaspora_status using `project_shares', nogen
		replace investor_share = 0 if missing(investor_share)

	keep diaspora_status project_share investor_share capital_share
	sort diaspora_status
	format *_share %9.4f
	export delimited using "${fdiout}/2_2_investor_name_shares.csv", datafmt replace
	list

********
*
*	7. Close log file
*
********

	log close stage
