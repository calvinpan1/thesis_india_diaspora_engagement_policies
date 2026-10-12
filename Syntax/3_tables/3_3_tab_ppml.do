*********************************************************************************
/*	TITLE:		3_3_tab_ppml
*	PURPOSE:	All the PPML gravity results: Tables 3-14 in the paper and
*				Tables A8-A25 in the online appendix.
*				Each model regresses FDI projects from a US metro to an Indian
*				state on the size of that state's diaspora in the metro, alone
*				(H0, Table 1) or interacted with the state's DEPs (Tables 2-4
*				and the single-policy tables).
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0402
*	UPDATED:	2026_1012
*	CALLS UPON:	"${gendata}/2_4_s*.dta"
*				"${gendata}/2_3_dep_turnons_long.dta"
*	PRODUCES:	Figures:	No
*				Tables:		"${tables}/3_3_tab*.tex" (12 paper tables, 18 appendix tables)
*				Datasets:	"${gendata}/3_3_ppml_results.dta"
*							"${gendata}/3_3_ppml_accounting.dta"
*							"${gendata}/3_3_policy_support.dta"
*	CONTENTS:	0: Start log file
*				1: Which policies have enough support to estimate
*				2: Programs that prep data and run each kind of model
*				3: Run every model
*				4: Programs that write the LaTeX tables
*				5: Tables 3-13 and A8-A24
*				6: Table 14, state-specific policy interactions
*				7: Table A25, single-policy results by support
*				8: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/3_3_tab_ppml.log", replace text name(stage)

********
*
*	1. Which policies have enough support to estimate
*
********

	// A policy is "supported" if at least 2 states have it, for at least 10
	// state-years in 2005-2017. Rarer policies are basically case studies, so
	// Tables 3 and 4 only count supported ones. The single-policy tables show
	// policies in 2+ states and MORE than 10 state-years.

	use "${gendata}/2_3_dep_turnons_long.dta", clear
	keep if item_type == "policy" & inrange(year, 2005, 2017)

	gen byte has_it = value > 0
	bysort item indian_state: gen byte state_has_it = has_it & sum(has_it) == 1
	collapse (sum) support_obs = has_it support_states = state_has_it ///
		(first) category item_order, by(item)

	gen byte eligible = support_states >= 2 & support_obs >= 10
	sort item_order

	**Origin ID for non-citizens (see note)

		// The thesis tables were run without this policy: the original code
		// renamed it in one place but not another, so it silently dropped out
		// of the DEP counts, the State Bureaucracy category, and the
		// single-policy tables. Left out here so the tables match the thesis and paper.
		// Set include_origin_id to 1 in 0_master.do to put it back.
		if "${include_origin_id}" != "1" drop if item == "origin_id_non_citizens"

	**Lists used by the models below

		levelsof item if eligible, local(eligible) clean
		global ELIGIBLE_POLICIES "`eligible'"

		// Every policy in DEP-data order (for the single-policy tables)
		global ALL_POLICIES ""
		forvalues i = 1/`=_N' {
			global ALL_POLICIES "${ALL_POLICIES} `=item[`i']'"
		}

		// Table 4 categories: any category with at least one supported policy,
		// in DEP-data order. The category measure only counts supported ones.
		global H4_CATEGORIES ""
		levelsof category if eligible, local(cats) clean
		foreach c in total_symbolic total_religious_cultural total_citizenship ///
			total_state_bureaucracy total_abroad total_networks total_info total_advantages {
			if strpos(" `cats' ", " `c' ") == 0 continue
			global H4_CATEGORIES "${H4_CATEGORIES} `c'"
			levelsof item if eligible & category == "`c'", local(members) clean
			global MEMBERS_`c' "`members'"
		}

	di as text "Supported policies: ${ELIGIBLE_POLICIES}"
	di as text "Table 4 categories: ${H4_CATEGORIES}"

	rename item policy
	keep policy category item_order support_states support_obs eligible
	save "${gendata}/3_3_policy_support.dta", replace

********
*
*	2. Programs that prep data and run each kind of model
*
********

	**Load a sample and build the regressors

		capture program drop prep_panel
		program define prep_panel
			syntax , FILE(string) [TECHHUBS]

			use "${gendata}/2_4_`file'.dta", clear

			// Tech-hub check (Tables A23-A24): metros where big tech firms are
			// headquartered, see Online Appendix Table A26
			if "`techhubs'" != "" {
				keep if inlist(met2013, 42660, 41940, 41860, 38900, 14260, 38060, 41740) ///
					| inlist(met2013, 12420, 39340, 41620, 31540, 22220, 39580, 20500)
			}

			// No DEP row means no DEPs (leaves total_indian_diaspora_pop alone)
			foreach v of varlist total_deps total_non_econ total_econ total_symbolic ///
				total_religious_cultural total_citizenship total_state_bureaucracy ///
				total_abroad total_networks total_info total_advantages ${ALL_POLICIES} {
				replace `v' = 0 if missing(`v')
			}

			gen origin_id = met2013
			egen od_id = group(origin_id languaged)		// metro x state pair
			gen ln_dias = ln(1 + n_people)
			gen ln_total_indian_dias = ln(1 + total_indian_diaspora_pop)

			// Table 2: any DEP at all. Table 3: count of supported DEPs.
			gen byte any_dep = total_deps > 0
			egen double sc_dep_count = rowtotal(${ELIGIBLE_POLICIES})

			// Table 4: count of supported DEPs in each category
			foreach c of global H4_CATEGORIES {
				egen double sc_`c' = rowtotal(${MEMBERS_`c'})
			}
		end

	**Record the sample-size details shown under every table

		capture program drop post_accounting
		program define post_accounting
			syntax , OUTCOME(name) RHS(varlist) TABLE(string) SPEC(integer) SAMPLEID(integer)

			tempvar touse
			gen byte `touse' = 1
			markout `touse' `outcome' origin_id languaged year od_id `rhs'

			quietly count if `touse'
			local raw_N = r(N)
			quietly summarize `outcome' if `touse'
			local projects = r(sum)
			quietly summarize n_people if `touse'
			local pop = r(sum)

			frame post accounting (`sampleid') ("`table'") (`spec') ///
				(`raw_N') (`projects') (`pop') (e(N_full)) (e(N)) ///
				(e(num_singletons)) (e(num_separated))
		end

	**Save one coefficient from the last model

		capture program drop post_coef
		program define post_coef
			syntax , TERM(string) TABLE(string) SPEC(integer) SPECLABEL(string) ///
				SAMPLEID(integer) [POLICY(string)]

			capture quietly lincom `term'
			if _rc exit
			frame post results (`sampleid') ("`table'") (`spec') (`"`speclabel'"') ///
				("`policy'") (r(estimate)) (r(se)) (r(p))
		end

	**H0 (Tables 3, A13): local vs national diaspora, metro FE + state-year FE

		capture program drop run_h0
		program define run_h0
			syntax , OUTCOME(name) SAMPLEID(integer)

			local spec = 0
			foreach x in ln_dias ln_total_indian_dias {
				local ++spec
				local lab "Subnational diaspora: exporter FE + importer-year FE"
				if "`x'" == "ln_total_indian_dias" local lab "National Indian diaspora: exporter FE + importer-year FE"

				capture quietly ppmlhdfe `outcome' c.`x', ///
					absorb(origin_id i.languaged#i.year) vce(cluster od_id)
				if _rc continue
				post_accounting, outcome(`outcome') rhs(`x') table(h0) spec(`spec') sampleid(`sampleid')
				post_coef, term(`x') table(h0) spec(`spec') speclabel("`lab'") sampleid(`sampleid')
			}
		end

	**Diaspora-only models (Table A14), two sets of fixed effects

		capture program drop run_table1
		program define run_table1
			syntax , OUTCOME(name) SAMPLEID(integer)

			forvalues spec = 1/2 {
				if `spec' == 1 {
					local lab "PPML exporter-year FE + importer-year FE"
					local fe "i.origin_id#i.year i.languaged#i.year"
				}
				else {
					local lab "PPML exporter FE + importer-year FE"
					local fe "origin_id i.languaged#i.year"
				}

				capture quietly ppmlhdfe `outcome' c.ln_dias, absorb(`fe') vce(cluster od_id)
				if _rc continue
				post_accounting, outcome(`outcome') rhs(ln_dias) table(table1_baseline) spec(`spec') sampleid(`sampleid')
				post_coef, term(ln_dias) table(table1_baseline) spec(`spec') speclabel("`lab'") sampleid(`sampleid')
			}
		end

	**Tables 2-4 and single-policy tables: ln diaspora x policy

		// Pair FE + metro-year FE + state-year FE, clustered by Indian state.
		// The policy itself is absorbed by the state-year FE, so we only report
		// the interaction.
		capture program drop run_interaction
		program define run_interaction
			syntax , OUTCOME(name) POLICY(name) TABLE(string) SPEC(integer) ///
				SPECLABEL(string) SAMPLEID(integer)

			quietly summarize `policy'
			if missing(r(sd)) | r(sd) <= 0 exit		// policy never varies here

			capture quietly ppmlhdfe `outcome' c.ln_dias##c.`policy', ///
				absorb(od_id i.origin_id#i.year i.languaged#i.year) vce(cluster languaged)
			if _rc exit

			post_accounting, outcome(`outcome') rhs(ln_dias `policy') table(`table') ///
				spec(`spec') sampleid(`sampleid')
			post_coef, term(c.ln_dias#c.`policy') table(`table') spec(`spec') ///
				speclabel(`"`speclabel'"') sampleid(`sampleid') policy(`policy')
		end

	**Run whichever tables a sample needs

		capture program drop run_model
		program define run_model
			syntax , SAMPLEID(integer) FILE(string) OUTCOME(name) ///
				[H0 TABLE1 TABLE2 TABLE3 TABLE4 SINGLEPOLICY TECHHUBS]

			prep_panel, file(`file') `techhubs'
			di as text "Sample `sampleid': `file', `outcome'"

			if "`h0'" != ""		run_h0, outcome(`outcome') sampleid(`sampleid')
			if "`table1'" != ""	run_table1, outcome(`outcome') sampleid(`sampleid')

			if "`table2'" != "" {
				run_interaction, outcome(`outcome') policy(any_dep) table(table2_h1) ///
					spec(1) speclabel("Any DEP adoption") sampleid(`sampleid')
			}
			if "`table3'" != "" {
				run_interaction, outcome(`outcome') policy(sc_dep_count) table(table3_h2) ///
					spec(1) speclabel("DEP count (support-screened)") sampleid(`sampleid')
			}
			if "`table4'" != "" {
				local spec = 0
				foreach c of global H4_CATEGORIES {
					local ++spec
					local lab = proper(subinstr(subinstr("`c'", "total_", "", 1), "_", " ", .))
					run_interaction, outcome(`outcome') policy(sc_`c') table(table4_h3) ///
						spec(`spec') speclabel("`lab'") sampleid(`sampleid')
				}
			}
			if "`singlepolicy'" != "" {
				local spec = 0
				foreach p of global ALL_POLICIES {
					local ++spec
					local lab = proper(subinstr("`p'", "_", " ", .))
					run_interaction, outcome(`outcome') policy(`p') table(singlepolicy) ///
						spec(`spec') speclabel("`lab'") sampleid(`sampleid')
				}
			}
		end

********
*
*	3. Run every model
*
********

	// Results and sample sizes collect in two frames, saved at the end
	capture frame drop results
	capture frame drop accounting
	frame create results int sample_id str30 table_id int spec_order str80 spec_label ///
		str40 policy double(coef_b coef_se coef_p)
	frame create accounting int sample_id str30 table_id int spec_order ///
		double(raw_N projects pop N_full N_used singletons separated)

	// Sample IDs are the column IDs used in the tables below. Several tables
	// reuse the same model under a different column label, those get copied
	// at the end of this section instead of being re-estimated.

	**Baseline samples (Tables 3-7)

		run_model, sampleid(15) file(s3_firstgen_all)			outcome(fdi_projects_ict) h0 table2 table3 table4 singlepolicy
		run_model, sampleid(11) file(s1_firstgen_highed_25plus)	outcome(fdi_projects_all) h0 table2 table3 table4 singlepolicy
		run_model, sampleid(12) file(s3_firstgen_all_25plus)	outcome(fdi_projects_all) h0 table2 table3 table4 singlepolicy
		run_model, sampleid(13) file(s4_allgen_all_25plus)		outcome(fdi_projects_all) h0 table2 table3 table4 singlepolicy
		run_model, sampleid(14) file(s4_allgen_all)				outcome(fdi_projects_all) h0 table2 table3 table4 singlepolicy

	**Sector (cluster) and activity cuts (Tables 8, A8-A12), first-gen 25+ high-ed

		run_model, sampleid(22) file(s1_firstgen_highed_25plus) outcome(fdi_projects_ict)				table2 table4 singlepolicy
		run_model, sampleid(23) file(s1_firstgen_highed_25plus) outcome(fdi_projects_profsvc)			table2 table4 singlepolicy
		run_model, sampleid(24) file(s1_firstgen_highed_25plus) outcome(fdi_projects_finsvc)			table2 table4 singlepolicy
		run_model, sampleid(25) file(s1_firstgen_highed_25plus) outcome(fdi_projects_creative)			table2 table4 singlepolicy
		run_model, sampleid(26) file(s1_firstgen_highed_25plus) outcome(fdi_projects_lifesciences)		table2 table4 singlepolicy
		run_model, sampleid(27) file(s1_firstgen_highed_25plus) outcome(fdi_projects_industrial)		table2 table4 singlepolicy
		run_model, sampleid(28) file(s1_firstgen_highed_25plus) outcome(fdi_projects_transportequip)	table2 table4 singlepolicy

		run_model, sampleid(32) file(s1_firstgen_highed_25plus) outcome(fdi_projects_sales_mkt_support)	table2 table4 singlepolicy
		run_model, sampleid(33) file(s1_firstgen_highed_25plus) outcome(fdi_projects_design_dev_testing)	table2 table4 singlepolicy
		run_model, sampleid(34) file(s1_firstgen_highed_25plus) outcome(fdi_projects_all_mfg)			table2 table4 singlepolicy
		run_model, sampleid(35) file(s1_firstgen_highed_25plus) outcome(fdi_projects_business_services)	table2 table4 singlepolicy

	**Company-size samples (Tables 9-11, A13-A15)

		run_model, sampleid(41) file(s1_firstgen_highed_25plus) outcome(fdi_projects_all_small75) h0 table1 table2 table3 table4 singlepolicy
		run_model, sampleid(42) file(s1_firstgen_highed_25plus) outcome(fdi_projects_ict_small75) h0 table1 table2 table3 table4 singlepolicy
		run_model, sampleid(43) file(s1_firstgen_highed_25plus) outcome(fdi_projects_all_large75) h0 table1 table2 table3 table4 singlepolicy
		run_model, sampleid(44) file(s1_firstgen_highed_25plus) outcome(fdi_projects_ict_large75) h0 table1 table2 table3 table4 singlepolicy

	**ICT deeper cuts (Tables 12-13, A16-A24), all with ICT FDI as the outcome

		run_model, sampleid(51) file(s3_firstgen_all_25plus)			outcome(fdi_projects_ict)			table2 table4 singlepolicy
		run_model, sampleid(52) file(s4_allgen_all_25plus)				outcome(fdi_projects_ict)			table2 table4 singlepolicy
		run_model, sampleid(54) file(s24_allgen_highed_25plus)			outcome(fdi_projects_ict)			table2 table4 singlepolicy
		run_model, sampleid(63) file(s27_firstgen_highed_ict_25plus)	outcome(fdi_projects_ict)			table2 table4 singlepolicy
		run_model, sampleid(64) file(s28_allgen_highed_ict_25plus)		outcome(fdi_projects_ict)			table2 table4 singlepolicy
		run_model, sampleid(74) file(s27_firstgen_highed_ict_25plus)	outcome(fdi_projects_ict_small75)	table2 table4 singlepolicy

		run_model, sampleid(81) file(s3_firstgen_all_25plus)			outcome(fdi_projects_ict)			table2 table4 techhubs
		run_model, sampleid(82) file(s25_firstgen_all_ict_25plus)		outcome(fdi_projects_ict)			table2 table4 techhubs
		run_model, sampleid(83) file(s3_firstgen_all_25plus)			outcome(fdi_projects_ict_small75)	table2 table4 techhubs
		run_model, sampleid(84) file(s25_firstgen_all_ict_25plus)		outcome(fdi_projects_ict_small75)	table2 table4 techhubs

	**Table A25: the four main samples from Table 1, all policies

		run_model, sampleid(1) file(s1_firstgen_highed)	outcome(fdi_projects_ict) singlepolicy
		run_model, sampleid(2) file(s1_firstgen_highed)	outcome(fdi_projects_all) singlepolicy
		run_model, sampleid(3) file(s3_firstgen_all)	outcome(fdi_projects_all) singlepolicy

	**Columns that reuse a model above

		// new column <- existing model
		foreach pair in "4 14" "21 11" "31 11" "53 22" "61 22" "71 22" "62 54" "72 63" "73 42" {
			gettoken new src : pair
			foreach f in results accounting {
				frame `f' {
					quietly expand 2 if sample_id == `src', generate(copy)
					quietly replace sample_id = `new' if copy
					drop copy
				}
			}
		}

	frame results: save "${gendata}/3_3_ppml_results.dta", replace
	frame accounting: save "${gendata}/3_3_ppml_accounting.dta", replace

********
*
*	4. Programs that write the LaTeX tables
*
********

	**Write a results table in the paper format

		// columns() holds one sample ID per column, labels() the matching
		// column headers separated by "|". singlepolicy adds the # States and
		// # State-years columns and splits rows by how much support a policy has.
		capture program drop write_table
		program define write_table
			syntax , TABLE(string) FILE(string) LABEL(string) TITLE(string) ///
				COLUMNS(numlist) LABELS(string) [SINGLEPOLICY]

			local ncols : word count `columns'
			local extra = cond("`singlepolicy'" != "", 2, 0)
			local totalcols = 1 + `extra' + `ncols'

			**Coefficients, one row per spec with columns side by side

				use "${gendata}/3_3_ppml_results.dta", clear
				keep if table_id == "`table'"
				gen col = .
				local j = 0
				foreach s of local columns {
					local ++j
					replace col = `j' if sample_id == `s'
				}
				keep if !missing(col)

				gen stars = cond(coef_p < .01, "***", cond(coef_p < .05, "**", cond(coef_p < .10, "*", "")))
				gen coef = string(round(coef_b, .001), "%9.3f") + stars
				gen se = "(" + string(round(coef_se, .001), "%9.3f") + ")"

				// Single-policy tables only show policies in 2+ states and more
				// than 10 state-years, split into two panels by support
				gen byte panel = 1
				if "`singlepolicy'" != "" {
					merge m:1 policy using "${gendata}/3_3_policy_support.dta", ///
						keepusing(support_states support_obs) keep(match) nogen
					keep if support_states >= 2 & support_obs > 10
					replace panel = cond(support_states >= 3 & support_obs >= 20, 1, 2)
				}
				else {
					gen support_states = .
					gen support_obs = .
				}

				keep spec_order spec_label panel support_states support_obs col coef se
				reshape wide coef se, i(spec_order) j(col)
				forvalues j = 1/`ncols' {
					capture gen coef`j' = ""
					capture gen se`j' = ""
				}
				sort panel spec_order
				replace spec_label = subinstr(subinstr(spec_label, "_", "\_", .), "&", "\&", .)

				tempfile rows
				save `rows'

			**Sample-size footer (shows a range when it varies across specs)

				use "${gendata}/3_3_ppml_accounting.dta", clear
				keep if table_id == "`table'"
				collapse (min) raw_N_lo = raw_N projects_lo = projects pop_lo = pop ///
						N_full_lo = N_full N_used_lo = N_used singletons_lo = singletons separated_lo = separated ///
					(max) raw_N_hi = raw_N projects_hi = projects pop_hi = pop ///
						N_full_hi = N_full N_used_hi = N_used singletons_hi = singletons separated_hi = separated, ///
					by(sample_id)
				foreach m in raw_N projects pop N_full N_used singletons separated {
					gen `m' = string(`m'_lo, "%9.0f") if `m'_lo < .
					replace `m' = `m' + "-" + string(`m'_hi, "%9.0f") if `m'_lo != `m'_hi & `m'_hi < .
				}
				local j = 0
				foreach s of local columns {
					local ++j
					foreach m in raw_N projects pop N_full N_used singletons separated {
						quietly levelsof `m' if sample_id == `s', local(`m'`j') clean
					}
				}

			**Write the file

				use `rows', clear
				// Wide tables (8+ columns) get smaller text and tighter spacing
				local size = cond(`totalcols' >= 8, "\scriptsize", "\footnotesize")
				local sep = cond(`totalcols' >= 8, "2pt", "3pt")
				local fullwidth "@{}>{\RaggedRight\arraybackslash}p{\dimexpr\linewidth-2\tabcolsep\relax}@{}"
				local blank = cond("`singlepolicy'" != "", " &  & ", "")

				file open tab using "${tables}/`file'", write replace text
				file write tab "\begin{table}[!htbp]" _n
				file write tab "\centering" _n
				file write tab "`size'" _n
				file write tab "\setlength{\tabcolsep}{`sep'}" _n
				file write tab "\renewcommand{\arraystretch}{1.08}" _n
				file write tab "\caption{`title'}" _n
				file write tab "\label{tab:`label'}" _n
				file write tab "\begin{tabularx}{\textwidth}{@{}>{\RaggedRight\arraybackslash}X *{`=`totalcols'-1'}{>{\Centering\arraybackslash}X}@{}}" _n
				file write tab "\hline" _n

				// Header row
				file write tab "Specification"
				if "`singlepolicy'" != "" file write tab " & \# States & \# State-years"
				local rest `"`labels'"'
				forvalues j = 1/`ncols' {
					gettoken lab rest : rest, parse("|")
					if "`lab'" == "|" gettoken lab rest : rest, parse("|")
					file write tab " & " (subinstr(trim("`lab'"), "&", "\&", .))
				}
				file write tab " \\" _n
				file write tab "\hline" _n

				// Coefficient rows, with standard errors underneath
				forvalues i = 1/`=_N' {
					if "`singlepolicy'" != "" & (`i' == 1 | panel[`i'] != panel[max(`i'-1, 1)]) {
						local heading = cond(panel[`i'] == 1, "Policies with 3+ states and 20+ state-years", ///
							"Policies with 2+ states and more than 10 state-years")
						file write tab "\multicolumn{`totalcols'}{`fullwidth'}{\textit{`heading'}}\\" _n
					}
					file write tab (spec_label[`i'])
					if "`singlepolicy'" != "" {
						file write tab " & " (string(support_states[`i'], "%9.0f")) " & " (string(support_obs[`i'], "%9.0f"))
					}
					forvalues j = 1/`ncols' {
						file write tab " & " (coef`j'[`i'])
					}
					file write tab " \\" _n
					file write tab "`blank'"
					forvalues j = 1/`ncols' {
						file write tab " & " (se`j'[`i'])
					}
					file write tab " \\" _n
				}
				file write tab "\hline" _n

				// Footer
				local f_raw_N		"Raw sample N"
				local f_projects	"Projects, 2005--2017"
				local f_pop			"Total diaspora pop., 2005--2017"
				local f_N_full		"e(N\_full)"
				local f_N_used		"e(N)"
				local f_singletons	"Dropped singletons"
				local f_separated	"Dropped separated obs"
				foreach m in raw_N projects pop N_full N_used singletons separated {
					file write tab "`f_`m''`blank'"
					forvalues j = 1/`ncols' {
						file write tab " & ``m'`j''"
					}
					file write tab " \\" _n
				}
				file write tab "\hline" _n
				file write tab "\fulltablenote{`totalcols'}{Cells are coefficients on ln\_dias or ln\_dias x policy, with SEs directly underneath.}" _n
				file write tab "\fulltablenote{`totalcols'}{* p<0.10, ** p<0.05, *** p<0.01.}" _n
				file write tab "\end{tabularx}" _n
				file write tab "\end{table}" _n
				file close tab
		end

********
*
*	5. Tables 3-13 and A8-A24
*
********

	**Column headers for each group of tables

		local base_cols "15 11 12 13 14"
		local base_labs "First-gen all diaspora, ICT FDI | First-gen 25+ high-ed, all FDI | First-gen 25+ all diaspora, all FDI | All-gen 25+ all diaspora, all FDI | All-gen all diaspora, all FDI"

		local clus_cols "21 22 23 24 25 26 27 28"
		local clus_labs "First-gen 25+ high-ed, all FDI | First-gen 25+ high-ed, ICT FDI | First-gen 25+ high-ed, Professional Services FDI | First-gen 25+ high-ed, Financial Services FDI | First-gen 25+ high-ed, Creative Industries FDI | First-gen 25+ high-ed, Life Sciences FDI | First-gen 25+ high-ed, Industrial FDI | First-gen 25+ high-ed, Transport Equipment FDI"

		local act_cols "31 32 33 34 35"
		local act_labs "First-gen 25+ high-ed, all FDI | First-gen 25+ high-ed, Sales, Marketing & Support FDI | First-gen 25+ high-ed, Design, Development & Testing FDI | First-gen 25+ high-ed, Manufacturing FDI | First-gen 25+ high-ed, Business Services FDI"

		local size_cols "41 42 43 44"
		local size_labs "First-gen 25+ high-ed, all FDI, small-75 companies | First-gen 25+ high-ed, ICT FDI, small-75 companies | First-gen 25+ high-ed, all FDI, large-75 companies | First-gen 25+ high-ed, ICT FDI, large-75 companies"

		local gen_cols "51 52 53 54"
		local gen_labs "First-gen 25+ all diaspora, ICT FDI | All-gen 25+ all diaspora, ICT FDI | First-gen 25+ high-ed, ICT FDI | All-gen 25+ high-ed, ICT FDI"

		local wrk_cols "61 62 63 64"
		local wrk_labs "First-gen 25+ high-ed, ICT FDI | All-gen 25+ high-ed, ICT FDI | First-gen 25+ high-ed, ICT FDI, ICT worker | All-gen 25+ high-ed, ICT FDI, ICT worker"

		local ictsize_cols "71 72 73 74"
		local ictsize_labs "First-gen 25+ high-ed, ICT FDI, all companies | First-gen 25+ high-ed, ICT FDI, all companies, ICT worker | First-gen 25+ high-ed, ICT FDI, small-75 companies | First-gen 25+ high-ed, ICT FDI, small-75 companies, ICT worker"

		local hub_cols "81 82 83 84"
		local hub_labs "First-gen 25+ all diaspora, ICT FDI, all companies, tech hubs | First-gen 25+ all diaspora, ICT FDI, all companies, ICT worker, tech hubs | First-gen 25+ all diaspora, ICT FDI, small-75 companies, tech hubs | First-gen 25+ all diaspora, ICT FDI, small-75 companies, ICT worker, tech hubs"

	**Tables 3-7: baseline all-FDI samples

		write_table, table(h0) file(3_3_tab3_h0_baseline.tex) label(final_baseline_h0) ///
			title("H0: location-specific diaspora versus national Indian diaspora stock: baseline all-FDI samples") ///
			columns(`base_cols') labels("`base_labs'")
		write_table, table(table2_h1) file(3_3_tab4_any_dep_baseline.tex) label(final_baseline_table2_h1) ///
			title("Any DEP adoption x diaspora: baseline all-FDI samples") ///
			columns(`base_cols') labels("`base_labs'")
		write_table, table(table3_h2) file(3_3_tab5_dep_count_baseline.tex) label(final_baseline_table3_h2) ///
			title("DEP-count intensity x diaspora: baseline all-FDI samples") ///
			columns(`base_cols') labels("`base_labs'")
		write_table, table(table4_h3) file(3_3_tab6_dep_category_baseline.tex) label(final_baseline_table4_h3) ///
			title("Category-level policy interactions: baseline all-FDI samples") ///
			columns(`base_cols') labels("`base_labs'")
		write_table, table(singlepolicy) file(3_3_tab7_single_policy_baseline.tex) label(final_baseline_appendix_singlepolicy) ///
			title("Baseline all-FDI samples: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`base_cols') labels("`base_labs'") singlepolicy

	**Tables 8, A8, A9: sector (cluster) cuts

		write_table, table(table2_h1) file(3_3_tab8_any_dep_cluster.tex) label(final_cluster_table2_h1) ///
			title("Sector cuts: any DEP adoption x diaspora") ///
			columns(`clus_cols') labels("`clus_labs'")
		write_table, table(table4_h3) file(3_3_tabA8_dep_category_cluster.tex) label(final_cluster_table4_h3) ///
			title("Sector cuts: category-level policy interactions") ///
			columns(`clus_cols') labels("`clus_labs'")
		write_table, table(singlepolicy) file(3_3_tabA9_single_policy_cluster.tex) label(final_cluster_appendix_singlepolicy) ///
			title("Sector cuts: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`clus_cols') labels("`clus_labs'") singlepolicy

	**Tables A10-A12: activity cuts

		write_table, table(table2_h1) file(3_3_tabA10_any_dep_activity.tex) label(final_activity_table2_h1) ///
			title("Activity cuts: any DEP adoption x diaspora") ///
			columns(`act_cols') labels("`act_labs'")
		write_table, table(table4_h3) file(3_3_tabA11_dep_category_activity.tex) label(final_activity_table4_h3) ///
			title("Activity cuts: category-level policy interactions") ///
			columns(`act_cols') labels("`act_labs'")
		write_table, table(singlepolicy) file(3_3_tabA12_single_policy_activity.tex) label(final_activity_appendix_singlepolicy) ///
			title("Activity cuts: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`act_cols') labels("`act_labs'") singlepolicy

	**Tables A13, A14, 9, A15, 10, 11: company-size samples

		write_table, table(h0) file(3_3_tabA13_h0_company_size.tex) label(final_company_size_h0) ///
			title("H0: location-specific diaspora versus national Indian diaspora stock: company-size FDI samples") ///
			columns(`size_cols') labels("`size_labs'")
		write_table, table(table1_baseline) file(3_3_tabA14_diaspora_only_company_size.tex) label(final_company_size_table1_baseline) ///
			title("Diaspora-only PPML: company-size FDI samples") ///
			columns(`size_cols') labels("`size_labs'")
		write_table, table(table2_h1) file(3_3_tab9_any_dep_company_size.tex) label(final_company_size_table2_h1) ///
			title("Any DEP adoption x diaspora: company-size FDI samples") ///
			columns(`size_cols') labels("`size_labs'")
		write_table, table(table3_h2) file(3_3_tabA15_dep_count_company_size.tex) label(final_company_size_table3_h2) ///
			title("DEP-count intensity x diaspora: company-size FDI samples") ///
			columns(`size_cols') labels("`size_labs'")
		write_table, table(table4_h3) file(3_3_tab10_dep_category_company_size.tex) label(final_company_size_table4_h3) ///
			title("Category-level policy interactions: company-size FDI samples") ///
			columns(`size_cols') labels("`size_labs'")
		write_table, table(singlepolicy) file(3_3_tab11_single_policy_company_size.tex) label(final_company_size_appendix_singlepolicy) ///
			title("Company-size FDI samples: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`size_cols') labels("`size_labs'") singlepolicy

	**Tables 12, A16, A17: ICT cuts by generation and education

		write_table, table(table2_h1) file(3_3_tab12_any_dep_ict_generation.tex) label(final_ict_generations_education_table2_h1) ///
			title("ICT FDI by diaspora generation and education: any DEP adoption x diaspora") ///
			columns(`gen_cols') labels("`gen_labs'")
		write_table, table(table4_h3) file(3_3_tabA16_dep_category_ict_generation.tex) label(final_ict_generations_education_table4_h3) ///
			title("ICT FDI by diaspora generation and education: category-level policy interactions") ///
			columns(`gen_cols') labels("`gen_labs'")
		write_table, table(singlepolicy) file(3_3_tabA17_single_policy_ict_generation.tex) label(final_ict_generations_education_appendix_singlepolicy) ///
			title("ICT FDI by diaspora generation and education: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`gen_cols') labels("`gen_labs'") singlepolicy

	**Tables A18, 13, A19: ICT cuts, ICT workers vs everyone

		write_table, table(table2_h1) file(3_3_tabA18_any_dep_ict_worker.tex) label(final_ict_worker_table2_h1) ///
			title("ICT FDI, ICT-worker diaspora: any DEP adoption x diaspora") ///
			columns(`wrk_cols') labels("`wrk_labs'")
		write_table, table(table4_h3) file(3_3_tab13_dep_category_ict_worker.tex) label(final_ict_worker_table4_h3) ///
			title("ICT FDI, ICT-worker diaspora: category-level policy interactions") ///
			columns(`wrk_cols') labels("`wrk_labs'")
		write_table, table(singlepolicy) file(3_3_tabA19_single_policy_ict_worker.tex) label(final_ict_worker_appendix_singlepolicy) ///
			title("ICT FDI, ICT-worker diaspora: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`wrk_cols') labels("`wrk_labs'") singlepolicy

	**Tables A20-A22: ICT cuts by company size

		write_table, table(table2_h1) file(3_3_tabA20_any_dep_ict_company_size.tex) label(final_ict_company_size_table2_h1) ///
			title("ICT FDI by company size: any DEP adoption x diaspora") ///
			columns(`ictsize_cols') labels("`ictsize_labs'")
		write_table, table(table4_h3) file(3_3_tabA21_dep_category_ict_company_size.tex) label(final_ict_company_size_table4_h3) ///
			title("ICT FDI by company size: category-level policy interactions") ///
			columns(`ictsize_cols') labels("`ictsize_labs'")
		write_table, table(singlepolicy) file(3_3_tabA22_single_policy_ict_company_size.tex) label(final_ict_company_size_appendix_singlepolicy) ///
			title("ICT FDI by company size: single-policy interactions, 2+ states and more than 10 state-years") ///
			columns(`ictsize_cols') labels("`ictsize_labs'") singlepolicy

	**Tables A23-A24: ICT cuts in tech-hub metros only

		write_table, table(table2_h1) file(3_3_tabA23_any_dep_tech_hubs.tex) label(final_ict_company_size_techhubs_table2_h1) ///
			title("ICT FDI from tech-hub metros: any DEP adoption x diaspora") ///
			columns(`hub_cols') labels("`hub_labs'")
		write_table, table(table4_h3) file(3_3_tabA24_dep_category_tech_hubs.tex) label(final_ict_company_size_techhubs_table4_h3) ///
			title("ICT FDI from tech-hub metros: category-level policy interactions") ///
			columns(`hub_cols') labels("`hub_labs'")

********
*
*	6. Table 14: State-specific policy interactions
*
********

	// Same interaction model, but the policy only "counts" in one state at a
	// time, to see whether a result is driven by a single state

	tempfile state_results
	frame create statecut int col str40 policy str20 state double(coef_b coef_se coef_p)
	local j = 0
	foreach outcome in fdi_projects_all fdi_projects_ict {
		local ++j
		prep_panel, file(s1_firstgen_highed_25plus)
		quietly summarize `outcome'
		local projects`j' = string(r(sum), "%9.0f")
		quietly summarize n_people
		local pop`j' = string(r(sum), "%9.0f")

		foreach p in diaspora_admin_unit tax_regulatory_guidance diaspora_conferences {
			foreach st in "punjab" "tamil nadu" "kerala" "gujarat" {
				capture drop p_state
				gen double p_state = cond(indian_state == "`st'", `p', 0)
				quietly summarize p_state
				if missing(r(sd)) | r(sd) <= 0 continue

				capture quietly ppmlhdfe `outcome' c.ln_dias##c.p_state, ///
					absorb(od_id i.origin_id#i.year i.languaged#i.year) vce(cluster languaged)
				if _rc continue
				capture quietly lincom c.ln_dias#c.p_state
				if _rc continue
				frame post statecut (`j') ("`p'") ("`st'") (r(estimate)) (r(se)) (r(p))
			}
		}
	}

	frame change statecut
	gen stars = cond(coef_p < .01, "***", cond(coef_p < .05, "**", cond(coef_p < .10, "*", "")))
	gen coef = string(round(coef_b, .001), "%9.3f") + stars
	gen se = "(" + string(round(coef_se, .001), "%9.3f") + ")"

	local fullwidth "@{}>{\RaggedRight\arraybackslash}p{\dimexpr\linewidth-2\tabcolsep\relax}@{}"
	file open tab using "${tables}/3_3_tab14_state_specific_policies.tex", write replace text
	file write tab "\begin{table}[!htbp]" _n
	file write tab "\centering" _n
	file write tab "\footnotesize" _n
	file write tab "\setlength{\tabcolsep}{3pt}" _n
	file write tab "\renewcommand{\arraystretch}{1.08}" _n
	file write tab "\caption{State-specific policy interactions}" _n
	file write tab "\label{tab:final_statecuts_appendix_singlepolicy}" _n
	file write tab "\begin{tabularx}{\textwidth}{@{}>{\RaggedRight\arraybackslash}X *{2}{>{\Centering\arraybackslash}X}@{}}" _n
	file write tab "\hline" _n
	file write tab "Policy & First-gen 25+ high-ed, all FDI & First-gen 25+ high-ed, ICT FDI \\" _n
	file write tab "\hline" _n
	foreach st in "punjab" "tamil nadu" "kerala" "gujarat" {
		file write tab "\multicolumn{3}{`fullwidth'}{\textit{`=proper("`st'")'}}\\" _n
		foreach p in diaspora_admin_unit tax_regulatory_guidance diaspora_conferences {
			quietly count if state == "`st'" & policy == "`p'"
			if r(N) == 0 continue
			local coefrow = proper(subinstr("`p'", "_", " ", .))
			local serow ""
			forvalues j = 1/2 {
				quietly levelsof coef if state == "`st'" & policy == "`p'" & col == `j', local(c) clean
				quietly levelsof se if state == "`st'" & policy == "`p'" & col == `j', local(s) clean
				local coefrow "`coefrow' & `c'"
				local serow "`serow' & `s'"
			}
			file write tab "`coefrow' \\" _n
			file write tab "`serow' \\" _n
		}
	}
	file write tab "\hline" _n
	file write tab "Projects, 2005--2017 & `projects1' & `projects2' \\" _n
	file write tab "Total diaspora pop., 2005--2017 & `pop1' & `pop2' \\" _n
	file write tab "\hline" _n
	file write tab "\fulltablenote{3}{Each cell is from a PPML model interacting ln\_dias with the named policy limited to the section state.}" _n
	file write tab "\fulltablenote{3}{* p<0.10, ** p<0.05, *** p<0.01.}" _n
	file write tab "\end{tabularx}" _n
	file write tab "\end{table}" _n
	file close tab

	frame change default
	frame drop statecut

********
*
*	7. Table A25: One-at-a-time policy interactions by support
*
********

	// Every policy we could estimate, for the four main samples (S1-S4 are
	// Samples 1-4 in Table 1), split into three panels by how many states
	// and state-years have the policy

	**Coefficients side by side

		use "${gendata}/3_3_ppml_results.dta", clear
		keep if table_id == "singlepolicy" & inlist(sample_id, 1, 2, 3, 4)
		merge m:1 policy using "${gendata}/3_3_policy_support.dta", ///
			keepusing(support_states support_obs item_order) keep(match) nogen

		gen stars = cond(coef_p < .01, "***", cond(coef_p < .05, "**", cond(coef_p < .10, "*", "")))
		gen coef = string(round(coef_b, .001), "%9.3f") + stars
		gen se = "(" + string(round(coef_se, .001), "%9.3f") + ")"
		keep policy item_order support_states support_obs sample_id coef se
		reshape wide coef se, i(policy) j(sample_id)

		gen byte panel = 3
		replace panel = 2 if support_states >= 2 & support_obs >= 10
		replace panel = 1 if support_states >= 3 & support_obs >= 20
		sort panel item_order

		gen rowlabel = proper(subinstr(policy, "_", " ", .))
		replace rowlabel = subinstr(subinstr(rowlabel, "Nri ", "NRI ", .), " For ", " for ", .)

	**Sample-size footer

		preserve
			use "${gendata}/3_3_ppml_accounting.dta", clear
			keep if table_id == "singlepolicy" & inlist(sample_id, 1, 2, 3, 4)
			collapse (min) raw_N_lo = raw_N N_full_lo = N_full N_used_lo = N_used ///
					singletons_lo = singletons separated_lo = separated ///
				(max) raw_N_hi = raw_N N_full_hi = N_full N_used_hi = N_used ///
					singletons_hi = singletons separated_hi = separated, by(sample_id)
			foreach m in raw_N N_full N_used singletons separated {
				gen `m' = string(`m'_lo, "%9.0f")
				replace `m' = `m' + "-" + string(`m'_hi, "%9.0f") if `m'_lo != `m'_hi
				forvalues s = 1/4 {
					quietly levelsof `m' if sample_id == `s', local(`m'`s') clean
				}
			}
		restore

	**Write the longtable (it runs across several pages)

		local width "4.1cm+1.2cm+1.7cm+1.35cm+1.35cm+1.35cm+1.35cm"
		local fullrow "\multicolumn{7}{@{}p{\dimexpr`width'\relax}@{}}"
		local header "Policy & \# States & \# State-years & S1 & S2 & S3 & S4 \\"

		file open tab using "${tables}/3_3_tabA25_single_policy_by_support.tex", write replace text
		file write tab "\begin{longtable}{@{}>{\raggedright\arraybackslash}p{4.1cm}" _n
		file write tab ">{\centering\arraybackslash}p{1.2cm}" _n
		file write tab ">{\centering\arraybackslash}p{1.7cm}" _n
		forvalues j = 1/3 {
			file write tab ">{\centering\arraybackslash}p{1.35cm}" _n
		}
		file write tab ">{\centering\arraybackslash}p{1.35cm}@{}}" _n
		file write tab "\caption{Appendix. One-at-a-Time Policy Interactions Split by Treatment Support}" _n
		file write tab "\label{tab:appendix_singlepolicy}\\" _n
		file write tab "\toprule" _n
		file write tab "`header'" _n
		file write tab "\midrule" _n
		file write tab "\endfirsthead" _n
		file write tab "" _n
		file write tab "\multicolumn{7}{@{}l}{\textit{Table \thetable\ continued}}\\" _n
		file write tab "\toprule" _n
		file write tab "`header'" _n
		file write tab "\midrule" _n
		file write tab "\endhead" _n
		file write tab "" _n
		file write tab "\midrule" _n
		file write tab "\multicolumn{7}{r@{}}{\textit{Continued on next page}}\\" _n
		file write tab "\endfoot" _n
		file write tab "" _n
		file write tab "\bottomrule" _n
		file write tab "\endlastfoot" _n
		file write tab "" _n

		local heading1 "Panel A: Policies with support in at least 3 states and 20 state-years"
		local heading2 "Panel B: Policies with support in at least 2 states and 10 state-years, but below 3 states and 20 state-years"
		local heading3 "Panel C: All remaining policies"

		forvalues i = 1/`=_N' {
			local p = panel[`i']
			if `i' == 1 | `p' != panel[max(`i'-1, 1)] {
				if `i' > 1 {
					file write tab "" _n
					file write tab "\midrule" _n
				}
				file write tab "`fullrow'{\textit{`heading`p''}}\\" _n
			}
			// Support counts repeat on the standard-error row
			local support = string(support_states[`i'], "%9.0f") + " & " + string(support_obs[`i'], "%9.0f")
			file write tab (rowlabel[`i']) " & `support'"
			forvalues s = 1/4 {
				file write tab " & " (coef`s'[`i'])
			}
			file write tab " \\" _n
			file write tab " & `support'"
			forvalues s = 1/4 {
				file write tab " & " (se`s'[`i'])
			}
			file write tab " \\" _n
		}

		file write tab "" _n
		file write tab "\midrule" _n
		local f_raw_N		"Raw sample N"
		local f_N_full		"e(N full)"
		local f_N_used		"e(N)"
		local f_singletons	"Dropped singletons"
		local f_separated	"Dropped separated observations"
		foreach m in raw_N N_full N_used singletons separated {
			file write tab "`f_`m'' &  & "
			forvalues s = 1/4 {
				file write tab " & ``m'`s''"
			}
			file write tab " \\" _n
		}
		file write tab "" _n
		// Dollar signs built with char(36), since Stata reads "$S1" as a global
		local d = char(36)
		file write tab "`fullrow'{\footnotesize \textit{Notes:} Cells report coefficients from one-at-a-time policy interaction models, with standard errors in parentheses directly underneath. Support counts come from the raw DEP state-year panel, 2005--2017. `d'S1`d'--`d'S4`d' correspond to the four main estimation samples used in the paper. `d'^{*}p<0.10`d', `d'^{**}p<0.05`d', `d'^{***}p<0.01`d'.} \\" _n
		file write tab "\end{longtable}" _n
		file close tab

********
*
*	8. Close log file
*
********

	log close stage
