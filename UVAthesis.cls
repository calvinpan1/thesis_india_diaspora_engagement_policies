% UVAthesis.cls - Provides a class for theses and dissertations
% 2021 Ricky Patterson
% Based on VTthesis.cls Copyright (C) 2016,2017 Alan M. Lattimer
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
%
% Please see the GNU General Public License: <http://www.gnu.org/licenses/>.
%
%-------------------------------------------------------------------------
% Revision Information for VTthesis.cls
%   v1.0 Adapted Thesis class written by Erich L. Foster, 10 April 2012
%   v1.1 Modifications by Alan Lattimer, 1/29/16
%   v1.2 Fixed TOC problems, Alan Lattimer, 3/24/16
%   v1.2 Fixed missing package problems, Alan Lattimer, 4/5/16
%   v1.4 Added the ability to change the institution, 8/16/16
%   v1.5 Added a flag to prevent page skips after the front matter, 5/2/17
%   v1.6 Added List of Abbreviations, Carrie Cross, 9/8/17
%   v1.7 Fixed excess whitespace problems, Carrie Cross & LianTze Lim, 9/20/17
%   v1.8 Modified date-setting macro, Carrie Cross, 10/5/17
%	v1.9 Changed the LaTex rendering engine, Carrie Cross & Robert Browder, 4/27/18
%	v2.0 Updated instructions, Carrie Cross & Robert Browder, 4/30/18
%   v2.1 Created flexible page numbering for front matter, Carrie Cross & Robert Browder, 12/19/19
%   v2.2 Updated code for disabling ligatures to comply with Tex Live 2019 standards, Carrie Cross & LianTze Lim, 5/8/2020
%-------------------------------------------------------------------------
% Revision Information for UVAthesis.cls
%    v0.1 Adapted VTthesis.cls written by Alan Lattimer, 20 October 2021
%%% IDENTIFICATION --------------------------------------------------------
\NeedsTeXFormat{LaTeX2e}[01/01/10]
\ProvidesClass{UVAthesis}[2021/10/20 v0.1 UVA Thesis Class]
\RequirePackage{etoolbox}
%Declaration of options
\newbool{@sig}
\boolfalse{@sig}
\newbool{@proposal}
\boolfalse{@proposal}
\newbool{@prelim}
\boolfalse{@prelim}
\newbool{@dbl}
\boolfalse{@dbl}
\newbool{@dft}
\boolfalse{@dft}
\newbool{@nopgskip}
\boolfalse{@nopgskip}

\DeclareOption{sig}{\booltrue{@sig}}
\DeclareOption{nosig}{\boolfalse{@sig}}
\DeclareOption{proposal}{\booltrue{@proposal}}
\DeclareOption{prelim}{\booltrue{@prelim}}
\DeclareOption{doublespace}{\booltrue{@dbl}}
\DeclareOption{draft}{\booltrue{@dft}}
\DeclareOption{nopageskip}{\booltrue{@nopgskip}}
%%% EXECUTION OF OPTIONS --------------------------------------------------
%% default to:
\ExecuteOptions{nosig}

\ProcessOptions

%%% PACKAGE LOADING -------------------------------------------------------
%% based on standard report class
\LoadClass[12pt,letterpaper,oneside]{report}

\RequirePackage[
  letterpaper,
  top=1in,
  bottom=1in,
  inner=1in,
  outer=1.5in
]{geometry}

%% AMSLaTeX math environments and symbols
\RequirePackage{amsmath,amsthm,amssymb,amsfonts}
\RequirePackage[normalem]{ulem}
\RequirePackage{enumerate}
\RequirePackage[backend=biber, style=numeric-comp, sorting=none, natbib=true]{biblatex}
\RequirePackage{paralist}
\RequirePackage[titletoc,page]{appendix}
\RequirePackage[nottoc]{tocbibind}

% Keep font setup simple for modern XeLaTeX engines.
\RequirePackage{fontspec}
\setmainfont[Ligatures={NoCommon,NoRare}]{Latin Modern Roman}

%package required for abbreviations page
\RequirePackage{nomencl}
\makenomenclature
\renewcommand{\nomname}{List of Abbreviations}

\setlength{\parindent}{2em}
\setlength{\parskip}{0.1in}
\usepackage{indentfirst}

% double space option
\RequirePackage{setspace}
\AtBeginDocument{\ifbool{@dbl}{\doublespacing}{}}

% links for references
\RequirePackage[final,colorlinks=true,allcolors=blue]{hyperref}

% For including pdf images: 
\RequirePackage{graphicx}
\RequirePackage{csquotes}
%\RequirePackage{float}

% MATLAB Code formattings
\RequirePackage{listings}
\RequirePackage{verbatim}


% Misc Packages
\RequirePackage{booktabs}
\RequirePackage[mathscr]{eucal}
\RequirePackage{tikz}
\usetikzlibrary{shapes,arrows}
\RequirePackage{todonotes}

% Packages required for subfigures
\RequirePackage{caption}
\RequirePackage{subcaption}


% Place a Draft Watermark, if a draft document
\PassOptionsToPackage{firstpage}{draftwatermark}
\RequirePackage{draftwatermark}
\ifbool{@dft}{
  \SetWatermarkScale{1} % Smaller numbers decrease the size of the watermark text. Originally set to 6.
  \SetWatermarkLightness{0.7}
}{
  \SetWatermarkText{}
}


% Define Theorems and such
\newtheorem{proposition}{Proposition}[chapter]
\newtheorem{theorem}[proposition]{Theorem}
\newtheorem{lemma}[proposition]{Lemma}
\newtheorem{corollary}[proposition]{Corollary}
\newtheorem{conjecture}[proposition]{Conjecture}

% Define style for definitions, etc.
\theoremstyle{definition}
\newtheorem{example}[proposition]{Example}
\newtheorem{definition}[proposition]{Definition}
\newtheorem{remark}[proposition]{Remark}
\newtheorem{algorithm}[proposition]{Algorithm}

\lstset{ % command to set programming language parameter(s)
frame=single,
  showstringspaces=false,
  showlines=false, %get rid of trailing white lines
  emptylines=1, %allow blank line
  breaklines=true, %get rid of overflow lines and enter \n
  numbers=left, %line number
  numberstyle=\scriptsize, %make line numbers small
  stepnumber=1, %line number every line
  numbersep=5pt,
  tabsize=2, %set tabs to two spaces
  basicstyle=\footnotesize, % print whole listing small
  keywordstyle=\bfseries,% green keywords
  stringstyle=\ttfamily % typewriter type for strings
  captionpos=b,% sets the caption-position to bottom
}

% \author,\title are defined in book; here are the rest of the front matter defining macros:
\def\@title{}
\def\@author{}
\def\@thesis{Your Document} %Dissertation or Thesis
\def\@degree{Your Degree}
\def\@program{Your Department}
\def\@institution{University of Virginia}
\def\@homeaddress{Your Hometown, State}
\def\@firstpriordegree{}
\def\@firstpriorinstitution{}
\def\@firstpriordate{}
\newbool{@2degrees}
\boolfalse{@2degrees}
\def\@secondpriordegree{}
\def\@secondpriorinstitution{}
\def\@secondpriordate{}
\def\@graddate{\ifcase\the\month\or
  January\or February\or March\or April\or May\or June\or
  July\or August\or September\or October\or November\or December\fi
  \space \number\the\year}

\def\type#1{\gdef\@type{#1}}
\def\thesis#1{\gdef\@thesis{#1}}
\def\degree#1{\gdef\@degree{#1}}
\def\program#1{\gdef\@program{#1}}
\def\institution#1{\gdef\@institution{#1}}
\def\homeaddress#1{\gdef\@homeaddress{#1}}
\def\firstpriordegree#1{\gdef\@firstpriordegree{#1}}
\def\firstpriorinstitution#1{\gdef\@firstpriorinstitution{#1}}
\def\firstpriordate#1{\gdef\@firstpriordate{#1}}
\def\secondpriordegree#1{\booltrue{@2degrees} \gdef\@secondpriordegree{#1}}
\def\secondpriorinstitution#1{\booltrue{@2degrees}\gdef\@secondpriorinstitution{#1}}
\def\secondpriordate#1{\booltrue{@2degrees}\gdef\@secondpriordate{#1}}
\def\graddate#1{\gdef\@graddate{#1}}

%\ifnum\month>9
  %  \@tempcnta=\year 
    % Un-comment the following line to advance the date by one year:
    %\advance\@tempcnta by 1 
  %  \edef\@copyrightyear{\number\the\@tempcnta}
%\else
  %  \def\@copyrightyear{\number\the\year}
%\fi

%committee information
\newbool{@1st}
\boolfalse{@1st}
\newbool{@2nd}
\boolfalse{@2nd}
\newbool{@3rd}
\boolfalse{@3rd}
\newbool{@4th}
\boolfalse{@4th}
\newbool{@5th}
\boolfalse{@5th}
\newbool{@coad}
\boolfalse{@coad}
\def\@advisor{}
\def\@coadvisor{}
\def\@secondmember{}
\def\@thirdmember{}
\def\@fourthmember{}
\def\@fifthmember{}
\def\@sixthmember{}
\def\advisor#1{\gdef\@advisor{#1}}
\def\coadvisor#1{\booltrue{@coad} \gdef\@coadvisor{#1}}
\def\secondmember#1{\booltrue{@1st} \gdef\@secondmember{#1}}
\def\thirdmember#1{\booltrue{@2nd} \gdef\@thirdmember{#1}}
\def\fourthmember#1{\booltrue{@3rd} \gdef\@fourthmember{#1}}
\def\fifthmember#1{\booltrue{@4th} \gdef\@fifthmember{#1}}
\def\sixthmember#1{\booltrue{@5th} \gdef\@sixthmember{#1}}

%abstract, acknowledgements, and dedication setup
\def\@abstract{}
\def\@acknowledge{}
\def\@dedication{}
\newbool{@abs}
\boolfalse{@abs}
\newbool{@ack}
\boolfalse{@ack}
\newbool{@ded}
\boolfalse{@ded}
\def\abstract#1{\booltrue{@abs} \gdef\@abstract{#1}}
\def\acknowledge#1{\booltrue{@ack} \gdef\@acknowledge{#1}}
\def\dedication#1{\booltrue{@ded} \gdef\@dedication{#1}}

% Set up the header and footer
\RequirePackage{fancyhdr}
\setlength{\headheight}{15pt}
\pagestyle{fancy}
\fancyhf{}

%keeps first pages of chapters from moving page numbers to the bottom center
\fancypagestyle{plain}{} 

%\renewcommand{\chaptermark}[1]{ \markboth{\chaptername \ \thechapter.\ #1}{}}
%\renewcommand{\sectionmark}[1]{\markright{\thesection.\ #1}}

%Set up up frontmatter, mainmatter, backmatter...
%The formatting for these sections will be different.
\newcommand{\frontmatter}{
  \ifbool{@nopgskip}
    {\clearpage}
    {\cleardoublepage}
  \clearpage
  \pagenumbering{roman} % defines page number style for front matter
  \fancyhead[L,R]{}
  %\fancyhf{}
  %\fancyhead[LE,RO]{\thepage}
  %\ifbool{@dft}{\fancyhead[C]{\textbf{DRAFT}}}{\fancyhead[C]{}}
  \fancyfoot[C]{\thepage}
  \fancyfoot[L,R]{}
  \renewcommand\headrulewidth{0.0pt}}
  
\newcommand{\mainmatter}{
  \ifbool{@nopgskip}
    {\clearpage}
    {\cleardoublepage}
  \pagenumbering{arabic} % defines page number style for main matter
  %\fancyhead[LE,RO]{\thepage}
  %\fancyhead[LE,RO]{\thepage}
  %\fancyhead[RE]{\sc \leftmark}
  %\fancyhead[LO]{\sc \rightmark}
  %\ifbool{@dft}{\fancyfoot[C]{\textbf{DRAFT}}}{\fancyfoot[C]{}}
  \renewcommand\headrulewidth{0.0pt}}
  
\newcommand{\biblio}{
  \fancyhead[C]{\bibname}}
  
\newcommand{\backmatter}{
  \ifbool{@nopgskip}
    {\clearpage}
    {\cleardoublepage}
  \addappheadtotoc
  \renewcommand{\chaptername}{\appendixname}
}

\apptocmd{\appendix}{\backmatter}{}{}

%Set up title page, abstract page, dedication page, and acknowledgement page
\def\uvatitlepage{
  \thispagestyle{empty}
  \begin{center}
  \MakeUppercase{\@title}\\
  \vfill
  \rm \@author\\
   \@homeaddress\\
   \bigskip
  %IF there is a 2nd prior degree
   \ifbool{@2degrees}{\noindent \@secondpriordegree , \@secondpriorinstitution , \@secondpriordate \\}{}

\vfill

    {\noindent A \@thesis\ submitted to the Faculty \\ 
    of the \@institution\ in Candidacy for \\
    the Distinguished Majors Program in Foreign Affairs\\
\bigskip
     Department of \@program \\
\vfill
    \@institution\\
    \@graddate\\
\vfill
  \begin{flushright}
  \begin{minipage}{0.35\textwidth}
    \noindent \@advisor\\
    \ifbool{@coad}{\@coadvisor, Co-chair\\}{}
    \ifbool{@1st}{\@secondmember\\}{}
    \ifbool{@2nd}{\@thirdmember\\}{}
    \ifbool{@3rd}{\@fourthmember\\}{}
    \ifbool{@4th}{\@fifthmember\\}{}
    \ifbool{@5th}{\@sixthmember\\}{}
  \end{minipage}
  \end{flushright}
  }
  \vfill


 

  \end{center}
\clearpage
%UVA GSAS says copyright page should be numbered
%\pagestyle{empty} % Suppresses page numbers for copyright page.

%Count the title page in the numbering, even though it is not numbered
\addtocounter{page}{1}
\vspace*{\fill}
%\includegraphics[height=2cm]{example-image}

Copyright \textcopyright\ \the\year{}, \@author\ 

\clearpage
  \newpage % This applies to the numbering of the front matter.
  %\addtocounter{page}{1} 
}

\def\abspage{
\pagestyle{fancy} % Restores all page numbers going forward, beginning at the abstract.
  \noindent {\Large \@title} \\
    
  \vfill
  \noindent  \@author \\
  \vfill

  (ABSTRACT)
  \vfill

  \@abstract
  \vfill
 \newpage

}


\def\ackpage{
  \chapter*{Acknowledgments}
  \@acknowledge
  \newpage
}

\def\dedpage{

\chapter*{Dedication}
  \vspace*{\fill}
  \begingroup
  \begin{center}
    \emph{\@dedication}
  \end{center}
  \endgroup
  \vspace*{\fill}
  \newpage
}

%This is where the main magic happens.
\renewcommand\maketitle{
  \setcounter{page}{0}
  \pdfbookmark[1]{Titlepage}{titlepage}
  \uvatitlepage
  \ifbool{@abs}{
    \pdfbookmark[1]{Abstract}{abstract}
    \abspage}{}
  \ifbool{@ded}{
    \pdfbookmark[1]{Dedication}{dedication}
    \dedpage}{}
  \ifbool{@ack}{
    \pdfbookmark[1]{Acknowledgements}{acknowledgements}
    \ackpage}{}
}

\patchcmd{\@makechapterhead}{\vspace*{50\p@}}{}{}{}  %% for numbered chapters \chapter{...}
\patchcmd{\@makeschapterhead}{\vspace*{50\p@}}{}{}{} %% for unnumbered chapters \chapter*{...}
