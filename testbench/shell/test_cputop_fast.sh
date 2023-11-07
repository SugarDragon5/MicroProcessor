#!/bin/sh

# `chmod 755 test_cputop_fast.sh` to make this file executable

verilator -cc ../../modules/CPUTop.v -exe ../cpu/test_cputop_fast.cpp -I../../modules
make -C obj_dir -f VCPUTop.mk
obj_dir/VCPUTop
