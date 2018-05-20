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

module exp_3x3_kernal_controller(
	clk_i,
	rst_n_i,

	fifo_exp_3x3_clr_i,
	fifo_exp_3x3_wr_data_i,
	fifo_exp_3x3_wr_en_i,
	fifo_exp_3x3_data_count_o,

	start_i,
	one_exp3_ker_addr_limit_i,
	exp3_ker_depth_i,
	layer_dimension_i,

	exp_3x3_kerl_req_i,
	exp_3x3_kerl_ready_o,
	exp_3x3_kerl_1_data_o,
	exp_3x3_kerl_2_data_o,
	exp_3x3_kerl_3_data_o,
	exp_3x3_kerl_4_data_o
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
		one_exp3_ker_addr_limit_i 	:- [NO of expand kernals / 4]
		exp3_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1]
	*/
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i; 

	// EXPAND 3x3 Kernal FIFO control Signals
	input 															fifo_exp_3x3_clr_i;
	input 					[63:0]									fifo_exp_3x3_wr_data_i;
	input 															fifo_exp_3x3_wr_en_i;
	output 					[7:0] 									fifo_exp_3x3_data_count_o;	

	// Configuration Control Signals
	input 															start_i;
	input 						[6:0] 								one_exp3_ker_addr_limit_i;
	input 						[5:0] 								exp3_ker_depth_i;
	input 						[6:0]								layer_dimension_i;

	// EXPAND 3x3 Kernal RAM Control Signals
	input 															exp_3x3_kerl_req_i;
	output 		 													exp_3x3_kerl_ready_o;	
	output 					[71:0] 									exp_3x3_kerl_1_data_o;
	output 					[71:0] 									exp_3x3_kerl_2_data_o;
	output 					[71:0] 									exp_3x3_kerl_3_data_o;					
	output 					[71:0] 									exp_3x3_kerl_4_data_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------	

	// EXPAND 3X3 Kernal RAM Write Control Signals
	wire 					[71:0] 									w_exp_3x3_ram_wr_data;
	wire 		 			[6:0] 									w_exp_3x3_ram_wr_addr;
	wire 		 													w_exp_3x3_ram_1_wr_en;
	wire 		 													w_exp_3x3_ram_2_wr_en;
	wire 		 													w_exp_3x3_ram_3_wr_en;
	wire 		 													w_exp_3x3_ram_4_wr_en;

	wire 		 			[6:0] 									w_exp_3x3_ram_rd_addr;

	// EXPAND 3x3 RAM Layer Status COntrol Signal
	wire 		 													w_layer_1_ready;
	wire 															w_layer_1_done;
	wire 		 													w_layer_2_ready;
	wire 															w_layer_2_done;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// EXPAND 3x3 Kernal Write Controller instantiation
	exp_3x3_ker_write_cont exp_3x3_ker_write_cont_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.fifo_exp_3x3_clr_i 					(fifo_exp_3x3_clr_i),
		.fifo_exp_3x3_wr_data_i 				(fifo_exp_3x3_wr_data_i),
		.fifo_exp_3x3_wr_en_i 					(fifo_exp_3x3_wr_en_i),
		.fifo_exp_3x3_data_count_o 				(fifo_exp_3x3_data_count_o),

		.exp_3x3_ram_wr_data_o 					(w_exp_3x3_ram_wr_data),
		.exp_3x3_ram_wr_addr_o 					(w_exp_3x3_ram_wr_addr),
		.exp_3x3_ram_1_wr_en_o 					(w_exp_3x3_ram_1_wr_en),
		.exp_3x3_ram_2_wr_en_o 					(w_exp_3x3_ram_2_wr_en),
		.exp_3x3_ram_3_wr_en_o 					(w_exp_3x3_ram_3_wr_en),
		.exp_3x3_ram_4_wr_en_o 					(w_exp_3x3_ram_4_wr_en),

		.start_i 								(start_i),
		.one_exp3_ker_addr_limit_i 				(one_exp3_ker_addr_limit_i),
		.exp3_ker_depth_i 						(exp3_ker_depth_i),
		.layer_dimension_i 						(layer_dimension_i),

		.layer_1_ready_o 						(w_layer_1_ready),
		.layer_1_done_i 						(w_layer_1_done),
		.layer_2_ready_o 						(w_layer_2_ready),
		.layer_2_done_i 						(w_layer_2_done)
	);

	// EXPAND 3X3 Kernal Read Controller instantiation
	exp_3x3_ker_read_cont exp_3x3_ker_read_cont_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.exp_3x3_ram_rd_addr_o 					(w_exp_3x3_ram_rd_addr),

		.exp_3x3_kerl_req_i 					(exp_3x3_kerl_req_i),
		.exp_3x3_kerl_ready_o 					(exp_3x3_kerl_ready_o),

		.start_i 								(start_i),
		.one_exp3_ker_addr_limit_i 				(one_exp3_ker_addr_limit_i),
		.exp3_ker_depth_i 						(exp3_ker_depth_i),
		.layer_dimension_i 						(layer_dimension_i),

		.layer_1_ready_i 						(w_layer_1_ready),
		.layer_1_done_o 						(w_layer_1_done),
		.layer_2_ready_i 						(w_layer_2_ready),
		.layer_2_done_o 						(w_layer_2_done)
	);

	// EXPAND 3X3 Kenal RAM 1 instantiation
	exp_3x3_kernal_ram exp_3x3_kernal_ram_1_inst
	(
		.clock 									(clk_i),

		.data 									(w_exp_3x3_ram_wr_data),
		.wraddress 								(w_exp_3x3_ram_wr_addr),
		.wren 									(w_exp_3x3_ram_1_wr_en),

		.rdaddress 								(w_exp_3x3_ram_rd_addr),
		.q 										(exp_3x3_kerl_1_data_o)
	);

	// EXPAND 3X3 Kenal RAM 2 instantiation
	exp_3x3_kernal_ram exp_3x3_kernal_ram_2_inst
	(
		.clock 									(clk_i),

		.data 									(w_exp_3x3_ram_wr_data),
		.wraddress 								(w_exp_3x3_ram_wr_addr),
		.wren 									(w_exp_3x3_ram_2_wr_en),

		.rdaddress 								(w_exp_3x3_ram_rd_addr),
		.q 										(exp_3x3_kerl_2_data_o)
	);

	// EXPAND 3X3 Kenal RAM 3 instantiation
	exp_3x3_kernal_ram exp_3x3_kernal_ram_3_inst
	(
		.clock 									(clk_i),

		.data 									(w_exp_3x3_ram_wr_data),
		.wraddress 								(w_exp_3x3_ram_wr_addr),
		.wren 									(w_exp_3x3_ram_3_wr_en),

		.rdaddress 								(w_exp_3x3_ram_rd_addr),
		.q 										(exp_3x3_kerl_3_data_o)
	);

	// EXPAND 3X3 Kenal RAM 4 instantiation
	exp_3x3_kernal_ram exp_3x3_kernal_ram_4_inst
	(
		.clock 									(clk_i),

		.data 									(w_exp_3x3_ram_wr_data),
		.wraddress 								(w_exp_3x3_ram_wr_addr),
		.wren 									(w_exp_3x3_ram_4_wr_en),

		.rdaddress 								(w_exp_3x3_ram_rd_addr),
		.q 										(exp_3x3_kerl_4_data_o)
	);

endmodule

