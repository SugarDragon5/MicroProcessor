#!/bin/sh

iverilog -g2009 ../../modules/define.v ../../modules/alu.v ../alu/test_alu.v -o alu.out
./alu.out