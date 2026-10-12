# Replication package: Do Subnational Diaspora Engagement Policies Attract FDI? Evidence from India

Calvin Pan, University of Virginia, Batten School of Public Policy (working paper, October 2026)

This folder rebuilds every data-driven table and figure in the working paper
(`paper.pdf`) and its online appendix (`online_appendix.pdf`), from raw data to
the compiled PDFs. Run one Stata do file, then compile the two LaTeX files.

## Quick start

1. Get the IPUMS extract (see [Getting the data](#getting-the-data)) and save it as
   `Raw_Data/ipums/usa_00014.dta`.
2. Open Stata 18 (the app, not the command line, see [Figure fonts](#figure-fonts)),
   `cd` into this folder, and run:
   ```stata
   do "Syntax/0_master.do"
   ```
3. Compile the paper and the online appendix with LuaLaTeX:
   ```bash
   latexmk -lualatex paper.tex && latexmk -lualatex online_appendix.tex
   ```
   On Overleaf, upload this whole folder, set the compiler to **LuaLaTeX**
   (Menu > Compiler), and pick `paper.tex` or `online_appendix.tex` as the main
   document.

The two documents cite each other's table and figure numbers through
`crossrefs.tex`, which is included. If you add or move a table, compile both
documents, run `python3 make_crossrefs.py`, and compile both again.

The whole pipeline takes about 7 minutes on an M2 MacBook Air (Stata/MP 18). About
6 of those are the PPML regressions in `3_3_tab_ppml.do`.

## What's in here

```
replication_package_working_paper/
├── paper.tex, paper.pdf                     the working paper
├── online_appendix.tex, online_appendix.pdf the online appendix
├── wp_preamble.tex                          shared layout (12pt, 1-inch margins, author-year)
├── crossrefs.tex, make_crossrefs.py         numbers each document cites from the other
├── articles.bib                             bibliography
├── static_figures/                          maps and diagrams that aren't made from data
├── Raw_Data/
│   ├── public/          DEP data I coded, DEP budgets (included)
│   ├── fdi_extracts/    aggregated FDI data built from fDi Markets (included)
│   ├── fdi_private/     licensed fDi Markets + CRSP files (NOT included)
│   └── ipums/           IPUMS ACS extract (NOT included, download it)
├── Syntax/
│   ├── 0_master.do      runs everything in order
│   ├── 1_build/         slow step that only needs to run once
│   ├── 2_clean/         cleaning and merging
│   ├── 3_tables/        one file per group of tables
│   └── 4_figures/       one file per group of figures
├── Generated_Datasets/  intermediate data (not in the repo, rebuilt by the code)
├── Log_Files/           one text log per do file
└── Tables_and_Figures/
    ├── tables/          .tex tables, \input by the paper and appendix
    └── figures/         .png figures
```

Every do file and every file it writes starts with its stage number, and every
table and figure file carries its number in the paper (`tab4`, `fig3`) or the
online appendix (`tabA13`, `figA9`). `3_3_tab4_any_dep_baseline.tex` is written
by `3_tables/3_3_tab_ppml.do` and is Table 4 in the paper. Outputs overwrite
themselves on every run.

## Run order

`0_master.do` runs these in order. Each one can also be run on its own once the
master has set the folder globals (`$root`, `$rawdata`, ...) in your session.

| Step | File | What it does | Paper | Online appendix | Time |
|---|---|---|---|---|---|
| 1 | `1_build/1_1_acs_clean.do` | Reads the 62M-row IPUMS file once, keeps people born in India or speaking an Indian state language. Skipped if its output already exists. | | | ~10 s |
| 2 | `2_clean/2_1_acs_samples.do` | Diaspora counts by US metro x language x year for each sample, ranks each language's metros | | | ~1 s |
| 3 | `2_clean/2_2_fdi_clean.do` | Licensed fDi data to public extracts. Skips itself if the licensed files aren't there. | | | ~1 s |
| 4 | `2_clean/2_3_deps_clean.do` | DEP and budget panels, year each policy switches on | | | ~1 s |
| 5 | `2_clean/2_4_merge_samples.do` | Diaspora x FDI x DEPs, top-50 metros per language | | | ~1 s |
| 6 | `3_tables/3_1_tab_descriptives.do` | Samples by number of observations | Table 1 | | <1 s |
| 7 | `3_tables/3_2_tab_policy_bundling.do` | DEP co-adoption and turn-on timing | | Tables A6-A7 | <1 s |
| 8 | `3_tables/3_3_tab_ppml.do` | All PPML results | Tables 3-14 | Tables A8-A25 | ~6 min |
| 9 | `4_figures/4_1_fig_descriptives.do` | FDI, diaspora, and DEP descriptives | Figures 6-7 | Figures A7-A14, A15-A17, A20 | ~7 s |
| 10 | `4_figures/4_2_fig_lang_verification.do` | Where speakers of each language were born | | Figures A3-A6 | ~1 s |
| 11 | `4_figures/4_3_fig_budgets.do` | DEP budgets | Figure 4 | | ~1 s |
| 12 | `4_figures/4_4_fig_policy_bundling.do` | Jaccard distribution, adoption timing | | Figures A18, A19, A21 | ~4 s |
| 13 | `4_figures/4_5_fig_sectoral.do` | Projects by sector | | Figure A22 | ~1 s |
| 14 | `4_figures/4_6_fig_investor_names.do` | Indian-name investor shares | Figure 5 | | ~1 s |

Not made from data, so they live in `static_figures/` or are typed into the
LaTeX: Table 2 and Figures 1-3 in the paper, and Tables A1-A5, A26 and Figures A1-A2
in the online appendix.

### Software

- **Stata 18** (MP or SE). Earlier versions back to 16 should work but weren't tested.
- **ftools, reghdfe, ppmlhdfe** from SSC. `0_master.do` installs them if they're
  missing. Versions used: ppmlhdfe 2.3.3, reghdfe 6.13.1, ftools 2.50.0.
- **LuaLaTeX** with biber, from TeX Live 2024 or Overleaf.
- **Python 3** only if you need to regenerate `crossrefs.tex`.

## Getting the data

### 1. IPUMS USA (American Community Survey): download it yourself

IPUMS doesn't allow redistributing its data, so you need a free account at
<https://usa.ipums.org>. Make this extract:

- **Samples**: the 13 ACS 1-year samples, **2005 ACS through 2017 ACS**
  (the default "1%" samples, *not* 3-year or 5-year).
- **Variables** (detailed versions where IPUMS offers them):

  | Variable | Used for |
  |---|---|
  | `YEAR` | survey year |
  | `STATEFIP` | US state |
  | `MET2013` | metro area (2013 delineations), the unit of analysis |
  | `PERWT` | person weight, every count is weighted |
  | `AGE` | the 25-and-over samples |
  | `BPL` / `BPLD` | born in India (`BPLD` = 52100) and the birthplace figures |
  | `LANGUAGE` / `LANGUAGED` | language spoken at home, which ties a person to an Indian state |
  | `EDUC` / `EDUCD` | college degree or more (`EDUCD` >= 101) |
  | `OCC1990` | ICT occupations |

- **Cases**: all persons, no case selection.
- **Format**: Stata (.dta).

Save the file as `Raw_Data/ipums/usa_00014.dta`, or change the filename in
`1_build/1_1_acs_clean.do`.

Language codes the paper uses (`LANGUAGED`): Malayalam 4004 (Kerala),
Tamil 4005 (Tamil Nadu), Gujarati 3115 (Gujarat), Kannada 3130 (Karnataka),
Marathi 3114 (Maharashtra), Punjabi 3113 (Punjab), Telugu 4003 (Andhra Pradesh),
Bengali 3112 (West Bengal), plus Nepali 4011 for the birthplace check.

### 2. fDi Markets: licensed, aggregated extracts included

FDI projects come from **fDi Markets** (Financial Times), a subscription
database, usually available through a university library. Its license doesn't
allow posting project-level records, so this package ships four aggregated
extracts in `Raw_Data/fdi_extracts/` and everything runs from those:

| Extract | Contents |
|---|---|
| `2_2_fdi_counts_metro_language_year.csv` | Number of projects from each US metro to each Indian state each year, by sector, activity, and company size. Counts only. |
| `2_2_fdi_state_year_top50.csv` | Projects, capital, and jobs by Indian state and year, top-50 diaspora metros only |
| `2_2_fdi_projects_by_cluster.csv` | Projects by sector, all years |
| `2_2_investor_name_shares.csv` | Share of projects, investors, and capital with possibly Indian-named investors |

To rebuild them from scratch you need fDi Markets access. The query: **source
country United States, destination country India, project dates 2005-2017, all
sectors, all project types (new, expansion, co-location)**, exported with
source city, destination state and city, sector ("cluster"), sub-sector,
activity, capital investment, jobs created, parent company, and contacts. I then added:

- `sourcecitymetro2013`: the source city's 2013 metro (MET2013) code.
- `techcompany`, `indianname`, `largecompany`: hand-coded flags.
- `capitalinvestmentreal`: inflation-adjusted capital investment (US$ millions).
- Public-company flags from matching parent company names to **CRSP** (via
  WRDS, also licensed) by fuzzy name match, kept if the company was listed on
  the project date.
- The "Indian name?" flag on each project's first listed contact, from the
  `instate` last-name model (Dhingra et al. 2023, arXiv:2303.06823), checked
  by hand in Excel.

Put the resulting four files (names in `Raw_Data/fdi_private/README.md`) in
`Raw_Data/fdi_private/` and `2_2_fdi_clean.do` will regenerate the extracts.

### 3. Data I collected (included)

- `Raw_Data/public/deps_state_year.csv`: 44 diaspora engagement policies
  (DEPs) for 8 Indian states, 2000-2025, hand-coded from state government
  documents, one row per state-year, 1 = the state has the policy that year.
  The columns go in taxonomy order: each `total_` column is followed by the
  policies in that category, which the code relies on. Andhra Pradesh stops in
  2013 because the state split in 2014.
- `Raw_Data/public/dep_budgets_state_year.csv`: each state's budget for its
  diaspora (NRI) department, 2005-2017, in 2023 rupees, per capita, and as a
  share of the state budget, from state budget documents. Blank means the
  documents weren't available (Gujarat, Karnataka 2016-17, Kerala 2015).

Both files only had their formatting cleaned compared to my working copies
(stray blank rows and columns, an Excel byte-order mark, `.` for missing). No
values changed.

## Figure fonts

The figures use CMU Serif (the Computer Modern font LaTeX uses). Stata can only
set graph fonts from the Stata app, not from batch or console mode
(`stata-mp -b`), where figures fall back to Helvetica. Everything else comes
out identical either way. To match the paper, install CMU Serif and run the
master from the Stata app.
