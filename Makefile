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
	sed -i 's/#include "ebpf_kernel.h"/#include "ebpf_kernel.h"\n#define set_tc_priority(prio) (skb->tc_classid = (prio))/' $(C_SRC)

$(OBJ): $(C_SRC)
	clang $(CLANG_FLAGS) $(C_SRC) -o $(OBJ)

simplifier: simplifier.c
	clang simplifier.c -o simplifier

# Target load wymaga root'a
.PHONY: clear-tc load check_root clean

check_root:
	@if ! [ "$(shell id -u)" = 0 ]; then \
		echo "You are not root, run this target as root please"; \
		exit 1; \
    fi

clear-tc: check_root
# Czyszczenie starych filtrów
	tc qdisc del dev $(INTERFACE) root 2> /dev/null || true
	tc qdisc del dev $(INTERFACE) ingress 2> /dev/null || true

load: $(OBJ) check_root clear-tc
# Tworzenie qdisc (egress)
	tc qdisc add dev $(INTERFACE) root handle 1: htb default 30
# Dodawanie przykładowych klas
	tc class add dev $(INTERFACE) parent 1: classid 1:1 htb rate 100mbit
	tc class add dev $(INTERFACE) parent 1:1 classid 1:10 htb rate 50mbit
	tc class add dev $(INTERFACE) parent 1:1 classid 1:20 htb rate 30mbit
	tc class add dev $(INTERFACE) parent 1:1 classid 1:30 htb rate 10mbit
# Ładowanie filtra eBPF 
	tc filter add dev $(INTERFACE) parent 1: prio 1 bpf obj $(OBJ) section $(SECTION) da

clean:
	rm -f $(C_SRC) $(OBJ)
	rm -f simplifier