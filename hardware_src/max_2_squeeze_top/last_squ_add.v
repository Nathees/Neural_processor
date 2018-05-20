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

module last_squ_add(
	clk_i,
	rst_n_i,

	start_i,
	max_repeat_add_i,
	no_of_squ_kernals_i,
	squ_layer_dimension_i,

	fifo_squ_bash_clr_i,
	fifo_squ_bash_wr_data_i,
	fifo_squ_bash_wr_en_i,
	fifo_squ_bash_data_count_o,
	bash_ram_ready_o,

	conv_data_i,
	conv_flag_i,

	output_data_o,
	output_flag_o
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
		no_of_squ_kernals_i 			:- [NO of squeeze kernals - 1]
		squ_layer_dimension_i 			:- [Squeeze layer dimension - 1] // After max pool
	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfig Control Signals
	input 															start_i;
	input 				[1:0]										max_repeat_add_i;
	input 				[9:0]	 									no_of_squ_kernals_i;
	input 				[6:0]	 									squ_layer_dimension_i;

	// Squeeze Bash FIFO COntrol Signals
	input 															fifo_squ_bash_clr_i;
	input 				[63:0] 										fifo_squ_bash_wr_data_i;
	input 															fifo_squ_bash_wr_en_i;
	output 				[6:0] 										fifo_squ_bash_data_count_o;

	output 		 													bash_ram_ready_o;

	// Squeeze Request data control Signals
	input 				[95:0] 										conv_data_i;
	input 															conv_flag_i;

	// Output Data COntrol Signals
	output reg	  		[11:0]										output_data_o;
	output reg	 													output_flag_o;


//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Addition Control Signals
	wire 				[11:0] 										w_add_1 		[0:3];
	wire 				[11:0] 										w_add_2 		[0:1];
	wire 				[11:0] 										w_add_3;

	// Final addition control signals
	wire 				[11:0] 										w_fin_dout;
	reg 				[11:0] 										r_fin_din_2;
	reg 				[1:0] 										r_repeat_add_count;

	wire 															w_add_en_flag;
	wire 															w_skip_en_flag;

	// Flag Control Signals
	reg 				[3:0]										r_add_1_flag_temp;
	reg 															r_add_1_flag;
	reg 				[3:0]										r_add_2_flag_temp;
	reg 															r_add_2_flag;
	reg 				[3:0]										r_add_3_flag_temp;
	reg 															r_add_3_flag;

	reg 				[3:0]										r_fin_add_flag_temp;
	reg 															r_fin_add_flag;
	reg 				[10:0]										r_out_flag_temp;

	// Bash COntrol Signals
	reg 				[2:0] 										r_bash_req;
	wire 				[7:0] 										w_bash_data;
	reg 				[7:0] 										r_bash_data;

	// Output Data
	wire 				[11:0] 										w_dout;
	
//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Addition level 1 flag
	always @(posedge clk_i) begin : ADD_1_FLAG
		if(~rst_n_i || start_i) begin
			r_add_1_flag_temp 		<= 0;
			r_add_1_flag 			<= 0;
		end else begin
			r_add_1_flag_temp[0:0] 	<= conv_flag_i;
			r_add_1_flag_temp[1:1] 	<= r_add_1_flag_temp[0:0];
			r_add_1_flag_temp[2:2] 	<= r_add_1_flag_temp[1:1];
			r_add_1_flag_temp[3:3] 	<= r_add_1_flag_temp[2:2];
			r_add_1_flag 			<= r_add_1_flag_temp[3:3];
		end
	end
	// Addition level 2 flag
	always @(posedge clk_i) begin : ADD_2_FLAG
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
	always @(posedge clk_i) begin : ADD_3_FLAG
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
	// Final Addition flag
	always @(posedge clk_i) begin : FIN_ADD_FLAG
		if(~rst_n_i || start_i) begin
			r_fin_add_flag_temp 		<= 0;
			r_fin_add_flag 				<= 0;
		end else begin
			r_fin_add_flag_temp[0:0] 	<= r_add_3_flag;
			r_fin_add_flag_temp[1:1] 	<= r_fin_add_flag_temp[0:0];
			r_fin_add_flag_temp[2:2] 	<= r_fin_add_flag_temp[1:1];
			r_fin_add_flag_temp[3:3] 	<= r_fin_add_flag_temp[2:2];
			r_fin_add_flag 				<= r_fin_add_flag_temp[3:3];
		end
	end
	// Output Flag
	always @(posedge clk_i) begin : OUTPUT_FLAG
		if(~rst_n_i || start_i) begin
			r_out_flag_temp <= 0;
			output_flag_o <= 0;
		end else begin
			r_out_flag_temp[00:00] <= (r_add_3_flag && r_repeat_add_count == max_repeat_add_i);
			r_out_flag_temp[01:01] <= r_out_flag_temp[00:00]; 
			r_out_flag_temp[02:02] <= r_out_flag_temp[01:01]; 
			r_out_flag_temp[03:03] <= r_out_flag_temp[02:02]; 
			r_out_flag_temp[04:04] <= r_out_flag_temp[03:03]; 
			r_out_flag_temp[05:05] <= r_out_flag_temp[04:04]; 
			r_out_flag_temp[06:06] <= r_out_flag_temp[05:05]; 
			r_out_flag_temp[08:08] <= r_out_flag_temp[06:06];
			r_out_flag_temp[09:09] <= r_out_flag_temp[08:08];
			r_out_flag_temp[10:10] <= r_out_flag_temp[09:09]; 
			output_flag_o 		   <= r_out_flag_temp[10:10];
		end
	end

	// Final addition 2nd input
	always @(posedge clk_i) begin : FIN_ADD_2ND_DIN
		if(~rst_n_i) begin
			r_fin_din_2 <= 0;
		end 
		else if(r_fin_add_flag) begin
			r_fin_din_2 <= w_fin_dout;
		end
	end

	// Repeat Add count
	always @(posedge clk_i) begin : REPEAT_ADD_COUNT
		if(~rst_n_i || start_i) begin
			r_repeat_add_count <= 0;
		end 
		else if(r_add_3_flag && r_repeat_add_count == max_repeat_add_i) begin
			r_repeat_add_count <= 0;
		end
		else if(r_add_3_flag) begin
			r_repeat_add_count <= r_repeat_add_count + 1;
		end
	end

	// Add flag
	assign w_add_en_flag = (r_add_3_flag && r_repeat_add_count != 0); 

	// Bash Request
	always @(posedge clk_i) begin : BASH_REQ
		if(~rst_n_i || start_i) begin
			r_bash_req <= 0;
		end 
		else begin
			r_bash_req[0:0] <= (r_add_3_flag && r_repeat_add_count == max_repeat_add_i);
			r_bash_req[1:1] <= r_bash_req[0:0];
			r_bash_req[2:2] <= r_bash_req[1:1];
		end
	end

	// Bash Data
	always @(posedge clk_i) begin : BASH_DATA
		if(~rst_n_i) begin
			r_bash_data <= 0;
		end else begin
			r_bash_data <= w_bash_data;
		end
	end

	// Output Data
	always @(posedge clk_i) begin : OUTPUT_DATA
		if(~rst_n_i) begin
			output_data_o <= 0;
		end 
		else if(r_out_flag_temp[10:10]) begin //[7:7]
			output_data_o <= w_dout;
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Addition Level 1
	genvar k,l;
	generate
		for (k = 0; k < 4; k = k + 1) begin : ADD_1
			add_12 temp_add1_1_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(conv_data_i[95 - 24*k : 84 - 24*k]),
				.data_2_i 			(conv_data_i[83 - 24*k : 72 - 24*k]),
				.data_sum_o 		(w_add_1[3 - k])
			);
		end
	endgenerate
	generate
		for (l = 0; l < 2; l = l + 1) begin : ADD_2
			add_12 temp_add1_2_inst
			(
				.clk_i 				(clk_i),
				.rst_n_i 			(rst_n_i),

				.data_1_i 			(w_add_1[3 - 2*l]),
				.data_2_i 			(w_add_1[2 - 2*l]),
				.data_sum_o 		(w_add_2[1 - l])
			);
		end
	endgenerate
	add_12 temp_add1_3_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_2[1]),
		.data_2_i 			(w_add_2[0]),
		.data_sum_o 		(w_add_3)
	);
	add_en_12 final_add_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_add_3),
		.data_2_i 			(r_fin_din_2),
		.data_sum_o 		(w_fin_dout),

		.add_en_i 			(w_add_en_flag),
		.skip_neg_en_i 		(0) // w_skip_en_flag
	);

	// Bash Controller
	squ_bash_controller squ_bash_controller_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.no_of_squ_kernals_i 				(no_of_squ_kernals_i),
		.squ_layer_dimension_i 				(squ_layer_dimension_i),

		.fifo_squ_bash_clr_i 				(fifo_squ_bash_clr_i),
		.fifo_squ_bash_wr_data_i 			(fifo_squ_bash_wr_data_i),
		.fifo_squ_bash_wr_en_i 				(fifo_squ_bash_wr_en_i),
		.fifo_squ_bash_data_count_o 		(fifo_squ_bash_data_count_o),

		.bash_req_i 						(r_bash_req[2:2]),
		.bash_ram_ready_o 					(bash_ram_ready_o),
		.bash_data_o 						(w_bash_data)
	);

	add_en_12 final_bash_add_inst
	(
		.clk_i 				(clk_i),
		.rst_n_i 			(rst_n_i),

		.data_1_i 			(w_fin_dout),
		.data_2_i 			({r_bash_data,4'b0000}),
		.data_sum_o 		(w_dout),

		.add_en_i 			(1),
		.skip_neg_en_i 		(1)
	);

endmodule

