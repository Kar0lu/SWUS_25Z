#!/usr/bin/env bash

ip netns exec server tc qdisc add dev eth0 root handle 1: htb default 10
ip netns exec server tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit
ip netns exec server tc class add dev eth0 parent 1:1 classid 1:10 htb rate 100mbit ceil 100mbit
ip netns exec server tc class add dev eth0 parent 1:1 classid 1:20 htb rate 250kbit ceil 250kbit

ip netns exec server tc filter add dev eth0 parent 1: basic match 'meta(tc_index eq 0x10)' flowid 1:10
ip netns exec server tc filter add dev eth0 parent 1: basic match 'meta(tc_index eq 0x20)' flowid 1:20

ip netns exec server tc qdisc add dev eth0 parent 1:10 handle 10: sfq perturb 10
ip netns exec server tc qdisc add dev eth0 parent 1:20 handle 20: sfq perturb 10