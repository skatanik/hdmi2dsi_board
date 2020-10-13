set module_name dsi_host_top
set tb_module_name tb_${module_name}

set include_dir {+incdir+./../../rtl/+incdir+./../../rtl/i2c_ip/+incdir+./../../rtl/uart_ip+incdir+./../../rtl/mipi_dsi+incdir+./../../rtl/misc_modules+incdir+./../../rtl/processor_core}
set defines {+define+XILINX+}

# if {[file isdirectory work]} {vdel work -all }

vlib work

set window_path_string $::env(PATH)
set modelsim_path $::env(MODELSIM)

set xilinx_lib_path

vmap

vlog -sv -incr -work work $defines $include_dir /path_to_top_tb_file.v

do ./compile_sources.tcl

puts "Start simulation"
vsim -voptargs=+acc -wlfopt -L work\
-L secureip 0L unisims_ver -L unimacro_ver -L unifast_ver\
$tb_module_name

log -r /*
run all
quit -f


# show waves
vsim -view -vsim.wlf -do ./addsignals.tcl &

