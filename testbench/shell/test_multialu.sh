#!/bin/sh

# `chmod 755 test_alu.sh` to make this file executable

rm multialu.out
iverilog -g2009 ../../modules/define.v ../../modules/multiclockalu.v ../multialu/test_multialu.v -o multialu.out
./multialu.out