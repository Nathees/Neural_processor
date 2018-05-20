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

module squeezenet_top(
	clk_i,
	rst_n_i,

	start_i,
	exp_1x1_en_i,
	max_en_i,
	squ_repeat_en_i,
	avg_en_i,
	one_exp_ker_addr_limit_i,
	exp_ker_depth_i,
	layer_dimension_i,
	tot_exp1_ker_addr_limit_i,
	one_exp_layer_addr_limit_i,
	no_of_exp_kernals_i,
	exp_123_addr_space_i,
	exp_12_addr_space_i,
	exp_1_addr_space_i,
	exp_tot_addr_space_i,
	max_tot_addr_space_i,
	tot_squ_ker_addr_limit_i,
	one_squ_ker_addr_limit_i,
	tot_repeat_squ_kernals_i,
	squ_kernals_63_i,
	tot_squ_addr_limit_i,
	no_of_squ_kernals_i,
	squ_3x3_ker_depth_i,
	squ_layer_dimension_i,

	layer_req_o,
	layer_ready_i,
	layer_data_i,

	fifo_exp_3x3_clr_i,
	fifo_exp_3x3_wr_data_i,
	fifo_exp_3x3_wr_en_i,
	fifo_exp_3x3_data_count_o,

	fifo_exp_1x1_clr_i,
	fifo_exp_1x1_wr_data_i,
	fifo_exp_1x1_wr_en_i,
	fifo_exp_1x1_data_count_o,

	fifo_exp_bash_clr_i,
	fifo_exp_bash_wr_data_i,
	fifo_exp_bash_wr_en_i,
	fifo_exp_bash_data_count_o,
	
	fifo_squeeze_clr_i,
	fifo_squeeze_wr_data_i,
	fifo_squeeze_wr_en_i,
	fifo_squeeze_data_count_o,

	fifo_squ_bash_clr_i,
	fifo_squ_bash_wr_data_i,
	fifo_squ_bash_wr_en_i,
	fifo_squ_bash_data_count_o,
	
	fifo_out_rd_data_o,
	fifo_out_rd_en_i,
	fifo_out_empty_o,
	fifo_out_data_count
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
		Configurations :- EXPAND 3X3 KERNAL CONTROLLER
		one_exp_ker_addr_limit_i 	:- [NO of expand kernals / 4]
		exp_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1]

		Configurations :- EXPAND 1X1 KERNAL CONTROLLER
		tot_exp1_ker_addr_limit_i 	:- [(NO of expand kernals * depth) / 4 ] - 1
		one_exp_ker_addr_limit_i 	:- [NO of expand kernals / 4]
		exp_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1]

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

		Configurations :- Squeeze KERNAL CONTROLLER
		tot_squ_ker_addr_limit_i 	:- [(NO of squeeze kernals * depth / 8 ] - 1
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
		squ_kernals_63_i 			:- [No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
		layer_dimension_i 			:- [dimension - 1]

		Configurations :- MAX 2 SQUEEZE
		tot_squ_addr_limit_i 		:- [(dimension * depth / 2) / 8] - 1
		no_of_squ_kernals_i 		:- [No of squeeze kernal - 1]
		squ_3x3_ker_depth_i 		:- [squeeze 3x3 depth]
		squ_layer_dimension_i 		:- [Squeeze layer dimension - 1] // After max pool
	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// Configuration Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 															max_en_i;
	input 															squ_repeat_en_i;
	input 															avg_en_i;
	input 					[6:0] 									one_exp_ker_addr_limit_i;
	input 					[5:0] 									exp_ker_depth_i;
	input 					[6:0]									layer_dimension_i;
	input 					[11:0] 									tot_exp1_ker_addr_limit_i;

	input 					[10:0] 									one_exp_layer_addr_limit_i;
	input 					[5:0] 									no_of_exp_kernals_i;
	input 					[7:0] 									exp_123_addr_space_i;
	input 					[7:0] 									exp_12_addr_space_i;
	input 					[7:0] 									exp_1_addr_space_i;
	input 					[10:0] 									exp_tot_addr_space_i;
	input 					[9:0] 									max_tot_addr_space_i;

	input 					[11:0] 									tot_squ_ker_addr_limit_i;
	input 					[5:0] 									one_squ_ker_addr_limit_i;
	input 					[15:0] 									tot_repeat_squ_kernals_i;
	input 					[5:0]									squ_kernals_63_i; 

	input 					[8:0] 									tot_squ_addr_limit_i;
	input 					[9:0]									no_of_squ_kernals_i;
	input 					[8:0]									squ_3x3_ker_depth_i;
	input 					[6:0]	 								squ_layer_dimension_i;

	// Layer Control Signals
	output 															layer_req_o;
	input 															layer_ready_i;
	input 					[71:0] 									layer_data_i;

	// EXPAND 3x3 Kernal FIFO control Signals
	input 															fifo_exp_3x3_clr_i;
	input 					[63:0]									fifo_exp_3x3_wr_data_i;
	input 															fifo_exp_3x3_wr_en_i;
	output 					[7:0] 									fifo_exp_3x3_data_count_o;

	// EXPAND 1X1 Kernal FIFO control Signals
	input 															fifo_exp_1x1_clr_i;
	input 					[63:0]									fifo_exp_1x1_wr_data_i;
	input 															fifo_exp_1x1_wr_en_i;
	output 					[7:0] 									fifo_exp_1x1_data_count_o;

	// Expand Bash FIFO COntrol Signals
	input 															fifo_exp_bash_clr_i;
	input 					[63:0] 									fifo_exp_bash_wr_data_i;
	input 															fifo_exp_bash_wr_en_i;
	output 					[6:0] 									fifo_exp_bash_data_count_o;

	// Squeeze Kernal FIFO control Signals
	input 															fifo_squeeze_clr_i;
	input 					[63:0]									fifo_squeeze_wr_data_i;
	input 															fifo_squeeze_wr_en_i;
	output 					[7:0] 									fifo_squeeze_data_count_o; 	

	// Squeeze Bash FIFO COntrol Signals
	input 															fifo_squ_bash_clr_i;
	input 					[63:0] 									fifo_squ_bash_wr_data_i;
	input 															fifo_squ_bash_wr_en_i;
	output 					[6:0] 									fifo_squ_bash_data_count_o;

	// Output FIFO Control Signals
	output 					[7:0] 									fifo_out_rd_data_o;
	input 															fifo_out_rd_en_i;
	output 															fifo_out_empty_o;
	output 				[9:0] 										fifo_out_data_count;
	
//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// EXPAND 3x3 Kernal RAM Control Signals
	wire  															w_exp_3x3_kerl_req;
	wire 		 													w_exp_3x3_kerl_ready;	
	wire 					[71:0] 									w_exp_3x3_kerl_1_data;
	wire 					[71:0] 									w_exp_3x3_kerl_2_data;
	wire 					[71:0] 									w_exp_3x3_kerl_3_data;					
	wire 					[71:0] 									w_exp_3x3_kerl_4_data;

	// EXPAND 1X1 Kernal RAM Control Signals
	wire  															w_exp_1x1_kerl_req;	
	wire 			 												w_exp_1x1_kerl_ready;
	wire 					[31:0] 									w_exp_1x1_kerl_data;

	// FIFO OUTPUT Expand 3x3 COntrol Signals
	wire  					[47:0] 									w_fifo_exp_3x3_rd_data;
	wire 															w_fifo_exp_3x3_rd_en;
	wire  															w_fifo_exp_3x3_empty;

	// FIFO OUTPUT Expand 1x1 COntrol Signals
	wire  					[47:0] 									w_fifo_exp_1x1_rd_data;
	wire 															w_fifo_exp_1x1_rd_en;
	wire  															w_fifo_exp_1x1_empty;

	// Squeeze Kernal RAM Control Signals
	wire 															w_squeeze_kerl_req;
	wire  	 	 													w_squeeze_kerl_ready;	
	wire  					[63:0] 									w_squeeze_kerl_3x3_data;
	wire  					[63:0] 									w_squeeze_kerl_1x1_data;

	// Squeeze 3x3 FIFO Control Signals
	wire  					[95:0] 									w_fifo_squeeze_3x3_rd_data;
	wire 															w_fifo_squeeze_3x3_rd_en;
	wire  															w_fifo_squeeze_3x3_empty;

	// Squeeze 1x1 FIFO Control Signals
	wire  					[95:0] 									w_fifo_squeeze_1x1_rd_data;
	wire 															w_fifo_squeeze_1x1_rd_en;
	wire  															w_fifo_squeeze_1x1_empty;


//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------
	
	// Expand Convolution
	expand_convolution expand_convolution_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.one_exp_ker_addr_limit_i 				(one_exp_ker_addr_limit_i),

		.layer_req_o 							(layer_req_o),
		.layer_ready_i 							(layer_ready_i),
		.layer_data_i 							(layer_data_i),

		.exp_3x3_kerl_req_o 					(w_exp_3x3_kerl_req),
		.exp_3x3_kerl_ready_i 					(w_exp_3x3_kerl_ready),
		.exp_3x3_kerl_1_data_i 					(w_exp_3x3_kerl_1_data),
		.exp_3x3_kerl_2_data_i 					(w_exp_3x3_kerl_2_data),
		.exp_3x3_kerl_3_data_i 					(w_exp_3x3_kerl_3_data),
		.exp_3x3_kerl_4_data_i 					(w_exp_3x3_kerl_4_data),
	
		.exp_1x1_kerl_req_o 					(w_exp_1x1_kerl_req),
		.exp_1x1_kerl_ready_i 					(w_exp_1x1_kerl_ready),
		.exp_1x1_kerl_data_i 					(w_exp_1x1_kerl_data),

		.fifo_exp_3x3_rd_data_o 				(w_fifo_exp_3x3_rd_data),
		.fifo_exp_3x3_rd_en_i 					(w_fifo_exp_3x3_rd_en),
		.fifo_exp_3x3_empty_o 					(w_fifo_exp_3x3_empty),

		.fifo_exp_1x1_rd_data_o 				(w_fifo_exp_1x1_rd_data),
 		.fifo_exp_1x1_rd_en_i 					(w_fifo_exp_1x1_rd_en),
 		.fifo_exp_1x1_empty_o 					(w_fifo_exp_1x1_empty)
	);

	// Expand 3x3 Kernal Controller
	exp_3x3_kernal_controller exp_3x3_kernal_controller_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.one_exp3_ker_addr_limit_i 				(one_exp_ker_addr_limit_i),
		.exp3_ker_depth_i 						(exp_ker_depth_i),
		.layer_dimension_i 						(layer_dimension_i),

		.fifo_exp_3x3_clr_i 					(fifo_exp_3x3_clr_i),
		.fifo_exp_3x3_wr_data_i 				(fifo_exp_3x3_wr_data_i),
		.fifo_exp_3x3_wr_en_i 					(fifo_exp_3x3_wr_en_i),
		.fifo_exp_3x3_data_count_o 				(fifo_exp_3x3_data_count_o),

		.exp_3x3_kerl_req_i 					(w_exp_3x3_kerl_req),
		.exp_3x3_kerl_ready_o 					(w_exp_3x3_kerl_ready),
		.exp_3x3_kerl_1_data_o 					(w_exp_3x3_kerl_1_data),
		.exp_3x3_kerl_2_data_o 					(w_exp_3x3_kerl_2_data),
		.exp_3x3_kerl_3_data_o 					(w_exp_3x3_kerl_3_data),
		.exp_3x3_kerl_4_data_o 					(w_exp_3x3_kerl_4_data)
	);
	
	// Expand 1x1 Kernal Controller
	exp_1x1_kernal_controller exp_1x1_kernal_controller_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.fifo_exp_1x1_clr_i 					(fifo_exp_1x1_clr_i),
		.fifo_exp_1x1_wr_data_i 				(fifo_exp_1x1_wr_data_i),
		.fifo_exp_1x1_wr_en_i 					(fifo_exp_1x1_wr_en_i),
		.fifo_exp_1x1_data_count_o 				(fifo_exp_1x1_data_count_o),

		.exp_1x1_kerl_req_i 					(w_exp_1x1_kerl_req),
		.exp_1x1_kerl_ready_o 					(w_exp_1x1_kerl_ready),
		.exp_1x1_kerl_data_o 					(w_exp_1x1_kerl_data),

		.start_i 								(start_i),
		.exp_1x1_en_i 							(exp_1x1_en_i),
		.tot_exp1_ker_addr_limit_i 				(tot_exp1_ker_addr_limit_i),
		.one_exp1_ker_addr_limit_i 				(one_exp_ker_addr_limit_i),
		.exp1_ker_depth_i 						(exp_ker_depth_i),
		.layer_dimension_i 						(layer_dimension_i)
	);

	// Expand 2 Max 
	expand_2_max_top expand_2_max_top_inst
	(
		.clk_i									(clk_i),
		.rst_n_i								(rst_n_i),

		.start_i								(start_i),
		.max_en_i								(max_en_i),
		.one_exp_layer_addr_limit_i				(one_exp_layer_addr_limit_i),
		.exp_ker_depth_i						(exp_ker_depth_i),
		.layer_dimension_i						(layer_dimension_i),
		.no_of_exp_kernals_i 					(no_of_exp_kernals_i),
		.exp_123_addr_space_i					(exp_123_addr_space_i),
		.exp_12_addr_space_i					(exp_12_addr_space_i),
		.exp_1_addr_space_i						(exp_1_addr_space_i),
		.exp_tot_addr_space_i					(exp_tot_addr_space_i),
		.max_tot_addr_space_i					(max_tot_addr_space_i),

		.fifo_exp_3x3_rd_data_i					(w_fifo_exp_3x3_rd_data),
		.fifo_exp_3x3_rd_en_o					(w_fifo_exp_3x3_rd_en),
		.fifo_exp_3x3_empty_i					(w_fifo_exp_3x3_empty),

		.fifo_exp_1x1_rd_data_i					(w_fifo_exp_1x1_rd_data),
		.fifo_exp_1x1_rd_en_o					(w_fifo_exp_1x1_rd_en),
		.fifo_exp_1x1_empty_i					(w_fifo_exp_1x1_empty),

		.fifo_squeeze_3x3_rd_data_o				(w_fifo_squeeze_3x3_rd_data),
		.fifo_squeeze_3x3_rd_en_i				(w_fifo_squeeze_3x3_rd_en),
		.fifo_squeeze_3x3_empty_o				(w_fifo_squeeze_3x3_empty),

		.fifo_squeeze_1x1_rd_data_o				(w_fifo_squeeze_1x1_rd_data),
		.fifo_squeeze_1x1_rd_en_i				(w_fifo_squeeze_1x1_rd_en),
		.fifo_squeeze_1x1_empty_o 				(w_fifo_squeeze_1x1_empty),

		.fifo_exp_bash_clr_i 					(fifo_exp_bash_clr_i),
		.fifo_exp_bash_wr_data_i 				(fifo_exp_bash_wr_data_i),
		.fifo_exp_bash_wr_en_i 					(fifo_exp_bash_wr_en_i),
		.fifo_exp_bash_data_count_o 			(fifo_exp_bash_data_count_o)
	);

	// Squeeze Kernal COntroller
	squeeze_kernal_controller squeeze_kernal_controller_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.repeat_en_i 							(squ_repeat_en_i),
		.tot_squ_ker_addr_limit_i 				(tot_squ_ker_addr_limit_i),
		.one_squ_ker_addr_limit_i 				(one_squ_ker_addr_limit_i),
		.tot_repeat_squ_kernals_i 				(tot_repeat_squ_kernals_i),
		.squ_kernals_i 							(squ_kernals_63_i),
		.layer_dimension_i 						(layer_dimension_i),

		.fifo_squeeze_clr_i 					(fifo_squeeze_clr_i),
		.fifo_squeeze_wr_data_i 				(fifo_squeeze_wr_data_i),
		.fifo_squeeze_wr_en_i 					(fifo_squeeze_wr_en_i),
		.fifo_squeeze_data_count_o 				(fifo_squeeze_data_count_o),

		.squeeze_kerl_req_i 					(w_squeeze_kerl_req),
		.squeeze_kerl_ready_o 					(w_squeeze_kerl_ready),
		.squeeze_kerl_3x3_data_o 				(w_squeeze_kerl_3x3_data),
		.squeeze_kerl_1x1_data_o 				(w_squeeze_kerl_1x1_data)
	);

	// MAX 2 Squeeze Controller
	max_2_squeeze_top max_2_squeeze_top_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.exp_1x1_en_i 							(exp_1x1_en_i),
		.tot_squ_addr_limit_i 					(tot_squ_addr_limit_i),
		.no_of_squ_kernals_i 					(no_of_squ_kernals_i),
		.squ_3x3_ker_depth_i 					(squ_3x3_ker_depth_i),
		.avg_en_i 								(avg_en_i),
		.squ_layer_dimension_i 					(squ_layer_dimension_i),

		.fifo_squ_3x3_rd_data_i 				(w_fifo_squeeze_3x3_rd_data),
		.fifo_squ_3x3_rd_en_o 					(w_fifo_squeeze_3x3_rd_en),
		.fifo_squ_3x3_empty_i 					(w_fifo_squeeze_3x3_empty),

		.fifo_squ_1x1_rd_data_i 				(w_fifo_squeeze_1x1_rd_data),
		.fifo_squ_1x1_rd_en_o 					(w_fifo_squeeze_1x1_rd_en),
		.fifo_squ_1x1_empty_i 					(w_fifo_squeeze_1x1_empty),

		.fifo_squ_bash_clr_i 					(fifo_squ_bash_clr_i),
		.fifo_squ_bash_wr_data_i 				(fifo_squ_bash_wr_data_i),
		.fifo_squ_bash_wr_en_i 					(fifo_squ_bash_wr_en_i),
		.fifo_squ_bash_data_count_o 			(fifo_squ_bash_data_count_o),

		.squ_ker_req_o 							(w_squeeze_kerl_req),
		.squ_ker_ready_i 						(w_squeeze_kerl_ready),
		.squ_3x3_ker_i 							(w_squeeze_kerl_3x3_data),
		.squ_1x1_ker_i 							(w_squeeze_kerl_1x1_data),

		.fifo_out_rd_data_o 					(fifo_out_rd_data_o),
		.fifo_out_rd_en_i 						(fifo_out_rd_en_i),
		.fifo_out_empty_o 						(fifo_out_empty_o),
		.fifo_out_data_count 					(fifo_out_data_count)
	);

endmodule

