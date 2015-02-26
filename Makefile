
all: cardinal-git.pdf

%.pdf: %.md
	pandoc -o $@ $^
