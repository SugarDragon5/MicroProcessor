//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
//Date        : Thu Nov 16 12:26:37 2023
//Host        : DJ00001 running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (cpu_resetn,
    sysclk,
    uart_rx_out);
  input cpu_resetn;
  input sysclk;
  output uart_rx_out;

  wire cpu_resetn;
  wire sysclk;
  wire uart_rx_out;

  design_1 design_1_i
       (.cpu_resetn(cpu_resetn),
        .sysclk(sysclk),
        .uart_rx_out(uart_rx_out));
endmodule
