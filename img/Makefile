ALL=$(wildcard *.tex)

all: $(ALL:.tex=.png)
	make clean-aux

clean-aux:
	@rm -f *.aux *.dvi *.log *.synctex.gz *.out *.nav *.snm *.toc *.vrb

clean: clean-aux
	rm -f *.png

%.svg: %.tex ./thesis-img.cls
	pdflatex -shell-escape $<

%.png: %.svg
	convert $< $@
