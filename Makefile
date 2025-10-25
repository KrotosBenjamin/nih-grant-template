R01_LIMIT=12
R21_LIMIT=6
R03_LIMIT=6

.PHONY: all r01 r21 r03 clean

all: r01 r21 r03

r01:
	quarto render mechanisms/r01.qmd --to pdf
	python3 scripts/check_pages.py _output/r01.pdf $(R01_LIMIT) || true
	quarto render mechanisms/r01.qmd --to docx

r21:
	quarto render mechanisms/r21.qmd --to pdf
	python3 scripts/check_pages.py _output/r21.pdf $(R21_LIMIT) || true
	quarto render mechanisms/r21.qmd --to docx

r03:
	quarto render mechanisms/r03.qmd --to pdf
	python3 scripts/check_pages.py _output/r03.pdf $(R03_LIMIT) || true
	quarto render mechanisms/r03.qmd --to docx

clean:
	rm -rf _output .quarto
