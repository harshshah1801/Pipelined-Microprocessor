transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/Sign_Extension_10.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/Sign_Extension_7.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/reg.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/reg_file.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/mux81.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/memory.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/Left_shift1.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/demux18.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/cpu.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/alu.vhdl}
vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/add.vhdl}

vcom -93 -work work {C:/Users/Ayush/Downloads/piroject_1/piroject/cpu.vhdl}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  cpu

add wave *
view structure
view signals
run -all
