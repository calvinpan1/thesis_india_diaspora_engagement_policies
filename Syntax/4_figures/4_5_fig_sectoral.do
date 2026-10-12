*********************************************************************************
/*	TITLE:		4_5_fig_sectoral
*	PURPOSE:	Online Appendix Figure A22: number of FDI projects in each sector (fDi Markets
*				"cluster"), all companies.
*	AUTHOR:		Calvin Pan
*	CREATED:	2026_0430
*	UPDATED:	2026_1012
*	CALLS UPON:	"${rawdata}/fdi_extracts/2_2_fdi_projects_by_cluster.csv"
*	PRODUCES:	Figures:	"${figures}/4_5_figA22_projects_by_cluster.png"
*				Tables:		No
*				Datasets:	No
*	CONTENTS:	0: Start log file
*				1: Figure A22
*				2: Close log file
*/
*********************************************************************************

	capture log close stage
	log using "${logs}/4_5_fig_sectoral.log", replace text name(stage)

********
*
*	1. Figure A22: All companies by sector
*
********

	import delimited using "${rawdata}/fdi_extracts/2_2_fdi_projects_by_cluster.csv", clear varnames(1)

	graph hbar (asis) n_projects, ///
		over(cluster, sort(1) descending label(labsize(small))) ///
		title("All Companies: Projects by Cluster", size(11pt)) ///
		ytitle("Number of projects", size(10pt)) ///
		blabel(bar, size(vsmall) format(%9.0fc)) ///
		graphregion(color(white))
	graph export "${figures}/4_5_figA22_projects_by_cluster.png", replace width(3600) height(2400)

********
*
*	2. Close log file
*
********

	log close stage
