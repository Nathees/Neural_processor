onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/clk_i
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/rst_n_i
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/start_i
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_3x3_kerl_req
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_3x3_kerl_ready
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_3x3_kerl_1_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_3x3_kerl_2_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_3x3_kerl_3_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_3x3_kerl_4_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_1x1_kerl_req
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_1x1_kerl_ready
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_exp_1x1_kerl_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_exp_3x3_rd_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_exp_3x3_rd_en
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_exp_3x3_empty
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_exp_1x1_rd_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_exp_1x1_rd_en
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_exp_1x1_empty
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_squeeze_kerl_req
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_squeeze_kerl_ready
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_squeeze_kerl_3x3_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_squeeze_kerl_1x1_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_squeeze_3x3_rd_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_squeeze_3x3_rd_en
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_squeeze_3x3_empty
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_squeeze_1x1_rd_data
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_squeeze_1x1_rd_en
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/w_fifo_squeeze_1x1_empty
add wave -noupdate -radix unsigned /squeezenet_top_sim/squeezenet_top_inst/fifo_out_rd_data_o
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/fifo_out_rd_en_i
add wave -noupdate /squeezenet_top_sim/r_squ_out
add wave -noupdate /squeezenet_top_sim/r_avg_out
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/max_2_squeeze_top_inst/squeeze_convolution_inst/output_data_o
add wave -noupdate /squeezenet_top_sim/squeezenet_top_inst/max_2_squeeze_top_inst/squeeze_convolution_inst/output_flag_o
add wave -noupdate -divider {New Divider}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3876424331 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 489
configure wave -valuecolwidth 166
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {3316848506 ps} {4143126394 ps}
