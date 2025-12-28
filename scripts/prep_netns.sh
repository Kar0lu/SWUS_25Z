#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $SCRIPT_DIR/../config.env

echo "Creating netns for client"
ip netns add client

echo "Creating netns for server"
ip netns add server

echo "Configuring interfaces"
ip -n client link add eth0 type veth peer name eth0 netns server

ip netns exec client ip link set lo up
ip netns exec server ip link set lo up

ip netns exec client ip addr add "$CLIENT_IP" dev eth0
ip netns exec server ip addr add "$SERVER_IP" dev eth0

ip netns exec client ip link set eth0 up
ip netns exec server ip link set eth0 up

ip netns exec client ip route add default dev eth0
ip netns exec server ip route add default dev eth0