# Makefile

DRAFTNAME=draft-ssb-TEMPLATE-00

TMP_PATH=$(shell dirname `dirname \`pwd\``)
EXTERN_PATH=$(shell dirname $(TMP_PATH))/extern
XML2RFC_PATH=$(EXTERN_PATH)/xml2rfc-latest

%.txt : %.md
	kramdown-rfc2629 $<  > $*.xml
	export PYTHONPATH=$(XML2RFC_PATH); \
	$(XML2RFC_PATH)/xml2rfc/run.py --legacy --text --html $*.xml
	rm -rf $*.xml

all: $(DRAFTNAME).txt

clean:
	rm -rf *.xml *~

# eof
