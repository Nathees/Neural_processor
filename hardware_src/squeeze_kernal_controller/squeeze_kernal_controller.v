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

module squeeze_kernal_controller(
	clk_i,
	rst_n_i,

	start_i,
	repeat_en_i,
	tot_squ_ker_addr_limit_i,
	one_squ_ker_addr_limit_i,
	tot_repeat_squ_kernals_i,
	squ_kernals_i,
	layer_dimension_i,

	fifo_squeeze_clr_i,
	fifo_squeeze_wr_data_i,
	fifo_squeeze_wr_en_i,
	fifo_squeeze_data_count_o,

	squeeze_kerl_req_i,
	squeeze_kerl_ready_o,
	squeeze_kerl_3x3_data_o,
	squeeze_kerl_1x1_data_o
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
		tot_squ_ker_addr_limit_i 	:- [(NO of squeeze kernals * depth / 8 ] - 1
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
		squ_kernals_i 				:- [No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
		layer_dimension_i 			:- [dimension - 1]
	*/
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfiguration Control Signals
	input 															start_i;
	input 															repeat_en_i;
	input 					[11:0] 									tot_squ_ker_addr_limit_i;
	input 					[5:0] 									one_squ_ker_addr_limit_i;
	input 					[15:0] 									tot_repeat_squ_kernals_i;
	input 					[5:0]									squ_kernals_i;   ///***************** conv
	input 					[6:0]	 								layer_dimension_i;

	// Squeeze Kernal FIFO control Signals
	input 															fifo_squeeze_clr_i;
	input 					[63:0]									fifo_squeeze_wr_data_i;
	input 															fifo_squeeze_wr_en_i;
	output 					[7:0] 									fifo_squeeze_data_count_o; 	

	// Squeeze Kernal RAM Control Signals
	input 															squeeze_kerl_req_i;
	output 	 	 													squeeze_kerl_ready_o;	
	output 					[63:0] 									squeeze_kerl_3x3_data_o;
	output 					[63:0] 									squeeze_kerl_1x1_data_o;


//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze Kernal RAM Write Control Signals
	wire 					[63:0] 									w_squeeze_ram_wr_data;
	wire 					[10:0] 									w_squeeze_ram_1_wr_addr;
	wire 					[10:0] 									w_squeeze_ram_2_wr_addr;
	wire 						 									w_squeeze_ram_1_wr_en;
	wire 						 									w_squeeze_ram_2_wr_en;

	// Squeeze Kernal RAM Read Control Signals
	wire 		 			[10:0] 									w_squeeze_ram_rd_addr;															

	// Squeeze Kernal RAM Control Signals
	wire 		 			[6:0] 									w_squeeze_layer_ready_no;
	wire 															w_fire_rd_done_flag;
	wire 		 			[6:0] 									w_conv_layer_ready_no;
	wire 															w_conv_rd_done_lay_flag;
		

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze Kernal RAM Write COntroller Instantiation
	squeeze_ker_write_cont squeeze_ker_write_cont_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.repeat_en_i 							(repeat_en_i),
		.tot_squ_ker_addr_limit_i 				(tot_squ_ker_addr_limit_i),
		.one_squ_ker_addr_limit_i 				(one_squ_ker_addr_limit_i),
		.tot_repeat_squ_kernals_i 				(tot_repeat_squ_kernals_i),

		.fifo_squeeze_clr_i 					(fifo_squeeze_clr_i),
		.fifo_squeeze_wr_data_i 				(fifo_squeeze_wr_data_i),
		.fifo_squeeze_wr_en_i 					(fifo_squeeze_wr_en_i),
		.fifo_squeeze_data_count_o 				(fifo_squeeze_data_count_o),

		.squeeze_ram_wr_data_o 					(w_squeeze_ram_wr_data),
		.squeeze_ram_1_wr_addr_o 				(w_squeeze_ram_1_wr_addr),
		.squeeze_ram_2_wr_addr_o 				(w_squeeze_ram_2_wr_addr),
		.squeeze_ram_1_wr_en_o 					(w_squeeze_ram_1_wr_en),
		.squeeze_ram_2_wr_en_o 					(w_squeeze_ram_2_wr_en),

		.squeeze_layer_ready_no_o 				(w_squeeze_layer_ready_no),
		.conv_layer_ready_no_o 					(w_conv_layer_ready_no),
		.conv_rd_done_lay_flag_i 				(w_conv_rd_done_lay_flag)
	);
	

	// Squeeze Kernal RAM Read COntroller Instantiation
	squeeze_ker_read_cont squeeze_ker_read_cont_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.repeat_en_i 							(repeat_en_i),
		.one_squ_ker_addr_limit_i 				(one_squ_ker_addr_limit_i),
		.squ_kernals_i 							(squ_kernals_i),
		.layer_dimension_i 						(layer_dimension_i),
		.tot_repeat_squ_kernals_i 				(tot_repeat_squ_kernals_i),

		.squeeze_ram_rd_addr_o 					(w_squeeze_ram_rd_addr),

		.squeeze_kerl_req_i 					(squeeze_kerl_req_i),
		.squeeze_kerl_ready_o 					(squeeze_kerl_ready_o),

		.squeeze_layer_ready_no_i 				(w_squeeze_layer_ready_no),
		.conv_layer_ready_no_i 					(w_conv_layer_ready_no),
		.conv_rd_done_lay_flag_o 				(w_conv_rd_done_lay_flag)
	);

	// Squeeze Kernal RAM 3x3 instantiation
	squeeze_kernal_ram squeeze_kernal_ram_3x3_inst
	(
		.clock 									(clk_i),

		.data 									(w_squeeze_ram_wr_data),
		.wraddress 								(w_squeeze_ram_1_wr_addr),
		.wren 									(w_squeeze_ram_1_wr_en),

		.q 										(squeeze_kerl_3x3_data_o),
		.rdaddress 								(w_squeeze_ram_rd_addr)
	);

	// Squeeze Kernal RAM 1x1 instantiation
	squeeze_kernal_ram squeeze_kernal_ram_1x1_inst
	(
		.clock 									(clk_i),

		.data 									(w_squeeze_ram_wr_data),
		.wraddress 								(w_squeeze_ram_2_wr_addr),
		.wren 									(w_squeeze_ram_2_wr_en),

		.q 										(squeeze_kerl_1x1_data_o),
		.rdaddress 								(w_squeeze_ram_rd_addr)
	);

endmodule

