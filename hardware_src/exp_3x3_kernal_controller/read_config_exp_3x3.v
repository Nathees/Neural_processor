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

module read_config_exp_3x3(
	clk_i,
	rst_n_i,

	start_i,
	one_exp3_ker_addr_limit_i,
	exp3_ker_depth_i,
	layer_dimension_i,

	chk_nxt_addr_limt_i,
	exp_3x3_kerl_req_i,
	rd_end_addr_o,
	layer_select_o,
	new_layer_flag_o,
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

	// Configuration Control Signals
	input 															start_i;
	input 						[6:0] 								one_exp3_ker_addr_limit_i;
	input 						[5:0] 								exp3_ker_depth_i;
	input 						[6:0]								layer_dimension_i;

	// Layer Control Signals
	input 															chk_nxt_addr_limt_i;
	input 															exp_3x3_kerl_req_i;
	output 	reg					[6:0] 								rd_end_addr_o;
	output 	reg 													layer_select_o;
	output 	reg 													new_layer_flag_o;
	output 	reg	 													fire_end_flag_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------
			
	// Write Address Control Signals
	reg 						[6:0] 								r_layer_addr_space;
	reg 						[5:0] 								r_kernal_no;
	reg 						[6:0] 								r_layer_dim;

	reg 						[6:0] 								r_col_count;
	reg 						[5:0] 								r_kernal_count;
	reg 															r_row_flag;
	reg 						[6:0] 								r_row_count;

	reg 						[3:0] 								r_end_addr_flag;
	reg 							 								r_new_config_flag;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Configuration COntrol Signals
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_layer_addr_space 	<= 0;
			r_kernal_no 		<= 0;
			r_layer_dim 		<= 0;
		end 
		else if(start_i) begin
			r_layer_addr_space 	<= one_exp3_ker_addr_limit_i - 1;
			r_kernal_no 		<= exp3_ker_depth_i;
			r_layer_dim 		<= layer_dimension_i;
		end
	end

	// New Config Flag
	always @(posedge clk_i) begin : NEW_CONFIG_FLAG
		if(~rst_n_i) begin
			r_new_config_flag <= 0;
		end else begin
			r_new_config_flag <= start_i;
		end
	end

	// Column Count
	always @(posedge clk_i) begin : COL_COUNT
		if(~rst_n_i || start_i) begin
			r_col_count <= 0;
		end 
		else if(exp_3x3_kerl_req_i && chk_nxt_addr_limt_i && r_col_count == r_layer_dim) begin
			r_col_count <= 0;
		end 
		else if(exp_3x3_kerl_req_i && chk_nxt_addr_limt_i) begin
			r_col_count <= r_col_count + 1;
		end
	end

	// Layer Select
	always @(posedge clk_i) begin : LAYER_SELECT
		if(~rst_n_i || start_i) begin
			layer_select_o <= 0;
		end 
		else if(exp_3x3_kerl_req_i && chk_nxt_addr_limt_i && r_col_count == r_layer_dim) begin
			layer_select_o <= ~layer_select_o;
		end
	end

	// New LAYER Flag
	always @(posedge clk_i) begin : NEW_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			new_layer_flag_o <= 0;
		end 
		else if(exp_3x3_kerl_req_i && new_layer_flag_o) begin
			new_layer_flag_o <= 0;
		end 
		else if(exp_3x3_kerl_req_i) begin
			new_layer_flag_o <= (chk_nxt_addr_limt_i && r_col_count == r_layer_dim);
		end
	end

	// Kernal Count
	always @(posedge clk_i) begin : KERNAL_COUNT
		if(~rst_n_i || start_i) begin
			r_kernal_count <= 0;
		end 
		else if(exp_3x3_kerl_req_i && new_layer_flag_o && r_kernal_count == r_kernal_no) begin
			r_kernal_count <= 0;
		end 
		else if(exp_3x3_kerl_req_i && new_layer_flag_o) begin
			r_kernal_count <= r_kernal_count + 1;
		end
	end

	// ROW Flag
	always @(posedge clk_i) begin : ROW_FLAG
		if(~rst_n_i || start_i) begin
			r_row_flag <= 0;
		end 
		else if(exp_3x3_kerl_req_i && r_row_flag) begin
			r_row_flag <= 0;
		end 
		else if(exp_3x3_kerl_req_i) begin
			r_row_flag <= (new_layer_flag_o && r_kernal_count == r_kernal_no);
		end
	end

	// ROW Count
	always @(posedge clk_i) begin : ROW_COUNT
		if(~rst_n_i || start_i) begin
			r_row_count <= 0;
		end
		else if(exp_3x3_kerl_req_i && r_row_flag && r_row_count == r_layer_dim) begin
			r_row_count <= 0;
		end 
		else if(exp_3x3_kerl_req_i && r_row_flag)begin
			r_row_count <= r_row_count + 1;
		end
	end

	// End Address Flag
	always @(posedge clk_i) begin : END_ADDR_FLAG
		if(~rst_n_i || start_i) begin
			r_end_addr_flag <= 0;
		end 
		else if(exp_3x3_kerl_req_i && r_end_addr_flag[3:3]) begin
			r_end_addr_flag <= 0;
		end 
		else if(exp_3x3_kerl_req_i && chk_nxt_addr_limt_i) begin
			r_end_addr_flag[1:0] <= 2'b11;
			r_end_addr_flag[3:2] <= 0;
		end
		else if(exp_3x3_kerl_req_i) begin
			r_end_addr_flag[1:1] <= r_end_addr_flag[0:0];
			r_end_addr_flag[2:2] <= r_end_addr_flag[1:1];
			r_end_addr_flag[3:3] <= r_end_addr_flag[2:2];
		end
	end
	// End Address
	always @(posedge clk_i) begin : END_ADDR
		if(~rst_n_i) begin
			rd_end_addr_o <= 0;
		end 
		else if(r_new_config_flag) begin
			rd_end_addr_o <= r_layer_addr_space;
		end 
		else if(r_end_addr_flag[3:3] && exp_3x3_kerl_req_i) begin
			rd_end_addr_o <= (layer_select_o) ? 64 + r_layer_addr_space : r_layer_addr_space;
		end
	end

	// FIRE End Flag
	always @(posedge clk_i) begin : FIRE_END_FLAG
		if(~rst_n_i || start_i) begin
			fire_end_flag_o <= 0;
		end 
		else if(exp_3x3_kerl_req_i && r_row_flag && r_row_count == r_layer_dim) begin // new_layer_flag_o && r_kernal_count == r_kernal_no
			fire_end_flag_o <= 1;
		end
	end
	

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------


endmodule

