#!/usr/bin/env bash

IFS=: read -r TBL_ID usless <<< "$(bpftool map show | grep 'hash  name pipe_flow')"

# bpftool map update id $TBL_ID key hex $SRC_IP $DST_IP $PROTO $SRC_PORT $DST_PORT value hex 01 00 00 00 20 00 00 00
# 10.0.0.1      10.0.0.2        6               5201            1234        ALIGNMENT
# 01 00 00 0A   02 00 00 0A     06 00           51 14           D2 04       00 00

bpftool map update id $TBL_ID key hex 01 00 00 0A 02 00 00 0A 06 00 51 14 D2 04 00 00 value hex 01 00 00 00 20 00 00 00