#!/usr/bin/env bash

# TODO: More comprehensive tests
ip netns exec server iperf3 -s &
SERVER_PID=$!
ip netns exec client iperf3 -R --cport 1234 -c 10.0.0.1
kill $SERVER_PID