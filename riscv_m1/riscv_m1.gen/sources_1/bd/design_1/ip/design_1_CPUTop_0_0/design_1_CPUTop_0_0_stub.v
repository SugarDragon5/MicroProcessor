// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Sun Nov 19 20:00:16 2023
// Host        : DJ00001 running 64-bit Ubuntu 20.04.6 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/denjo/b3exp/riscv_m1/riscv_m1.gen/sources_1/bd/design_1/ip/design_1_CPUTop_0_0/design_1_CPUTop_0_0_stub.v
// Design      : design_1_CPUTop_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tsbg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "CPUTop,Vivado 2020.2" *)
module design_1_CPUTop_0_0(sysclk, nrst, uart_tx)
/* synthesis syn_black_box black_box_pad_pin="sysclk,nrst,uart_tx" */;
  input sysclk;
  input nrst;
  output uart_tx;
endmodule
