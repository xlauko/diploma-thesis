
all: thesis_skeleton.latex appendix.tex
	pandoc chapters/*.md ref-appendix/references.tex \
	--include-after-body=ref-appendix/appendix.tex \
	--atx-headers \
	--filter=pandoc-citeproc \
	--latex-engine=pdflatex --template=thesis_skeleton.latex \
	--bibliography=bib/thesis.bib --csl=bib/ieee.csl \
	-S \
    -V bibfile='bib/thesis.bib' \
	-V bibtitle='Bibliography' \
	-V documentclass='scrbook' \
	-V fontfamily='times' \
	-V author='Henrich Lauko' \
	-V year='2017' \
	-V department='Faculty of Informatics' \
	-V university='Masaryk University' \
	-V title='Symbolic Model Checking via Program Transformations' \
	-V subtitle='Diploma Thesis' \
	-V supervisor='RNDr. Petr Ročkai, Ph.D.' \
	-V university_logo='img/fi-logo' \
	-f markdown -o thesis.pdf
	rm thesis_skeleton.latex ref-appendix/appendix.tex

appendix.tex: ref-appendix/appendix.md
	pandoc -f markdown -t latex ref-appendix/appendix.md -o ref-appendix/appendix.tex

thesis_skeleton.latex: classicthesis/ClassicThesis.tex
	python template_gen.py
