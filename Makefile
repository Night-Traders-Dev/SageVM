SAGE = /root/Devel/sagelang/core/sage
SAGE_PATH = /root/Devel/sagelang/core/lib

all: sgvm sgvmc

sgvm: sgvm.sage
	SAGE_PATH=$(SAGE_PATH) $(SAGE) --compile sgvm.sage -o sgvm

sgvmc: sgvmc.sage
	SAGE_PATH=$(SAGE_PATH) $(SAGE) --compile sgvmc.sage -o sgvmc

clean:
	rm -f sgvm sgvmc .tmp.svm

install: all
	install -m 755 sgvm /usr/local/bin/sgvm
	install -m 755 sgvmc /usr/local/bin/sgvmc

.PHONY: all clean install
