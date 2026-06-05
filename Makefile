<<<<<<< HEAD
SAGE = /root/Devel/sagelang/core/sage
SAGE_PATH = /root/Devel/sagelang/core/lib:./src
=======
SAGE = /usr/local/bin/sage
SAGE_PATH = /usr/local/share/sage/lib
>>>>>>> fb7e6460ee9f588d3e14736f1f9307625c6afc9b

all: sgvm sgvmc

sgvm: sgvm.sage src/sgvm_vm.sage src/sgvm_opcodes.sage src/sgvm_utils.sage
	SAGE_PATH=$(SAGE_PATH) $(SAGE) --compile sgvm.sage -o sgvm

sgvmc: sgvmc.sage src/sgvm_compiler.sage src/sgvm_opcodes.sage src/sgvm_utils.sage
	SAGE_PATH=$(SAGE_PATH) $(SAGE) --compile sgvmc.sage -o sgvmc

clean:
	rm -f sgvm sgvmc .tmp.svm

install: all
	install -m 755 sgvm /usr/local/bin/sgvm
	install -m 755 sgvmc /usr/local/bin/sgvmc

.PHONY: all clean install
