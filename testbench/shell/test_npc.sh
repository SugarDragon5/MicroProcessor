#!/bin/sh

rm npc.out
iverilog -g2009 ../../modules/define.v ../../modules/pc.v ../pc/test_npc.v -o npc.out
./npc.out