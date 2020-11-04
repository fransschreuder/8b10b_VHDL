set scriptdir [pwd]

vmap uvvm_util            ${scriptdir}/../UVVM/uvvm_util/sim/uvvm_util

vcom -work work -2008 ${scriptdir}/../src/dec_8b10b.vhd
vcom -work work -2008 ${scriptdir}/../src/enc_8b10b.vhd
vcom -work work -2008 ${scriptdir}/../tb/lookup_8b10b.vhd
vcom -work work -2008 ${scriptdir}/../tb/validate_8b10b_tb.vhd

vsim -voptargs="+acc" work.validate_8b10b_tb
add wave -group top sim:/validate_8b10b_tb/*
add wave -group DUTE sim:/validate_8b10b_tb/DUTE/*
add wave -group DUTD  sim:/validate_8b10b_tb/DUTD/*
run -all
