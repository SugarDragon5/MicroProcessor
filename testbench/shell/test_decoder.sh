#!/bin/sh

# `chmod 755 test_decoder.sh` to make this file executable

rm decoder.out
iverilog -g2009 ../../modules/define.v ../../modules/decoder.v ../decoder/test_decoder.v -o decoder.out
./decoder.out