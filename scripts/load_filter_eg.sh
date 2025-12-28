#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ip netns exec server tc qdisc add dev eth0 clsact
ip netns exec server tc filter add dev eth0 egress bpf da obj $SCRIPT_DIR/../classifier.o sec tc