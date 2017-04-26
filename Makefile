
all: thesis_skeleton.latex appendix.tex
	pandoc chapters/*.md ref-appendix/references.tex \
	--include-before-body=frontback/dedication.tex \
	--include-before-body=frontback/acknowledgements.tex \
	--include-before-body=frontback/abstract.tex \
	--include-after-body=ref-appendix/appendix.tex \
	--atx-headers \
	--latex-engine=pdflatex --template=thesis_skeleton.latex \
	--bibliography=bib/thesis.bib --csl=bib/ieee.csl \
	-S \
    -V bibfile='thesis' \
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
