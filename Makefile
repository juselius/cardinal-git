
all: git-bottom.pdf

%.pdf: %.md
	pandoc -o $@ $^
