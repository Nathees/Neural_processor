if [file exists work] {vdel -all}
vlib work
vlog -y "D:/Innovate_GIT/Neural_processor/hardware_src" squeezenet_top_sim.sv 
vsim -novopt -L sim_lib/altera_mf_ver -L sim_lib/lpm_ver squeezenet_top_sim 
do wave.do
run -all