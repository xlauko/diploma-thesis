% thesisimg.sty
% (c) 2017 Henrich Lauko template for thesis images

\ProvidesClass{thesis-img}[2017/07/14 v 0.1 THESI]
\LoadClass[crop,tikz,convert={outext=.svg,command=\unexpanded{pdf2svg \infile\space\outfile}},multi=false]{standalone}[2012/04/13]

\NeedsTeXFormat{LaTeX2e}

\RequirePackage{iftex}
\ifPDFTeX
    \RequirePackage{etex}
    \RequirePackage[utf8]{inputenc}
    \RequirePackage[T1]{fontenc}
    \RequirePackage{lmodern}
\else
    \RequirePackage{fontspec}
    \setmainfont{Latin Modern Roman}
\fi

\RequirePackage{ifthen}

\RequirePackage{tikz}
\usetikzlibrary{
	chains,fit,shapes,
	shapes.multipart,
	matrix,
	positioning,
	shapes.callouts,
	shapes.arrows,
	shapes.geometric,
	arrows,
	calc
}

\tikzset{
  treenode/.style = {align=center, inner sep=0pt, text centered, font=\sffamily},
  tnode/.style = {treenode, circle, black, draw=black, text width=1.5em, thick},
  bnode/.style = {treenode, circle, white, font=\sffamily, draw=black, fill=black, text width=1.5em},
  rnode/.style = {treenode, circle, red, draw=red, text width=1.5em, very thick},
  nilnode/.style = {treenode, minimum width=1.3em, minimum height=0.9em},
  leaf/.style = {isosceles triangle, draw, shape border rotate=90, minimum height=13mm, minimum width=5mm}
}
