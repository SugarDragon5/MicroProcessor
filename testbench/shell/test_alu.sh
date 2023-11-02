#!/bin/sh

# `chmod 755 test_alu.sh` to make this file executable

rm alu.out
iverilog -g2009 ../../modules/define.v ../../modules/alu.v ../alu/test_alu.v -o alu.out
./alu.out