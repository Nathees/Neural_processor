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

module exp_3x3_conv(
	clk_i,
	rst_n_i,
	start_i,

	layer_data_i,

	kernal_1_data_i,
	kernal_2_data_i,
	kernal_3_data_i,
	kernal_4_data_i,

	data_flag_i,

	fifo_exp_3x3_rd_data_o,
	fifo_exp_3x3_data_count_o,
	fifo_exp_3x3_rd_en_i,
	fifo_exp_3x3_empty_o
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
	input 					[71:0]									layer_data_i;

	input 					[71:0]									kernal_1_data_i;
	input 					[71:0]									kernal_2_data_i;
	input 					[71:0]									kernal_3_data_i;
	input 					[71:0]									kernal_4_data_i;

	input 															data_flag_i;

	// FIFO Expand 3x3 COntrol Signals
	output 					[47:0] 									fifo_exp_3x3_rd_data_o;
	output 					[7:0] 									fifo_exp_3x3_data_count_o;
	input 															fifo_exp_3x3_rd_en_i;
	output 															fifo_exp_3x3_empty_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Mult Control Signals
	wire 					[11:0] 									w_mult_1 			[0:8];
	wire 					[11:0] 									w_mult_2 			[0:8];
	wire 					[11:0] 									w_mult_3 			[0:8];
	wire 					[11:0] 									w_mult_4 			[0:8]; 	
	// Add Level 1 Control Signals								
	wire 					[11:0] 									w_add_1_1 			[0:3];
	wire 					[11:0] 									w_add_1_2 			[0:3];
	wire 					[11:0] 									w_add_1_3 			[0:3];
	wire 					[11:0] 									w_add_1_4 			[0:3];
	// Add Level 2 Control Signals								
	wire 					[11:0] 									w_add_2_1 			[0:1];
	wire 					[11:0] 									w_add_2_2 			[0:1];
	wire 					[11:0] 									w_add_2_3 			[0:1];
	wire 					[11:0] 									w_add_2_4 			[0:1]; 
	// Add Level 3 Control Signals								
	wire 					[11:0] 									w_add_3_1;
	wire 					[11:0] 									w_add_3_2;
	wire 					[11:0] 									w_add_3_3;
	wire 					[11:0] 									w_add_3_4; 
	// Add Level final Control Signals								
	wire 					[11:0] 									w_conv_1;
	wire 					[11:0] 									w_conv_2;
	wire 					[11:0] 									w_conv_3;
	wire 					[11:0] 									w_conv_4; 	

	// Mult and Add flag
	reg 					[1:0]									r_mult_flag_temp;
	reg 															r_mult_flag;
	reg 					[3:0]									r_add_1_flag_temp;
	reg 															r_add_1_flag;
	reg 					[3:0]									r_add_2_flag_temp;
	reg 															r_add_2_flag;
	reg 					[3:0]									r_add_3_flag_temp;
	reg 															r_add_3_flag;
	reg 					[3:0] 									r_conv_flag_temp;
	reg 															r_conv_flag;

	reg 					[11:0] 									r_conv_1_din2;
	reg 					[11:0] 									r_conv_2_din2;
	reg 					[11:0] 									r_conv_3_din2;
	reg 					[11:0] 									r_conv_4_din2;

	// Conv SUB fifo control Signals
	wire 															w_sub_fifo_wr_en;
	wire 					[47:0]  								w_sub_fifo_din;
	wire 															w_sub_fifo_rd_en;
	wire 					[47:0] 									w_sub_fifo_dout;	

	// Expand 3x3 FIFO COntrol Signals
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
	// Addition level 1 flag
	always @(posedge clk_i) begin : ADD_1_FLAG // pipeline 5
		if(~rst_n_i || start_i) begin
			r_add_1_flag_temp 		<= 0;
			r_add_1_flag 			<= 0;
		end else begin
			r_add_1_flag_temp[0:0] 	<= r_mult_flag;
			r_add_1_flag_temp[1:1] 	<= r_add_1_flag_temp[0:0];
			r_add_1_flag_temp[2:2] 	<= r_add_1_flag_temp[1:1];
			r_add_1_flag_temp[3:3] 	<= r_add_1_flag_temp[2:2];
			r_add_1_flag 			<= r_add_1_flag_temp[3:3];
		end
	end
	// Addition level 2 flag
	always @(posedge clk_i) begin : ADD_2_FLAG // pipeline 5
		if(~rst_n_i || start_i) begin
			r_add_2_flag_temp 		<= 0;
			r_add_2_flag 			<= 0;
		end else begin
			r_add_2_flag_temp[0:0] 	<= r_add_1_flag;
			r_add_2_flag_temp[1:1] 	<= r_add_2_flag_temp[0:0];
			r_add_2_flag_temp[2:2] 	<= r_add_2_flag_temp[1:1];
			r_add_2_flag_temp[3:3] 	<= r_add_2_flag_temp[2:2];
			r_add_2_flag 			<= r_add_2_flag_temp[3:3];
		end
	end
	// Addition level 3 flag
	always @(posedge clk_i) begin : ADD_3_FLAG // pipeline 5
		if(~rst_n_i || start_i) begin
			r_add_3_flag_temp 		<= 0;
			r_add_3_flag 			<= 0;
		end else begin
			r_add_3_flag_temp[0:0] 	<= r_add_2_flag;
			r_add_3_flag_temp[1:1] 	<= r_add_3_flag_temp[0:0];
			r_add_3_flag_temp[2:2] 	<= r_add_3_flag_temp[1:1];
			r_add_3_flag_temp[3:3] 	<= r_add_3_flag_temp[2:2];
			r_add_3_flag 			<= r_add_3_flag_temp[3:3];
		end
	end
	// Conv flag
	always @(posedge clk_i) begin : CONV_FLAG // pipeline 5
		if(~rst_n_i || start_i) begin
			r_conv_flag_temp 		<= 0;
			r_conv_flag 			<= 0;
		end else begin
			r_conv_flag_temp[0:0] 	<= r_add_3_flag;
			r_conv_flag_temp[1:1] 	<= r_conv_flag_temp[0:0];
			r_conv_flag_temp[2:2] 	<= r_conv_flag_temp[1:1];
			r_conv_flag_temp[3:3] 	<= r_conv_flag_temp[2:2];
			r_conv_flag 			<= r_conv_flag_temp[3:3];
		end
	end

	// SUB FIFO Write enable
	assign w_sub_fifo_wr_en = r_mult_flag;

	// SUB FIFO Write Data
	assign w_sub_fifo_din[47:36] = w_mult_1[8];
	assign w_sub_fifo_din[35:24] = w_mult_2[8];
	assign w_sub_fifo_din[23:12] = w_mult_3[8];
	assign w_sub_fifo_din[11:00] = w_mult_4[8];

	// SUB FIFO Read enable
	assign w_sub_fifo_rd_en = r_add_3_flag_temp[2:2];  //***************************************************

	// CONV 2nd din
	always @(posedge clk_i) begin : CONV_2ND_DIN
		if(~rst_n_i) begin
			r_conv_1_din2 <= 0;
			r_conv_2_din2 <= 0;
			r_conv_3_din2 <= 0;
			r_conv_4_din2 <= 0;
		end else begin
			r_conv_1_din2 <= w_sub_fifo_dout[47:36];
			r_conv_2_din2 <= w_sub_fifo_dout[35:24];
			r_conv_3_din2 <= w_sub_fifo_dout[23:12];
			r_conv_4_din2 <= w_sub_fifo_dout[11:00];
		end
	end

	// EXP 3x3 FIFO Wr data
	assign w_exp_fifo_din[47:36] = w_conv_1;
	assign w_exp_fifo_din[35:24] = w_conv_2;
	assign w_exp_fifo_din[23:12] = w_conv_3;
	assign w_exp_fifo_din[11:00] = w_conv_4;

	// // EXP 3x3 FIFO Write enable
	assign w_exp_fifo_wr_en = r_conv_flag;

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------
	
	// Multiplication Instant
	genvar i;
	generate
		for (i = 0; i < 9; i = i + 1) begin : MULT_3X3
			mult_12 flaot_mult_1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			({layer_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_2_i 			({kernal_1_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_mult_o 		(w_mult_1[8 - i])
			);
			mult_12 flaot_mult_2_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			({layer_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_2_i 			({kernal_2_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_mult_o 		(w_mult_2[8 - i])
			);
			mult_12 flaot_mult_3_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			({layer_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_2_i 			({kernal_3_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_mult_o 		(w_mult_3[8 - i])
			);
			mult_12 flaot_mult_4_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			({layer_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_2_i 			({kernal_4_data_i[71 - 8*i : 64 - 8*i],4'b0000}),
				.data_mult_o 		(w_mult_4[8 - i])
			);
		end
	endgenerate

	// Addition Level 1
	genvar j;
	generate
		for (j = 0; j < 4; j = j + 1) begin : ADD_3X3_1
			add_12 flaot_add_1_1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_mult_1[7 - 2*j]),
				.data_2_i 			(w_mult_1[6 - 2*j]),
				.data_sum_o 		(w_add_1_1[3 - j])
			);
			add_12 flaot_add_1_2_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_mult_2[7 - 2*j]),
				.data_2_i 			(w_mult_2[6 - 2*j]),
				.data_sum_o 		(w_add_1_2[3 - j])
			);
			add_12 flaot_add_1_3_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_mult_3[7 - 2*j]),
				.data_2_i 			(w_mult_3[6 - 2*j]),
				.data_sum_o 		(w_add_1_3[3 - j])
			);
			add_12 flaot_add_1_4_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_mult_4[7 - 2*j]),
				.data_2_i 			(w_mult_4[6 - 2*j]),
				.data_sum_o 		(w_add_1_4[3 - j])
			);
		end
	endgenerate

	// Addition Level 2
	genvar k;
	generate
		for (k = 0; k < 2; k = k + 1) begin : ADD_3X3_2
			add_12 flaot_add_2_1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_add_1_1[3 - 2*k]),
				.data_2_i 			(w_add_1_1[2 - 2*k]),
				.data_sum_o 		(w_add_2_1[1 - k])
			);
			add_12 flaot_add_2_2_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_add_1_2[3 - 2*k]),
				.data_2_i 			(w_add_1_2[2 - 2*k]),
				.data_sum_o 		(w_add_2_2[1 - k])
			);
			add_12 flaot_add_2_3_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_add_1_3[3 - 2*k]),
				.data_2_i 			(w_add_1_3[2 - 2*k]),
				.data_sum_o 		(w_add_2_3[1 - k])
			);
			add_12 flaot_add_2_4_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_add_1_4[3 - 2*k]),
				.data_2_i 			(w_add_1_4[2 - 2*k]),
				.data_sum_o 		(w_add_2_4[1 - k])
			);
		end
	endgenerate

	// Addition Level 3
	add_12 flaot_add_3_1_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_2_1[1]),
		.data_2_i 			(w_add_2_1[0]),
		.data_sum_o 		(w_add_3_1)
	);
	add_12 flaot_add_3_2_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_2_2[1]),
		.data_2_i 			(w_add_2_2[0]),
		.data_sum_o 		(w_add_3_2)
	);
	add_12 flaot_add_3_3_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_2_3[1]),
		.data_2_i 			(w_add_2_3[0]),
		.data_sum_o 		(w_add_3_3)
	);
	add_12 flaot_add_3_4_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_2_4[1]),
		.data_2_i 			(w_add_2_4[0]),
		.data_sum_o 		(w_add_3_4)
	);

	// 9th  Mult data
	exp_3x3_conv_add_fifo exp_3x3_conv_add_fifo_inst
	(
		.clock 				(clk_i),
		.aclr 				(start_i),

		.data 				(w_sub_fifo_din),
		.wrreq 				(w_sub_fifo_wr_en),

		.rdreq 				(w_sub_fifo_rd_en),
		.q 					(w_sub_fifo_dout)
	);

	// FINAL Addition 
	add_12 flaot_add_4_1_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_3_1),
		.data_2_i 			(r_conv_1_din2),
		.data_sum_o 		(w_conv_1)
	);
	add_12 flaot_add_4_2_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_3_2),
		.data_2_i 			(r_conv_2_din2),
		.data_sum_o 		(w_conv_2)
	);
	add_12 flaot_add_4_3_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_3_3),
		.data_2_i 			(r_conv_3_din2),
		.data_sum_o 		(w_conv_3)
	);
	add_12 flaot_add_4_4_inst 
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_3_4),
		.data_2_i 			(r_conv_4_din2),
		.data_sum_o 		(w_conv_4)
	);

	// Expand 3x3 Conv FIFO
	expand_conv_fifo expand_3x3_fifo_inst
	(
		.clock 				(clk_i),
		.aclr 				(start_i),

		.data 				(w_exp_fifo_din),
		.wrreq 				(w_exp_fifo_wr_en),
		.usedw 				(fifo_exp_3x3_data_count_o),

		.rdreq 				(fifo_exp_3x3_rd_en_i),
		.empty 				(fifo_exp_3x3_empty_o),
		.q 					(fifo_exp_3x3_rd_data_o)
	);

endmodule

