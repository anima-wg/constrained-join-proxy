DRAFT:=draft-ietf-anima-constrained-join-proxy
VERSION:=$(shell ./getver ${DRAFT}.md )
EXAMPLES=

${DRAFT}-${VERSION}.txt: ${DRAFT}.txt
	cp ${DRAFT}.txt ${DRAFT}-${VERSION}.txt
	: git add ${DRAFT}-${VERSION}.txt ${DRAFT}.txt

%.xml: %.md
	kramdown-rfc2629 ${DRAFT}.md >${DRAFT}.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --v2v3 ${DRAFT}.xml
	mv ${DRAFT}.v2v3.xml ${DRAFT}.xml

%.txt: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --text -o $@ $?

%.html: %.xml
	unset DISPLAY; XML_LIBRARY=$(XML_LIBRARY):./src xml2rfc --html -o $@ $?

submit: ${DRAFT}.xml
	curl -s -F "user=mcr+ietf@sandelman.ca" ${REPLACES} -F "xml=@${DRAFT}.xml" https://datatracker.ietf.org/api/submission | jq

html:	${DRAFT}.html

version:
	echo Version: ${VERSION}

clean:
	-rm -f ${DRAFT}.xml

.PRECIOUS: ${DRAFT}.xml
