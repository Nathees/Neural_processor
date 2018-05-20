//**************************************************************************************************
// Project/Product : IDCT
// Description     : Inverse Discrete Cosine Transform 
//                   row and column 1D IDCT operation 
//                   with 3 stage pipeline in each 1D IDCT
// Dependencies    : global_defs.v, global_func.v, synch_fifo.v
// References      : 
//
//**************************************************************************************************
   
`timescale 1ns / 1ps

module expand_2_max_top(
	clk_i,
	rst_n_i,

	start_i,
	max_en_i,
	one_exp_layer_addr_limit_i,
	exp_ker_depth_i,
	layer_dimension_i,
	no_of_exp_kernals_i,
	exp_123_addr_space_i,
	exp_12_addr_space_i,
	exp_1_addr_space_i,
	exp_tot_addr_space_i,
	max_tot_addr_space_i,

	fifo_exp_3x3_rd_data_i,
	fifo_exp_3x3_rd_en_o,
	fifo_exp_3x3_empty_i,

	fifo_exp_1x1_rd_data_i,
	fifo_exp_1x1_rd_en_o,
	fifo_exp_1x1_empty_i,

	fifo_squeeze_3x3_rd_data_o,
	fifo_squeeze_3x3_rd_en_i,
	fifo_squeeze_3x3_empty_o,

	fifo_squeeze_1x1_rd_data_o,
	fifo_squeeze_1x1_rd_en_i,
	fifo_squeeze_1x1_empty_o,

	fifo_exp_bash_clr_i,
	fifo_exp_bash_wr_data_i,
	fifo_exp_bash_wr_en_i,
	fifo_exp_bash_data_count_o
);


//----------------------------------------------------------------------------------------------------------------------
// Global constant and function headers
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// parameter definitions
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// localparam definitions
//----------------------------------------------------------------------------------------------------------------------
	/*

	Configurations :- 
	one_exp_layer_addr_limit_i 	:- [(dimension * expand kernals / 4)] - 1
	exp_ker_depth_i 	  		:- [depth - 1]
	layer_dimension_i 			:- [dimnision -1]

	no_of_exp_kernals_i 		:- [2 * NO of expand kernals / 8 - 1]

	exp_123_addr_space_i 		:- [expand kernal / 4 * 3] - 1 	
	exp_12_addr_space_i 		:- [expand kernal / 4 * 2]
	exp_1_addr_space_i 			:- [expand kernal / 4 * 1] - 1
	exp_tot_addr_space_i 		:- [expand layer dim * expand kernal / 4] - 2
	max_tot_addr_space_i 		:- [max layer dim * expand kernal / 4] - 2

	*/
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfig Control Signals
	input 															start_i;
	input 															max_en_i;
	input 				[10:0] 										one_exp_layer_addr_limit_i;
	input 				[5:0] 										exp_ker_depth_i;
	input 				[6:0] 										layer_dimension_i;
	input 				[5:0] 										no_of_exp_kernals_i;
	input 				[7:0] 										exp_123_addr_space_i;
	input 				[7:0] 										exp_12_addr_space_i;
	input 				[7:0] 										exp_1_addr_space_i;
	input 				[10:0] 										exp_tot_addr_space_i;
	input 				[9:0] 										max_tot_addr_space_i;

	// FIFO Expand 3x3 COntrol Signals
	input 				[47:0] 										fifo_exp_3x3_rd_data_i;
	output 															fifo_exp_3x3_rd_en_o;
	input 															fifo_exp_3x3_empty_i;

	// FIFO Expand 1x1 COntrol Signals
	input 				[47:0] 										fifo_exp_1x1_rd_data_i;
	output 															fifo_exp_1x1_rd_en_o;
	input 															fifo_exp_1x1_empty_i;

	// Squeeze 3x3 FIFO Control Signals
	output 				[95:0] 										fifo_squeeze_3x3_rd_data_o;
	input 															fifo_squeeze_3x3_rd_en_i;
	output 															fifo_squeeze_3x3_empty_o;

	// Squeeze 1x1 FIFO Control Signals
	output 				[95:0] 										fifo_squeeze_1x1_rd_data_o;
	input 															fifo_squeeze_1x1_rd_en_i;
	output 															fifo_squeeze_1x1_empty_o;

	// Expand Bash FIFO COntrol Signals
	input 															fifo_exp_bash_clr_i;
	input 				[63:0] 										fifo_exp_bash_wr_data_i;
	input 															fifo_exp_bash_wr_en_i;
	output 				[6:0] 										fifo_exp_bash_data_count_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	wire 															w_expand_flag;
	// FIRE COnfig Control Signals
	wire 															w_max_en;
	wire 															w_layer_done_flag;
	wire 				[10:0] 										w_layer_end_addr;
	wire 															w_new_layer_flag;
	wire 															w_new_line_flag;
	wire 															w_first_layer_flag;
	wire 															w_last_layer_flag;
	wire 															w_fire_end_flag;
	wire 															w_bash_ram_ready;

	// MAX COntrol Signals
	wire 				[47:0]										w_expand_3x3_data;
	wire 				[47:0]										w_expand_1x1_data;
	wire 															w_expand_flag_out;

	wire 				[47:0] 										w_max_3x3_rd_data;
	wire 				[47:0] 										w_max_1x1_rd_data;
	wire 				[10:0] 										w_max_rd_addr;
	wire 		 													w_max_ready_flag;

	wire 															w_squeeze_fifo_busy;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Expand Flag
	assign w_expand_flag = (~fifo_exp_3x3_empty_i && ~w_squeeze_fifo_busy && w_bash_ram_ready);

	// Expand FIFO read enable
	assign fifo_exp_3x3_rd_en_o = w_expand_flag;
	assign fifo_exp_1x1_rd_en_o = w_expand_flag;

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------
	
	// FIRE Config Expand
	fire_config_expand fire_config_expand_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.max_en_i 							(max_en_i),
		.one_exp_layer_addr_limit_i 		(one_exp_layer_addr_limit_i),
		.exp_ker_depth_i 					(exp_ker_depth_i),
		.layer_dimension_i 					(layer_dimension_i),

		.max_en_o  							(w_max_en),
		.layer_done_flag_i  				(w_layer_done_flag),
		.expand_flag_i  					(w_expand_flag),
		.layer_end_addr_o  					(w_layer_end_addr),
		.new_layer_flag_o  					(w_new_layer_flag),
		.new_line_flag_o  					(w_new_line_flag),
		.first_layer_flag_o  				(w_first_layer_flag),
		.last_layer_flag_o  				(w_last_layer_flag),
		.fire_end_flag_o 					(w_fire_end_flag)
	);

	// Expand RAM Controller
	expand_ram_controller expand_ram_controller_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.max_en_i 							(w_max_en),
		.no_of_exp_kernals_i 				(no_of_exp_kernals_i),
		.layer_done_flag_o 					(w_layer_done_flag),
		.layer_end_addr_i 					(w_layer_end_addr),
		.new_layer_flag_i 					(w_new_layer_flag),
		.new_line_flag_i 					(w_new_line_flag),
		.first_layer_flag_i 				(w_first_layer_flag),
		.last_layer_flag_i 					(w_last_layer_flag),
		.fire_end_flag_i 					(w_fire_end_flag),
		.bash_ram_ready_o 					(w_bash_ram_ready),

		.expand_3x3_data_i 					(fifo_exp_3x3_rd_data_i),
		.expand_1x1_data_i 					(fifo_exp_1x1_rd_data_i),
		.expand_flag_i 						(w_expand_flag),

		.expand_3x3_data_o 					(w_expand_3x3_data),
		.expand_1x1_data_o 					(w_expand_1x1_data),
		.expand_flag_o 						(w_expand_flag_out),

		.max_3x3_rd_data_o 					(w_max_3x3_rd_data),
		.max_1x1_rd_data_o 					(w_max_1x1_rd_data),
		.max_rd_addr_i 						(w_max_rd_addr),
		.max_ready_flag_o 					(w_max_ready_flag),

		.fifo_exp_bash_clr_i 				(fifo_exp_bash_clr_i),
		.fifo_exp_bash_wr_data_i 			(fifo_exp_bash_wr_data_i),
		.fifo_exp_bash_wr_en_i 				(fifo_exp_bash_wr_en_i),
		.fifo_exp_bash_data_count_o 		(fifo_exp_bash_data_count_o)
	); 	

	// MAX Ram Controller
	max_ram_controller max_ram_controller_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.max_en_i 							(max_en_i),
		.exp_123_addr_space_i 				(exp_123_addr_space_i),
		.exp_12_addr_space_i 				(exp_12_addr_space_i),
		.exp_1_addr_space_i 				(exp_1_addr_space_i),
		.exp_tot_addr_space_i 				(exp_tot_addr_space_i),
		.max_tot_addr_space_i 				(max_tot_addr_space_i),

		.expand_3x3_data_i 					(w_expand_3x3_data),
		.expand_1x1_data_i 					(w_expand_1x1_data),
		.expand_flag_i 						(w_expand_flag_out),

		.max_3x3_rd_data_i 					(w_max_3x3_rd_data),
		.max_1x1_rd_data_i 					(w_max_1x1_rd_data),
		.max_rd_addr_o 						(w_max_rd_addr),
		.max_ready_flag_i 					(w_max_ready_flag),
	
		.exp_lst_layer_flag_i 				(w_last_layer_flag),
		.squeeze_fifo_busy_o 				(w_squeeze_fifo_busy),

		.fifo_squeeze_3x3_rd_data_o 		(fifo_squeeze_3x3_rd_data_o),
		.fifo_squeeze_3x3_rd_en_i 			(fifo_squeeze_3x3_rd_en_i),
		.fifo_squeeze_3x3_empty_o 			(fifo_squeeze_3x3_empty_o),

		.fifo_squeeze_1x1_rd_data_o 		(fifo_squeeze_1x1_rd_data_o),
		.fifo_squeeze_1x1_rd_en_i 			(fifo_squeeze_1x1_rd_en_i),
		.fifo_squeeze_1x1_empty_o 			(fifo_squeeze_1x1_empty_o)
	);

endmodule

