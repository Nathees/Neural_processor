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

module max_2_squeeze_top(
	clk_i,
	rst_n_i,

	start_i,
	exp_1x1_en_i,
	tot_squ_addr_limit_i,
	no_of_squ_kernals_i,
	squ_3x3_ker_depth_i,
	avg_en_i,
	squ_layer_dimension_i,

	fifo_squ_3x3_rd_data_i,
	fifo_squ_3x3_rd_en_o,
	fifo_squ_3x3_empty_i,

	fifo_squ_1x1_rd_data_i,
	fifo_squ_1x1_rd_en_o,
	fifo_squ_1x1_empty_i,

	fifo_squ_bash_clr_i,
	fifo_squ_bash_wr_data_i,
	fifo_squ_bash_wr_en_i,
	fifo_squ_bash_data_count_o,

	squ_ker_req_o,
	squ_ker_ready_i,
	squ_3x3_ker_i,
	squ_1x1_ker_i,

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

	Configurations :- 
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

	// COnfig Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 				[8:0] 										tot_squ_addr_limit_i;
	input 				[9:0]										no_of_squ_kernals_i;
	input 				[8:0]										squ_3x3_ker_depth_i;
	input 															avg_en_i;
	input 				[6:0]	 									squ_layer_dimension_i;

	// SQUEEZE 3x3 FIFO Control Signals
	input 				[95:0]										fifo_squ_3x3_rd_data_i;
	output 															fifo_squ_3x3_rd_en_o;
	input 															fifo_squ_3x3_empty_i;

	// SQUEEZE 3x3 FIFO Control Signals
	input 				[95:0]										fifo_squ_1x1_rd_data_i;
	output 															fifo_squ_1x1_rd_en_o;
	input 															fifo_squ_1x1_empty_i;

	// Squeeze Bash FIFO COntrol Signals
	input 															fifo_squ_bash_clr_i;
	input 				[63:0] 										fifo_squ_bash_wr_data_i;
	input 															fifo_squ_bash_wr_en_i;
	output 				[6:0] 										fifo_squ_bash_data_count_o;

	// Squeeze Request Kernal control Signals
	output 															squ_ker_req_o;
	input 		 													squ_ker_ready_i;
	input 				[63:0] 										squ_3x3_ker_i;
	input 				[63:0] 										squ_1x1_ker_i;

	// Output FIFO Control Signals
	output 				[7:0] 										fifo_out_rd_data_o;
	input 															fifo_out_rd_en_i;
	output 															fifo_out_empty_o;
	output 				[9:0] 										fifo_out_data_count;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze Request data control Signals
	wire 															w_squ_data_req;
	wire 		 													w_squ_data_ready;
	wire 				[95:0] 										w_squ_3x3_data;
	wire 				[95:0] 										w_squ_1x1_data;

	// Output Data COntrol Signals
	wire 		  		[11:0]										w_output_data;
	wire 		 													w_output_flag;
	wire 		  													w_output_fifo_busy;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze RAM Controller
	squeeze_ram_controller squeeze_ram_controller_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.exp_1x1_en_i 							(exp_1x1_en_i),
		.tot_squ_addr_limit_i 					(tot_squ_addr_limit_i),
		.squ_kernals_i 							(no_of_squ_kernals_i),

		.fifo_squ_3x3_rd_data_i 				(fifo_squ_3x3_rd_data_i),
		.fifo_squ_3x3_rd_en_o 					(fifo_squ_3x3_rd_en_o),
		.fifo_squ_3x3_empty_i 					(fifo_squ_3x3_empty_i),

		.fifo_squ_1x1_rd_data_i 				(fifo_squ_1x1_rd_data_i),
		.fifo_squ_1x1_rd_en_o 					(fifo_squ_1x1_rd_en_o),
		.fifo_squ_1x1_empty_i 					(fifo_squ_1x1_empty_i),

		.squ_data_req_i 						(w_squ_data_req),
		.squ_data_ready_o 						(w_squ_data_ready),
		.squ_3x3_data_o 						(w_squ_3x3_data),
		.squ_1x1_data_o 						(w_squ_1x1_data)
	);

	// Squeeze Convolution
	squeeze_convolution squeeze_convolution_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.exp_1x1_en_i 							(exp_1x1_en_i),
		.squ_3x3_ker_depth_i 					(squ_3x3_ker_depth_i),
		.no_of_squ_kernals_i 					(no_of_squ_kernals_i),
		.squ_layer_dimension_i 					(squ_layer_dimension_i),

		.squ_data_req_o 						(w_squ_data_req),
		.squ_data_ready_i 						(w_squ_data_ready),
		.squ_3x3_data_i 						(w_squ_3x3_data),
		.squ_1x1_data_i 						(w_squ_1x1_data),

		.squ_ker_req_o 							(squ_ker_req_o),
		.squ_ker_ready_i 						(squ_ker_ready_i),
		.squ_3x3_ker_i 							(squ_3x3_ker_i),
		.squ_1x1_ker_i 							(squ_1x1_ker_i),

		.fifo_squ_bash_clr_i 					(fifo_squ_bash_clr_i),
		.fifo_squ_bash_wr_data_i 				(fifo_squ_bash_wr_data_i),
		.fifo_squ_bash_wr_en_i 					(fifo_squ_bash_wr_en_i),
		.fifo_squ_bash_data_count_o 			(fifo_squ_bash_data_count_o),

		.output_data_o 							(w_output_data),
		.output_flag_o 							(w_output_flag),
		.output_fifo_busy_i 					(w_output_fifo_busy)
	);

	// Average POOL
	average_pool average_pool_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.avg_en_i 								(avg_en_i),
		.layer_dim_i 							(squ_layer_dimension_i),
		.classes_i 								(no_of_squ_kernals_i),

		.output_data_i 							(w_output_data),
		.output_flag_i 							(w_output_flag),
		.output_fifo_busy_o 					(w_output_fifo_busy),

		.fifo_out_rd_data_o 					(fifo_out_rd_data_o),
		.fifo_out_rd_en_i 						(fifo_out_rd_en_i),
		.fifo_out_empty_o 						(fifo_out_empty_o),
		.fifo_out_data_count 					(fifo_out_data_count)
	);

endmodule

