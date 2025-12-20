#!/usr/bin/env bash

tc qdisc del dev $1 root 2>/dev/null || true
tc qdisc del dev $1 clsact 2>/dev/null || true
tc filter del dev $1

tc qdisc add dev $1 clsact

tc qdisc add dev $1 root handle 1: htb default 30
tc class add dev $1 parent 1: classid 1:1 htb rate 1000kbit
tc class add dev $1 parent 1:1 classid 1:10 htb rate 500kbit ceil 500kbit
tc class add dev $1 parent 1:1 classid 1:20 htb rate 250kbit ceil 250kbit
tc class add dev $1 parent 1:1 classid 1:30 htb rate 250kbit ceil 250kbit

# tc filter add dev $1 ingress bpf da obj classifier.o sec tc
tc filter add dev $1 egress bpf da obj classifier.o sec tc

tc filter add dev $1 parent 1: basic match 'meta(tc_index eq 0x10)' flowid 1:10
tc filter add dev $1 parent 1: basic match 'meta(tc_index eq 0x20)' flowid 1:20
tc filter add dev $1 parent 1: basic match 'meta(tc_index eq 0x30)' flowid 1:30

tc qdisc add dev $1 parent 1:10 handle 10: sfq perturb 10
tc qdisc add dev $1 parent 1:20 handle 20: sfq perturb 10
tc qdisc add dev $1 parent 1:30 handle 30: sfq perturb 10

# Dodawanie jakiejś ogólnej klasyfikacji po protokole L3
IFS=: read -r TBL_ID usless <<< "$(bpftool map show | grep 'hash  name pipe_tbl_protoc')"

# UDP do klasy 1:10, TCP do 1:20, reszta 1:30
bpftool map update id $TBL_ID key hex 11 00 00 00 value hex 01 00 00 00 10 00 00 00
bpftool map update id $TBL_ID key hex 06 00 00 00 value hex 01 00 00 00 20 00 00 00

bpftool map show
tc -s class show dev $1
tc -s qdisc show dev $1
tc -s filter show dev $1
tc -s filter show dev $1 ingress
bpftool map dump id $TBL_ID