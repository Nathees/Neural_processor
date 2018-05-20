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

module squeeze_convolution(
	clk_i,
	rst_n_i,

	start_i,
	exp_1x1_en_i,
	squ_3x3_ker_depth_i,
	no_of_squ_kernals_i,
	squ_layer_dimension_i,

	squ_data_req_o,
	squ_data_ready_i,
	squ_3x3_data_i,
	squ_1x1_data_i,

	squ_ker_req_o,
	squ_ker_ready_i,
	squ_3x3_ker_i,
	squ_1x1_ker_i,

	fifo_squ_bash_clr_i,
	fifo_squ_bash_wr_data_i,
	fifo_squ_bash_wr_en_i,
	fifo_squ_bash_data_count_o,

	output_data_o,
	output_flag_o,
	output_fifo_busy_i
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
	squ_3x3_ker_depth_i 		:- [squeeze 3x3 depth]
	no_of_squ_kernals_i 		:- [NO of squeeze kernals - 1]
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
	input 				[8:0]										squ_3x3_ker_depth_i;
	input 				[9:0]	 									no_of_squ_kernals_i;
	input 				[6:0]	 									squ_layer_dimension_i;

	// Squeeze Request data control Signals
	output 															squ_data_req_o;
	input 		 													squ_data_ready_i;
	input 				[95:0] 										squ_3x3_data_i;
	input 				[95:0] 										squ_1x1_data_i;

	// Squeeze Request Kernal control Signals
	output 															squ_ker_req_o;
	input 		 													squ_ker_ready_i;
	input 				[63:0] 										squ_3x3_ker_i;
	input 				[63:0] 										squ_1x1_ker_i;

	// Squeeze Bash FIFO COntrol Signals
	input 															fifo_squ_bash_clr_i;
	input 				[63:0] 										fifo_squ_bash_wr_data_i;
	input 															fifo_squ_bash_wr_en_i;
	output 				[6:0] 										fifo_squ_bash_data_count_o;

	// Output Data COntrol Signals
	output 		  		[11:0]										output_data_o;
	output 		 													output_flag_o;
	input 															output_fifo_busy_i;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Config Control Signals
	reg 															r_exp_1x1_en;
	reg 				[1:0]										r_repeat_add_count;

	wire 															w_add_en_flag;
	wire 															w_skip_neg_flag;
 	wire 															w_req_en;
	reg 				[1:0]										r_req_en;

	// Squeeze input Signals
	reg 				[95:0] 										r_squ_3x3_data;
	reg 				[95:0] 										r_squ_1x1_data;
	reg 				[63:0] 										r_squ_3x3_ker;
	reg 				[63:0] 										r_squ_1x1_ker;

	// Mult and Add control Signals
	wire 				[11:0] 										w_3x3_mult 				[0:7];
	wire 				[11:0] 										w_1x1_mult 				[0:7];

	wire 				[11:0] 										w_3x3_add_1 			[0:3];
	wire 				[11:0] 										w_1x1_add_1 			[0:3];
	wire 				[11:0] 										w_3x3_add_2 			[0:1];
	wire 				[11:0] 										w_1x1_add_2 			[0:1];

	wire 				[11:0] 										w_3x3_conv;
	wire 				[11:0] 										w_1x1_conv;
	wire 				[11:0] 										w_conv_out;

	// Mult and Add flag
	reg 				[1:0]										r_mult_flag_temp;
	reg 															r_mult_flag;
	reg 				[3:0]										r_add_1_flag_temp;
	reg 															r_add_1_flag;
	reg 				[3:0]										r_add_2_flag_temp;
	reg 															r_add_2_flag;
	reg 				[3:0]										r_add_3_flag_temp;
	reg 															r_add_3_flag;
	reg 				[3:0] 										r_conv_flag_temp;
	reg 															r_conv_flag;

	// Conv output
	reg 				[95:0] 										r_conv_data;
	reg 				[2:0] 										r_conv_count;
	reg 															r_conv_8_flag;

	wire 		 													w_bash_ram_ready;
	
//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// COnfig
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_exp_1x1_en 		<= 0;
			r_repeat_add_count 	<= 0;
		end 
		else if(start_i) begin
			r_exp_1x1_en 		<= exp_1x1_en_i;
			r_repeat_add_count 	<= squ_3x3_ker_depth_i[8:6] - 1;
		end
	end

	// Request Control Signals
	assign w_req_en = (squ_data_ready_i && squ_ker_ready_i && ~output_fifo_busy_i); // && w_bash_ram_ready
	assign squ_data_req_o = w_req_en;
	assign squ_ker_req_o = w_req_en;

	always @(posedge clk_i) begin : REQUEST_EN
		if(~rst_n_i || start_i) begin
			r_req_en <= 0;
		end else begin
			r_req_en[0:0] <= w_req_en;
			r_req_en[1:1] <= r_req_en[0:0];
		end
	end

	// Squeeze kernal & data
	always @(posedge clk_i) begin : SQU_KERL_DATA
		if(~rst_n_i) begin
			r_squ_3x3_data 	<= 0;
			r_squ_1x1_data 	<= 0;
			r_squ_3x3_ker 	<= 0;
			r_squ_1x1_ker 	<= 0;
		end else begin
			r_squ_3x3_data 	<= squ_3x3_data_i;
			r_squ_1x1_data 	<= squ_1x1_data_i;
			r_squ_3x3_ker 	<= squ_3x3_ker_i;
			r_squ_1x1_ker 	<= squ_1x1_ker_i;
		end
	end

	// Mult Flag
	always @(posedge clk_i) begin : MULT_FLAG // Pipeline 3
		if(~rst_n_i || start_i) begin
			r_mult_flag_temp 		<= 0;
			r_mult_flag 			<= 0;
		end else begin
			r_mult_flag_temp[0:0] 	<= r_req_en[1:1];
			r_mult_flag_temp[1:1] 	<= r_mult_flag_temp[0:0];
			r_mult_flag 			<= r_mult_flag_temp[1:1];
		end
	end
	// Addition level 1 flag
	always @(posedge clk_i) begin : ADD_1_FLAG // Pipeline 5
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
	always @(posedge clk_i) begin : ADD_2_FLAG // Pipeline 5
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
	always @(posedge clk_i) begin : ADD_3_FLAG // Pipeline 5
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
	always @(posedge clk_i) begin : CONV_FLAG // Pipeline 5
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

	// COnv Count
	always @(posedge clk_i) begin : CONV_COUNT
		if(~rst_n_i || start_i) begin
			r_conv_count <= 0;
		end 
		else if(r_conv_flag) begin
			r_conv_count <= r_conv_count + 1;
		end
	end

	// COnv Data
	always @(posedge clk_i) begin : CONV_DATA
		if(~rst_n_i) begin
			r_conv_data <= 0;
		end 
		else begin
			case(r_conv_count)
				0 	:	r_conv_data[95:84] <= w_conv_out;
				1 	:	r_conv_data[83:72] <= w_conv_out;
				2 	:	r_conv_data[71:60] <= w_conv_out;
				3 	:	r_conv_data[59:48] <= w_conv_out;
				4 	:	r_conv_data[47:36] <= w_conv_out;
				5 	:	r_conv_data[35:24] <= w_conv_out;
				6 	:	r_conv_data[23:12] <= w_conv_out;
				7 	:	r_conv_data[11:00] <= w_conv_out;
			endcase
		end
	end

	// CONV Flag
	always @(posedge clk_i) begin : REPEAT_FLAG
		if(~rst_n_i || start_i) begin
			r_conv_8_flag <= 0;
		end else begin
			r_conv_8_flag <= (r_conv_flag && r_conv_count == 7);
		end
	end
	

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Last Squeeze Add
	last_squ_add last_squ_add_inst
	(
		.clk_i 							(clk_i),
		.rst_n_i 						(rst_n_i),

		.start_i 						(start_i),
		.max_repeat_add_i 				(r_repeat_add_count),
		.no_of_squ_kernals_i			(no_of_squ_kernals_i),
		.squ_layer_dimension_i			(squ_layer_dimension_i),

		.fifo_squ_bash_clr_i 			(fifo_squ_bash_clr_i),
		.fifo_squ_bash_wr_data_i 		(fifo_squ_bash_wr_data_i),
		.fifo_squ_bash_wr_en_i 			(fifo_squ_bash_wr_en_i),
		.fifo_squ_bash_data_count_o 	(fifo_squ_bash_data_count_o),
		.bash_ram_ready_o 				(w_bash_ram_ready),

		.conv_data_i 					(r_conv_data),
		.conv_flag_i 					(r_conv_8_flag),

		.output_data_o 					(output_data_o),
		.output_flag_o 					(output_flag_o)
	);

	// Multiplication
	genvar i,j;
	generate
		for (i = 0; i < 8; i = i + 1) begin : MULT_3X3
			mult_12 temp_mult_3x3_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(r_squ_3x3_data[95 - 12*i : 84 - 12*i]),
				.data_2_i 			({r_squ_3x3_ker[63 - 8*i : 56 - 8*i],4'b0000}),
				.data_mult_o 		(w_3x3_mult[7 - i])
			);
		end
	endgenerate
	generate
		for (j = 0; j < 8; j = j + 1) begin : MULT_1X1
			mult_12 temp_mult_1x1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(r_squ_1x1_data[95 - 12*j : 84 - 12*j]),
				.data_2_i 			({r_squ_1x1_ker[63 - 8*j : 56 - 8*j],4'b0000}),
				.data_mult_o 		(w_1x1_mult[7 - j])
			);
		end
	endgenerate

	// Addition Level 1
	genvar k_1,l_1;
	generate
		for (k_1 = 0; k_1 < 4; k_1 = k_1 + 1) begin : ADD_3X3_1
			add_12 temp_add1_3x3_1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_3x3_mult[7 - 2*k_1]),
				.data_2_i 			(w_3x3_mult[6 - 2*k_1]),
				.data_sum_o 		(w_3x3_add_1[3 - k_1])
			);
		end
	endgenerate
	generate
		for (l_1 = 0; l_1 < 4; l_1 = l_1 + 1) begin : ADD_1x1_1
			add_12 temp_add1_1x1_1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_1x1_mult[7 - 2*l_1]),
				.data_2_i 			(w_1x1_mult[6 - 2*l_1]),
				.data_sum_o 		(w_1x1_add_1[3 - l_1])
			);
		end
	endgenerate
	// Addition Level 2
	genvar k_2,l_2;
	generate
		for (k_2 = 0; k_2 < 2; k_2 = k_2 + 1) begin : ADD_3X3_2
			add_12 temp_add1_3x3_2_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_3x3_add_1[3 - 2*k_2]),
				.data_2_i 			(w_3x3_add_1[2 - 2*k_2]),
				.data_sum_o 		(w_3x3_add_2[1 - k_2])
			);
		end
	endgenerate
	generate
		for (l_2 = 0; l_2 < 2; l_2 = l_2 + 1) begin : ADD_1x1_2
			add_12 temp_add1_1x1_2_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_1x1_add_1[3 - 2*l_2]),
				.data_2_i 			(w_1x1_add_1[2 - 2*l_2]),
				.data_sum_o 		(w_1x1_add_2[1 - l_2])
			);
		end
	endgenerate
	// Addition Level 3
	add_12 temp_add1_3x3_3_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_3x3_add_2[1]),
		.data_2_i 			(w_3x3_add_2[0]),
		.data_sum_o 		(w_3x3_conv)
	);
	add_12 temp_add1_1x1_3_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_1x1_add_2[1]),
		.data_2_i 			(w_1x1_add_2[0]),
		.data_sum_o 		(w_1x1_conv)
	);

	// Combine Addition
	add_en_12 temp_add_comb_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_3x3_conv),
		.data_2_i 			(w_1x1_conv),
		.data_sum_o 		(w_conv_out),

		.add_en_i 			(r_exp_1x1_en),
		.skip_neg_en_i 		(0)
	);

endmodule

