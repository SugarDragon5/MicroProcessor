//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
//Date        : Wed Nov 22 11:33:39 2023
//Host        : DJ00001 running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=2,numReposBlks=2,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (cpu_resetn,
    sysclk,
    uart_rx_out);
  input cpu_resetn;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYSCLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYSCLK, CLK_DOMAIN design_1_sysclk, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.000" *) input sysclk;
  output uart_rx_out;

  wire CPUTop_0_uart_tx;
  wire clk_wiz_0_clk_out1;
  wire cpu_resetn_1;
  wire sysclk_1;

  assign cpu_resetn_1 = cpu_resetn;
  assign sysclk_1 = sysclk;
  assign uart_rx_out = CPUTop_0_uart_tx;
  design_1_CPUTop_0_2 CPUTop_0
       (.nrst(cpu_resetn_1),
        .sysclk(clk_wiz_0_clk_out1),
        .uart_tx(CPUTop_0_uart_tx));
  design_1_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(sysclk_1),
        .clk_out1(clk_wiz_0_clk_out1));
endmodule
