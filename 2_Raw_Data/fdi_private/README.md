# Licensed fDi Markets and CRSP files (not included)

These four files are project-level fDi Markets data (plus CRSP matches from
WRDS). Both are licensed and can't be posted publicly. If you have access, put
them here and `2_2_fdi_clean.do` will rebuild the extracts in `../fdi_extracts/`.
Without them, the package runs on those extracts, which are already included.

- `0428.fdi.csv`: one row per US-to-India greenfield FDI project, 2005-2017 (3,183 projects)
- `0428.fdi.sectoral.csv`: the same projects with fDi's "activity" field
- `0428.fdi.crsp_parent_public.csv`: parent companies matched to CRSP
- `investor_name_results.csv`: projects with the first listed contact's name
  and a hand-checked "Indian name?" flag

See the main README for how each was put together.
