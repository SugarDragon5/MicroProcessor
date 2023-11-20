-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
-- Date        : Mon Nov 20 22:56:09 2023
-- Host        : DJ00001 running 64-bit Ubuntu 20.04.6 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/denjo/b3exp/riscv_predict2/riscv_predict2.gen/sources_1/bd/design_1/ip/design_1_CPUTop_0_0/design_1_CPUTop_0_0_stub.vhdl
-- Design      : design_1_CPUTop_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a200tsbg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity design_1_CPUTop_0_0 is
  Port ( 
    sysclk : in STD_LOGIC;
    nrst : in STD_LOGIC;
    uart_tx : out STD_LOGIC
  );

end design_1_CPUTop_0_0;

architecture stub of design_1_CPUTop_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "sysclk,nrst,uart_tx";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "CPUTop,Vivado 2020.2";
begin
end;
