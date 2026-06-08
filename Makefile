LIBDIR := lib
include $(LIBDIR)/main.mk

## Keep the intermediate .xml build product only when explicitly requested
## via 'make xml'. main.mk marks the .xml as .INTERMEDIATE (auto-deleted after
## build); .SECONDARY overrides that, but only when 'xml' is a goal.
.PHONY: xml
xml: $(addsuffix .xml,$(drafts))
ifneq (,$(filter xml,$(MAKECMDGOALS)))
.SECONDARY: $(addsuffix .xml,$(drafts))
endif

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update --init
else
ifneq (,$(wildcard $(ID_TEMPLATE_HOME)))
	ln -s "$(ID_TEMPLATE_HOME)" $(LIBDIR)
else
	git clone -q --depth 10 -b main \
	    https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
endif
