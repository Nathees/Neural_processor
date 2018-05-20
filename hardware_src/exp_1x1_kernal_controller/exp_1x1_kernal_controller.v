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

module exp_1x1_kernal_controller(
	clk_i,
	rst_n_i,

	fifo_exp_1x1_clr_i,
	fifo_exp_1x1_wr_data_i,
	fifo_exp_1x1_wr_en_i,
	fifo_exp_1x1_data_count_o,

	exp_1x1_kerl_req_i,
	exp_1x1_kerl_ready_o,
	exp_1x1_kerl_data_o,

	start_i,
	exp_1x1_en_i,
	tot_exp1_ker_addr_limit_i,
	one_exp1_ker_addr_limit_i,
	exp1_ker_depth_i,
	layer_dimension_i
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
	Configurations

	tot_exp1_ker_addr_limit_i :- [(NO of expand kernals * depth) / 4 ] - 1
	one_exp1_ker_addr_limit_i :- [NO of expand kernals / 4]
	exp1_ker_depth_i 	  		:- [depth - 1]
	layer_dimension_i 			:- [dimnision -1]

	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i; 

	// EXPAND 1X1 Kernal FIFO control Signals
	input 															fifo_exp_1x1_clr_i;
	input 					[63:0]									fifo_exp_1x1_wr_data_i;
	input 															fifo_exp_1x1_wr_en_i;
	output 					[7:0] 									fifo_exp_1x1_data_count_o;	

	// EXPAND 1X1 Kernal RAM Control Signals
	input 															exp_1x1_kerl_req_i;
	output 			 												exp_1x1_kerl_ready_o;
	output 					[31:0] 									exp_1x1_kerl_data_o;

	// COnfiguration Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 					[11:0] 									tot_exp1_ker_addr_limit_i;
	input 					[6:0] 									one_exp1_ker_addr_limit_i;	
	input 					[5:0] 									exp1_ker_depth_i;
	input 					[6:0] 									layer_dimension_i;			

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------	

	// EXPAND 1X1 Kernal RAM Write Control Signals
	wire 					[31:0] 									w_exp_1x1_ram_wr_data;
	wire 		 			[11:0] 									w_exp_1x1_ram_wr_addr;
	wire 		 				 									w_exp_1x1_ram_wr_en;
	// EXPAND 1X1 Kernal RAM Read Control Signals	
	wire 		 			[11:0] 									w_exp_1x1_ram_rd_addr;

	// EXPAND 1X1 Kernal RAM Control Signals
	wire 		 			[6:0] 									w_exp_1x1_layer_ready_no;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------


//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// EXPAND 1X1 Kernal Write Controller instantiation
	exp_1x1_ker_write_cont exp_1x1_ker_write_cont_inst
	(
		.clk_i 										(clk_i),
		.rst_n_i 									(rst_n_i),

		.fifo_exp_1x1_clr_i 							(fifo_exp_1x1_clr_i),
		.fifo_exp_1x1_wr_data_i 					(fifo_exp_1x1_wr_data_i),
		.fifo_exp_1x1_wr_en_i 						(fifo_exp_1x1_wr_en_i),
		.fifo_exp_1x1_data_count_o 					(fifo_exp_1x1_data_count_o),

		.exp_1x1_ram_wr_data_o 						(w_exp_1x1_ram_wr_data),
		.exp_1x1_ram_wr_addr_o 						(w_exp_1x1_ram_wr_addr),
		.exp_1x1_ram_wr_en_o 						(w_exp_1x1_ram_wr_en),

		.start_i 									(start_i),
		.exp_1x1_en_i 								(exp_1x1_en_i),
		.tot_exp1_ker_addr_limit_i 					(tot_exp1_ker_addr_limit_i),
		.one_exp1_ker_addr_limit_i 					(one_exp1_ker_addr_limit_i),

		.exp_1x1_layer_ready_no_o 					(w_exp_1x1_layer_ready_no)
	);


	// EXPAND 1X1 Kernal Read Controller instantiation
	exp_1x1_ker_read_cont exp_1x1_ker_read_cont_inst
	(
		.clk_i 										(clk_i),
		.rst_n_i 									(rst_n_i),

		.exp_1x1_ram_rd_addr_o 						(w_exp_1x1_ram_rd_addr),

		.exp_1x1_kerl_req_i 						(exp_1x1_kerl_req_i),
		.exp_1x1_kerl_ready_o 						(exp_1x1_kerl_ready_o),

		.start_i 									(start_i),		
		.exp_1x1_en_i 								(exp_1x1_en_i),
		.one_exp1_ker_addr_limit_i 					(one_exp1_ker_addr_limit_i),
		.exp1_ker_depth_i 							(exp1_ker_depth_i),
		.layer_dimension_i 							(layer_dimension_i),

		.exp_1x1_layer_ready_no_i 					(w_exp_1x1_layer_ready_no)
	);

	// EXPAND 1x1 Kenal RAM instantiation
	exp_1x1_kernal_ram exp_1x1_kernal_ram_inst
	(
		.clock 									(clk_i),

		.data 									(w_exp_1x1_ram_wr_data),
		.wraddress 								(w_exp_1x1_ram_wr_addr),
		.wren 									(w_exp_1x1_ram_wr_en),

		.rdaddress 								(w_exp_1x1_ram_rd_addr),
		.q 										(exp_1x1_kerl_data_o)
	);


endmodule

