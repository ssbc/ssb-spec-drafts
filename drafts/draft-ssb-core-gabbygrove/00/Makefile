# Makefile

DRAFTNAME=draft-ssb-core-gabbygrove-00

TMP_PATH=$(shell dirname `dirname \`pwd\``)
EXTERN_PATH=$(shell dirname $(TMP_PATH))/extern

%.txt : %.md
	kramdown-rfc2629 $<  > $*.xml
	xml2rfc --text --html $*.xml
	rm -rf $*.xml

all: $(DRAFTNAME).txt

clean:
	rm -rf *.xml *~

# eof
