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

module exp_1x1_conv(
	clk_i,
	rst_n_i,
	start_i,

	layer_data_i,

	kernal_1_data_i,
	kernal_2_data_i,
	kernal_3_data_i,
	kernal_4_data_i,

	data_flag_i,

	fifo_exp_1x1_rd_data_o,
	fifo_exp_1x1_data_count_o,
	fifo_exp_1x1_rd_en_i,
	fifo_exp_1x1_empty_o
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

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;
	input 															start_i;

	// Convolution Control Signals
	input 					[7:0]									layer_data_i;

	input 					[7:0]									kernal_1_data_i;
	input 					[7:0]									kernal_2_data_i;
	input 					[7:0]									kernal_3_data_i;
	input 					[7:0]									kernal_4_data_i;

	input 															data_flag_i;

	// FIFO Expand 1x1 COntrol Signals
	output 					[47:0] 									fifo_exp_1x1_rd_data_o;
	output 					[7:0] 									fifo_exp_1x1_data_count_o;
	input 															fifo_exp_1x1_rd_en_i;
	output 															fifo_exp_1x1_empty_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Mult Control Signals
	wire 					[11:0] 									w_mult_1;
	wire 					[11:0] 									w_mult_2;
	wire 					[11:0] 									w_mult_3;
	wire 					[11:0] 									w_mult_4; 

	// Mult and Add flag
	reg 					[1:0]									r_mult_flag_temp;
	reg 															r_mult_flag;

	// Expand 1x1 FIFO COntrol Signals
	wire 					[47:0] 									w_exp_fifo_din;
	wire 															w_exp_fifo_wr_en;	

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Mult Flag
	always @(posedge clk_i) begin : MULT_FLAG // pipeline 3
		if(~rst_n_i || start_i) begin
			r_mult_flag_temp 		<= 0;
			r_mult_flag 			<= 0;
		end else begin
			r_mult_flag_temp[0:0] 	<= data_flag_i;
			r_mult_flag_temp[1:1] 	<= r_mult_flag_temp[0:0];
			r_mult_flag 			<= r_mult_flag_temp[1:1];
		end
	end

	// EXP 1x1 FIFO Wr data
	assign w_exp_fifo_din[47:36] = w_mult_1;
	assign w_exp_fifo_din[35:24] = w_mult_2;
	assign w_exp_fifo_din[23:12] = w_mult_3;
	assign w_exp_fifo_din[11:00] = w_mult_4;

	// // EXP 1x1 FIFO Write enable
	assign w_exp_fifo_wr_en = r_mult_flag;
		
	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------
	
	// Multiplication Instant
	mult_12 flaot_mult_1_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			({layer_data_i,4'b0000}),
		.data_2_i 			({kernal_1_data_i,4'b0000}),
		.data_mult_o 		(w_mult_1)
	);
	mult_12 flaot_mult_2_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			({layer_data_i,4'b0000}),
		.data_2_i 			({kernal_2_data_i,4'b0000}),
		.data_mult_o 		(w_mult_2)
	);
	mult_12 flaot_mult_3_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			({layer_data_i,4'b0000}),
		.data_2_i 			({kernal_3_data_i,4'b0000}),
		.data_mult_o 		(w_mult_3)
	);
	mult_12 flaot_mult_4_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			({layer_data_i,4'b0000}),
		.data_2_i 			({kernal_4_data_i,4'b0000}),
		.data_mult_o 		(w_mult_4)
	);

	
	// Expand Convolution Output FIFO
	expand_conv_fifo expand_1x1_fifo_inst
	(
		.clock 				(clk_i),
		.aclr 				(start_i),

		.data 				(w_exp_fifo_din),
		.wrreq 				(w_exp_fifo_wr_en),
		.usedw 				(fifo_exp_1x1_data_count_o),

		.q 					(fifo_exp_1x1_rd_data_o),
		.rdreq 				(fifo_exp_1x1_rd_en_i),
		.empty 				(fifo_exp_1x1_empty_o)
	);

endmodule

