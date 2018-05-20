# flush stdout
if [file exists work] {vdel -all}
vlib work
vlog -y "E:/questasim/Innovate_New/Integration/part_3"  squeezenet_top_sim.sv 
vsim -novopt -L E:/questasim/Innovate_FPGA_test/sim_lib/verilog_libs/altera_mf_ver squeezenet_top_sim 
do wave.do
run -all
###write transcript out.log
# quit -sim