#!/bin/sh

# `chmod 755 test_cputop.sh` to make this file executable

rm "cpu.out"
echo "Compiling"
iverilog -g2009 ../../modules/testdata.v ../../modules/define.v ../../modules/hardware_counter.v ../../modules/uart.v ../../modules/alu.v ../../modules/decoder.v ../../modules/lsu.v ../../modules/opswitcher.v ../../modules/pc.v ../../modules/ram.v ../../modules/register.v ../../modules/rom.v  ../../modules/CPUTop.v ../cpu/test_cputop.v -o cpu.out
echo "Running"
./cpu.out