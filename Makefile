all: gvs2gv ctp.png

ctp.png: ctp.gv
	dot -Tpng -o ctp.png ctp.gv

ctp.gv: ctp.gvs
	./gvs2gv ctp.gvs

gvs2gv:
	chicken-install -n

install:
	chicken-install

.PHONY: all install
