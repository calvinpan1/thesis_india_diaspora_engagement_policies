# Replication package: Do Subnational Diaspora Engagement Policies Attract FDI? Evidence from India

Calvin Pan, University of Virginia, Department of Politics (BA thesis, 2026)

This folder rebuilds every data-driven table and figure in the thesis, from raw
data to the LaTeX file. Run one Stata do file, then compile `main.tex`.

## Quick start

1. Get the IPUMS extract (see [Getting the data](#getting-the-data)) and save it as
   `Raw_Data/ipums/usa_00014.dta`.
2. Open Stata 18 (the app, not the command line, see [Figure fonts](#figure-fonts)),
   `cd` into this folder, and run:
   ```stata
   do "Syntax/0_master.do"
   ```
3. Upload this whole folder to Overleaf, set the compiler to **LuaLaTeX**
   (Menu > Compiler) and the main document to `main.tex`. Or compile locally
   with `latexmk -lualatex main.tex`.

The whole pipeline takes about 7 minutes on an M2 MacBook Air (Stata/MP 18). About
6 of those are the PPML regressions in `3_3_tab_ppml.do`. Everything else takes
under 30 seconds, including reading the 2.2 GB IPUMS file.

## What's in here

```
replication_package/
├── main.tex, UVAthesis.cls, articles.bib   the thesis, pulling in tables and figures below
├── main.pdf                                 the compiled thesis
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
├── Generated_Datasets/   intermediate data (not in the repo, rebuilt by the code)
├── Log_Files/            one text log per do file
└── Tables_and_Figures/
    ├── tables/          .tex tables, \input by main.tex
    └── figures/         .png figures, used by main.tex
```

Every do file and every file it writes starts with its stage number, so you can
always tell where something came from. `3_3_tab7_2_any_dep_baseline.tex` is
written by `3_tables/3_3_tab_ppml.do` and is Table 7.2 in the thesis. Outputs
overwrite themselves on every run.

## Run order

`0_master.do` runs these in order. Each one can also be run on its own once the
master has set the folder globals (`$root`, `$rawdata`, ...) in your session.

| Step | File | What it does | Time |
|---|---|---|---|
| 1 | `1_build/1_1_acs_clean.do` | Reads the 62M-row IPUMS file once, keeps people born in India or speaking an Indian state language. Skipped if its output already exists. | ~10 s |
| 2 | `2_clean/2_1_acs_samples.do` | Diaspora counts by US metro x language x year for each sample, ranks each language's metros | ~1 s |
| 3 | `2_clean/2_2_fdi_clean.do` | Licensed fDi data to public extracts. Skips itself if the licensed files aren't there. | ~1 s |
| 4 | `2_clean/2_3_deps_clean.do` | DEP and budget panels, year each policy switches on | ~1 s |
| 5 | `2_clean/2_4_merge_samples.do` | Diaspora x FDI x DEPs, top-50 metros per language | ~1 s |
| 6 | `3_tables/3_1_tab_descriptives.do` | Table 5.2 | <1 s |
| 7 | `3_tables/3_2_tab_policy_bundling.do` | Tables 5.1, 6.1 | <1 s |
| 8 | `3_tables/3_3_tab_ppml.do` | Tables 7.1-7.29, B.1 | ~6 min |
| 9 | `4_figures/4_1_fig_descriptives.do` | Figures 5.2-5.14, 8.2 | ~7 s |
| 10 | `4_figures/4_2_fig_lang_verification.do` | Figures 4.4-4.7 (and A.1-A.2) | ~1 s |
| 11 | `4_figures/4_3_fig_budgets.do` | Figure 4.8 | ~1 s |
| 12 | `4_figures/4_4_fig_policy_bundling.do` | Figures 5.15, 5.16, unnumbered figure after 8.2 | ~4 s |
| 13 | `4_figures/4_5_fig_sectoral.do` | Figure 6.4 | ~1 s |
| 14 | `4_figures/4_6_fig_investor_names.do` | Figure 5.1 | ~1 s |

Tables and figures used more than once in the thesis (Figure 5.2 = 6.1,
5.11 = 6.2, 5.16 = 6.3, 5.14 = 8.1, 4.6 = A.1, 4.4 = A.2) are made once and
named after their first appearance.

Not made from data, so they live in `static_figures/` or are typed into
`main.tex`: Figures 2.1, 2.2, 4.1-4.3, and Tables 6.2, A.1-A.5, C.1.

### Software

- **Stata 18** (MP or SE). Earlier versions back to 16 should work but weren't tested.
- **ftools, reghdfe, ppmlhdfe** from SSC. `0_master.do` installs them if they're
  missing. Versions used: ppmlhdfe 2.3.3, reghdfe 6.13.1, ftools 2.50.0.
- **LuaLaTeX** for the paper (`lua-ul` needs it). TeX Live 2024 or Overleaf.

## Getting the data

### 1. IPUMS USA (American Community Survey): download it yourself

IPUMS doesn't allow redistributing its data, so you need a free account at
<https://usa.ipums.org>. Make this extract:

- **Samples**: the 13 ACS 1-year samples, **2005 ACS through 2017 ACS**
  (the default "1%" samples, *not* 3-year or 5-year). My original extract also
  had 2018-2024, which the code drops, so leave those out to save space.
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

  The original extract (`usa_00014`) also had `MET2013ERR`, `INDNAICS`, and
  `INCTOT`, which the final code doesn't use. You can drop IPUMS's automatic
  household variables too.
- **Cases**: all persons, no case selection.
- **Format**: Stata (.dta).

Save the file as `Raw_Data/ipums/usa_00014.dta`, or change the filename in
`1_build/1_1_acs_clean.do`.

Language codes the thesis uses (`LANGUAGED`): Malayalam 4004 (Kerala),
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

The thesis figures use CMU Serif (the Computer Modern font LaTeX uses). Stata
can only set graph fonts from the Stata app, not from batch or console mode
(`stata-mp -b`), where figures fall back to Helvetica. Everything else comes
out identical either way. To match the thesis, install CMU Serif and run the
master from the Stata app.
