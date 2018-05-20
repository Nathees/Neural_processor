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

module fire_config_expand(
	clk_i,
	rst_n_i,

	start_i,
	max_en_i,
	one_exp_layer_addr_limit_i,
	exp_ker_depth_i,
	layer_dimension_i,

	max_en_o,
	layer_done_flag_i,
	expand_flag_i,
	layer_end_addr_o,
	new_layer_flag_o,
	new_line_flag_o,
	first_layer_flag_o,
	last_layer_flag_o,
	fire_end_flag_o
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
	input 						[10:0] 								one_exp_layer_addr_limit_i;
	input 						[5:0] 								exp_ker_depth_i;
	input 						[6:0] 								layer_dimension_i;

	// COnfig COntrol Signals
	output 	reg 													max_en_o;
	input 															layer_done_flag_i;
	input 															expand_flag_i;
	output 	reg 				[10:0] 								layer_end_addr_o;
	output 	reg 													new_layer_flag_o;
	output 	reg 													new_line_flag_o;
	output 	reg  													first_layer_flag_o;
	output 	reg  													last_layer_flag_o;
	output	reg 													fire_end_flag_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------
			
	//Config COntrol Signals
	reg 						[5:0] 								r_layer_no;
	reg 						[6:0] 								r_layer_dim;
	reg 															r_max_en;

	reg 						[5:0] 								r_layer_count;
	reg 						[6:0] 								r_row_count;
	reg 															r_row_flag;

	reg 						[2:0]								r_new_layer_flag;
	reg 						[2:0]								r_new_line_flag;
	reg 						[4:0]								r_first_layer_flag;
	reg 						[3:0]								r_last_layer_flag;
	reg 						[15:0] 								r_fire_end_flag;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Configuration
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			layer_end_addr_o 	<= 0;
			r_layer_no 			<= 0;
			r_layer_dim 		<= 0;
			max_en_o 			<= 0;
		end 
		else if(start_i) begin
			layer_end_addr_o 	<= one_exp_layer_addr_limit_i - 4;
			r_layer_no 			<= exp_ker_depth_i;
			r_layer_dim 		<= layer_dimension_i;
			max_en_o 			<= max_en_i;
		end
	end

	// Layer Count
	always @(posedge clk_i) begin : LAYER_COUNT
		if(~rst_n_i || start_i) begin
			r_layer_count <= 0;
		end 
		else if(layer_done_flag_i && r_layer_count == r_layer_no) begin
			r_layer_count <= 0;
		end 
		else if(layer_done_flag_i) begin
			r_layer_count <= r_layer_count + 1;
		end
	end

	// ROW Flag
	always @(posedge clk_i) begin : ROW_FLAG
		if(~rst_n_i || start_i) begin
			r_row_flag <= 0;
		end else begin
			r_row_flag <= (layer_done_flag_i && r_layer_count == r_layer_no);
		end
	end

	// row count
	always @(posedge clk_i) begin : ROW_COUNT
		if(~rst_n_i || start_i) begin
			r_row_count <= 0;
		end
		else if(r_row_flag && r_row_count == r_layer_dim) begin
			r_row_count <= 0;
		end 
		else if(r_row_flag) begin
			r_row_count <= r_row_count + 1;
		end
	end

	// New Layer flag
	always @(posedge clk_i) begin : NEW_LAYER_FLAG_TEMP
		if(~rst_n_i || start_i) begin
			r_new_layer_flag <= 0;
		end
		else if(expand_flag_i && new_layer_flag_o) begin
			r_new_layer_flag <= 0;
		end
		else if(layer_done_flag_i && expand_flag_i) begin
			r_new_layer_flag[1:0] <= 2'b11;
			r_new_layer_flag[2:2] <= 0;
		end
		else if(layer_done_flag_i) begin
			r_new_layer_flag[0:0] <= 1;
			r_new_layer_flag[2:1] <= 0;
		end
		else if(expand_flag_i) begin
			r_new_layer_flag[1:1] <= r_new_layer_flag[0:0];
			r_new_layer_flag[2:2] <= r_new_layer_flag[1:1];
		end
	end
	always @(posedge clk_i) begin : NEW_LAYER_FLAG
		if(~rst_n_i || start_i)
			new_layer_flag_o <= 0;
		else if(expand_flag_i && new_layer_flag_o) 
			new_layer_flag_o <= 0;
		else if(expand_flag_i) 
			new_layer_flag_o <= r_new_layer_flag[2:2];
	end

	// New Line flag
	always @(posedge clk_i) begin : NEW_LINE_FLAG_TEMP
		if(~rst_n_i || start_i) begin
			r_new_line_flag <= 0; 
		end
		else if(expand_flag_i && new_line_flag_o) begin
			r_new_line_flag <= 0; 
		end
		else if(layer_done_flag_i && expand_flag_i && r_layer_count == r_layer_no) begin
			r_new_line_flag[1:0] <= 2'b11;
			r_new_line_flag[2:2] <= 0;
		end
		else if(layer_done_flag_i && r_layer_count == r_layer_no) begin
			r_new_line_flag[0:0] <= 1;
			r_new_line_flag[2:1] <= 0;
		end
		else if(expand_flag_i) begin
			r_new_line_flag[1:1] <= r_new_line_flag[0:0];
			r_new_line_flag[2:2] <= r_new_line_flag[1:1];
		end
	end
	always @(posedge clk_i) begin : NEW_LINE_FLAG
		if(~rst_n_i || start_i)
			new_line_flag_o <= 0;
		else if(expand_flag_i && new_line_flag_o) 
			new_line_flag_o <= 0;
		else if(expand_flag_i) 
			new_line_flag_o <= r_new_line_flag[2:2];
	end

	// First Layer Flag
	always @(posedge clk_i) begin : FIRST_LAYER_FLAG_TEPM
		if(~rst_n_i || start_i) begin
			r_first_layer_flag <= 0; 
		end
		else if(expand_flag_i && first_layer_flag_o) begin
			r_first_layer_flag <= 0; 
		end
		else if(layer_done_flag_i && expand_flag_i && r_layer_count == r_layer_no) begin
			r_first_layer_flag[1:0] <= 2'b11;
			r_first_layer_flag[2:2] <= 0;
		end
		else if(layer_done_flag_i && r_layer_count == r_layer_no) begin
			r_first_layer_flag[0:0] <= 1;
			r_first_layer_flag[2:1] <= 0;
		end
		else if(expand_flag_i) begin
			r_first_layer_flag[1:1] <= r_first_layer_flag[0:0];
			r_first_layer_flag[2:2] <= r_first_layer_flag[1:1];
			r_first_layer_flag[3:3] <= r_first_layer_flag[2:2];
		end
	end
	always @(posedge clk_i) begin : FIRST_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			first_layer_flag_o <= 1;
		end 
		else if(expand_flag_i && first_layer_flag_o && new_layer_flag_o) begin // new_layer_flag_o
			first_layer_flag_o <= 0;
		end
		else if(expand_flag_i && r_first_layer_flag[3:3]) begin
			first_layer_flag_o <= 1;
		end
	end

	
	// Last Layer Flag
	always @(posedge clk_i) begin : LAST_LAYER_FLAG_TEPM
		if(~rst_n_i || start_i) begin
			r_last_layer_flag <= 0; 
		end
		else if(expand_flag_i && last_layer_flag_o) begin
			r_last_layer_flag <= 0; 
		end
		else if(layer_done_flag_i && expand_flag_i && r_layer_count == r_layer_no-1) begin
			r_last_layer_flag[1:0] <= 2'b11;
			r_last_layer_flag[3:2] <= 0;
		end
		else if(layer_done_flag_i && r_layer_count == r_layer_no-1) begin
			r_last_layer_flag[0:0] <= 1;
			r_last_layer_flag[3:1] <= 0;
		end
		else if(expand_flag_i) begin
			r_last_layer_flag[1:1] <= r_last_layer_flag[0:0];
			r_last_layer_flag[2:2] <= r_last_layer_flag[1:1];
			r_last_layer_flag[3:3] <= r_last_layer_flag[2:2];
		end
	end
	always @(posedge clk_i) begin : LAST_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			last_layer_flag_o <= 0;
		end 
		else if(expand_flag_i && last_layer_flag_o && new_layer_flag_o) begin
			last_layer_flag_o <= 0;
		end 
		else if(expand_flag_i && r_last_layer_flag[3:3]) begin
			last_layer_flag_o <= 1;
		end
	end

	// FIRE End Flag
	always @(posedge clk_i) begin : FIRE_END_FLAG_TEMP
		if(~rst_n_i || start_i) begin
			r_fire_end_flag <= 0;
		end 
		else if(r_row_flag && r_row_count == r_layer_dim) begin
			r_fire_end_flag[0:0] <= 1;
			r_fire_end_flag[15:1] <= 0;
		end
		else if(expand_flag_i) begin
			r_fire_end_flag[01:01] <= r_fire_end_flag[00:00];
			r_fire_end_flag[02:02] <= r_fire_end_flag[01:01];
			r_fire_end_flag[03:03] <= r_fire_end_flag[02:02];
			r_fire_end_flag[04:04] <= r_fire_end_flag[03:03];
			r_fire_end_flag[05:05] <= r_fire_end_flag[04:04];
			r_fire_end_flag[06:06] <= r_fire_end_flag[05:05];
			r_fire_end_flag[07:07] <= r_fire_end_flag[06:06];
			r_fire_end_flag[08:08] <= r_fire_end_flag[07:07];
			r_fire_end_flag[09:09] <= r_fire_end_flag[08:08];
			r_fire_end_flag[10:10] <= r_fire_end_flag[09:09];
			r_fire_end_flag[11:11] <= r_fire_end_flag[10:10];
			r_fire_end_flag[12:12] <= r_fire_end_flag[11:11];
			r_fire_end_flag[13:13] <= r_fire_end_flag[12:12];
			r_fire_end_flag[14:14] <= r_fire_end_flag[13:13];
			r_fire_end_flag[15:15] <= r_fire_end_flag[14:14];
		end
	end
	always @(posedge clk_i) begin : FIRE_END_FLAG
		if(~rst_n_i || start_i) begin
			fire_end_flag_o <= 0;
		end 
		else if(r_fire_end_flag[15:15] && expand_flag_i) begin
			fire_end_flag_o <= 1;
		end
	end
	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------


endmodule

