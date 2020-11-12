#!/bin/sh
ghdl -a --std=08 -frelaxed-rules -P$(pwd)/../UVVM/ ../src/enc_8b10b.vhd
ghdl -a --std=08 -frelaxed-rules -P$(pwd)/../UVVM/ ../src/dec_8b10b.vhd
ghdl -a --std=08 -frelaxed-rules -P$(pwd)/../UVVM/ ../tb/lookup_8b10b.vhd
ghdl -a --std=08 -frelaxed-rules -P$(pwd)/../UVVM/ ../tb/validate_8b10b_tb.vhd
ghdl -e --std=08 -frelaxed-rules -P$(pwd)/../UVVM/ validate_8b10b_tb
ghdl -r --std=08 -frelaxed-rules -P$(pwd)/../UVVM/ validate_8b10b_tb --wave=validate_8b10b.ghw
gtkwave validate_8b10b.ghw 

