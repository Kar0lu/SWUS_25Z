#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

$SCRIPT_DIR/prep_netns.sh
$SCRIPT_DIR/load_filter_eg.sh

echo "Tests after loading filter, but before setting HTB"
$SCRIPT_DIR/test.sh
$SCRIPT_DIR/add_classes.sh
$SCRIPT_DIR/fill_table.sh

echo "Tests after loading filter and setting HTB"
$SCRIPT_DIR/test.sh
$SCRIPT_DIR/clear.sh


# Stare rzeczy, ale mogą się przydać jeszcześ

# bpftool map show
# tc -s class show dev $1
# tc -s qdisc show dev $1
# tc -s filter show dev $1
# tc -s filter show dev $1 ingress
# bpftool map dump id $TBL_ID