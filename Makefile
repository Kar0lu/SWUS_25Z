INTERFACE?=enp0s3
P4_SRC?=classifier.p4
C_SRC?=classifier.c
OBJ?=classifier.o
SECTION?=tc
USER:=$$(whoami)
CLANG_INCLUDE?="/home/$(USER)/p4c/backends/ebpf/runtime"
CLANG_FLAGS=-O2 -target bpf -g -c -I $(CLANG_INCLUDE)

.PHONY: all
all: $(OBJ) simplifier

$(C_SRC): $(P4_SRC)
	p4c-ebpf -o $(C_SRC) $(P4_SRC) --emit-externs
	sed -i 's/#include "ebpf_kernel.h"/#include "ebpf_kernel.h"\n#define set_tc_priority(maj,min) (skb->tc_classid = TC_H_MAKE((maj),(min)))/' $(C_SRC)

$(OBJ): $(C_SRC)
# 	clang $(CLANG_FLAGS) $(C_SRC) -o $(OBJ)
	clang -O2 -g -emit-llvm -I $(CLANG_INCLUDE) -c $(C_SRC) -o - | llc -march=bpf -filetype=obj -o $(OBJ)

simplifier: simplifier.c
	clang simplifier.c -o simplifier

.PHONY: clean

clean:
	rm -f $(C_SRC) $(OBJ)
	rm -f simplifier