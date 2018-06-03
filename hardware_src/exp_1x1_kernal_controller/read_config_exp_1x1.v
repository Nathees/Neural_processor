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

module read_config_exp_1x1(
	clk_i,
	rst_n_i,

	start_i,
	exp_1x1_en_i,
	one_exp1_ker_addr_limit_i,
	exp1_ker_depth_i,
	layer_dimension_i,

	chk_nxt_fire_addr_limt_i,
	exp_1x1_kerl_req_i,
	exp_1x1_kerl_en_o,
	rd_addr_layr_start_o,
	rd_start_addr_flag_o,
	rd_addr_layr_end_o,
	rd_end_addr_flag_o,

	fire_rd_done_flag_o,
	fire_rd_done_lay_flag_o
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

	one_exp1_ker_addr_limit_i 	:- [NO of expand kernals / 4]
	exp1_ker_depth_i 	  		:- [depth - 1]
	layer_dimension_i 			:- [dimnision -1]

	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfiguration Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 						[6:0] 								one_exp1_ker_addr_limit_i;
	input 						[5:0] 								exp1_ker_depth_i;
	input 						[6:0] 								layer_dimension_i;

	// EXPAND 1X1 RAM Control Signals
	input 															chk_nxt_fire_addr_limt_i;
	input 															exp_1x1_kerl_req_i;
	output 	reg 													exp_1x1_kerl_en_o;
	output 	reg					[11:0] 								rd_addr_layr_start_o;
	output 	reg 													rd_start_addr_flag_o;
	output 	reg					[11:0] 								rd_addr_layr_end_o;
	output 	reg 													rd_end_addr_flag_o;

	// FIRE & Control Signals
	output 	reg 													fire_rd_done_flag_o;
	output 	reg 													fire_rd_done_lay_flag_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	reg 						[6:0] 								r_addr_space_per_lay;
	reg 						[5:0] 								r_kernal_per_fire;
	reg 						[6:0] 								r_layer_dim;

	reg 						[6:0] 								r_col_count;
	reg 															r_kernal_flag;
	reg 						[5:0] 								r_kernal_count;
	reg 															r_row_flag;
	reg 						[6:0] 								r_row_count;

	// Data Flag COntrol Signals
	reg 						[3:0]								r_start_addr_flag;
	reg 															r_end_addr_flag;

	reg 						[2:0] 								r_new_config_flag;
	reg 															r_fire_rd_done_flag;


//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Expand 1x1 Enable
	always @(posedge clk_i) begin : EXP_1X1_EN
		if(~rst_n_i) begin
			exp_1x1_kerl_en_o <= 0;
		end 
		else if(start_i) begin
			exp_1x1_kerl_en_o <= exp_1x1_en_i;
		end
	end

	// COnfiguration
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_addr_space_per_lay	<= 0;
			r_kernal_per_fire 		<= 0;
			r_layer_dim 			<= 0;
		end 
		else if(start_i) begin
			r_addr_space_per_lay	<= one_exp1_ker_addr_limit_i;
			r_kernal_per_fire 		<= exp1_ker_depth_i;
			r_layer_dim 			<= layer_dimension_i;
		end
	end

	// New COnfig Flag
	always @(posedge clk_i) begin : NEW_CONFIG_FLAG
		if(~rst_n_i) begin
			r_new_config_flag <= 0;
		end else begin
			r_new_config_flag[0:0] <= start_i;
			r_new_config_flag[1:1] <= r_new_config_flag[0:0];
			r_new_config_flag[2:2] <= r_new_config_flag[1:1];
		end
	end


	// FIRE Column Count
	always @(posedge clk_i) begin : COL_COUNT
		if(~rst_n_i || start_i) begin
			r_col_count <= 0;
		end 
		else if(chk_nxt_fire_addr_limt_i && r_col_count == r_layer_dim && exp_1x1_kerl_req_i) begin
			r_col_count <= 0;
		end 
		else if(chk_nxt_fire_addr_limt_i && exp_1x1_kerl_req_i) begin
			r_col_count <= r_col_count + 1;
		end
	end
	// New Kernal Flag
	always @(posedge clk_i) begin : KERNAL_FLAG
		if(~rst_n_i || start_i) begin
			r_kernal_flag <= 0;
		end 
		else if(exp_1x1_kerl_req_i && r_kernal_flag) begin
			r_kernal_flag <= 0;
		end 
		else if(exp_1x1_kerl_req_i) begin
			r_kernal_flag <= (chk_nxt_fire_addr_limt_i && r_col_count == r_layer_dim);
		end
	end
	// FIRE Kernal Count
	always @(posedge clk_i) begin : KERNAL_COUNT
		if(~rst_n_i || start_i) begin
			r_kernal_count <= 0;
		end 
		else if(r_kernal_flag && r_kernal_count == r_kernal_per_fire && exp_1x1_kerl_req_i) begin
			r_kernal_count <= 0;
		end
		else if(r_kernal_flag && exp_1x1_kerl_req_i) begin
			r_kernal_count <= r_kernal_count + 1;
		end
	end
	// New ROW Flag
	always @(posedge clk_i) begin : ROW_FLAG
		if(~rst_n_i || start_i) begin
			r_row_flag <= 0;
		end 
		else if(exp_1x1_kerl_req_i && r_row_flag) begin
			r_row_flag <= 0;
		end 
		else if(exp_1x1_kerl_req_i) begin
			r_row_flag <= (r_kernal_flag && r_kernal_count == r_kernal_per_fire);
		end
	end
	// FIRE Row Count
	always @(posedge clk_i) begin : ROW_COUNT
		if(~rst_n_i || start_i) begin
			r_row_count <= 0;
		end 
		else if(exp_1x1_kerl_req_i && r_row_flag && r_row_count == r_layer_dim) begin
			r_row_count <= 0;
		end
		else if(r_row_flag && exp_1x1_kerl_req_i) begin
			r_row_count <= r_row_count + 1;
		end
	end

	// Read Address Start
	always @(posedge clk_i) begin : RD_ADDR_START
		if(~rst_n_i || start_i) begin
			rd_addr_layr_start_o <= 0;
		end 
		else if(r_row_flag && exp_1x1_kerl_req_i) begin
			rd_addr_layr_start_o <= 0;
		end 
		else if(r_kernal_flag && exp_1x1_kerl_req_i) begin
			rd_addr_layr_start_o <= rd_addr_layr_start_o + r_addr_space_per_lay;
		end
	end

	// Start Address Flag
	always @(posedge clk_i) begin : START_ADDR_FLAG_TEMP
		if(~rst_n_i || rd_start_addr_flag_o || start_i) begin
			r_start_addr_flag <= 0;
		end  
		else if(exp_1x1_kerl_req_i && chk_nxt_fire_addr_limt_i) begin
			r_start_addr_flag[1:0] <= 2'b11;
			r_start_addr_flag[3:2] <= 0;
		end
		else if(chk_nxt_fire_addr_limt_i) begin
			r_start_addr_flag[0:0] <= 1'b1;
			r_start_addr_flag[3:1] <= 0;
		end
		else if(exp_1x1_kerl_req_i)begin
			r_start_addr_flag[1:1] <= r_start_addr_flag[0:0];
			r_start_addr_flag[2:2] <= r_start_addr_flag[1:1];
			r_start_addr_flag[3:3] <= r_start_addr_flag[2:2];
		end
	end
	always @(posedge clk_i) begin : START_ADDR_FLAG
		if(~rst_n_i || start_i) begin
			rd_start_addr_flag_o <= 0;
		end 
		else if(exp_1x1_kerl_req_i && rd_start_addr_flag_o) begin
			rd_start_addr_flag_o <= 0;
		end 
		else if(exp_1x1_kerl_req_i) begin
			rd_start_addr_flag_o <= r_start_addr_flag[3:3];
		end
	end

	// Read Address End
	always @(posedge clk_i) begin : RD_ADDR_END
		if(~rst_n_i)begin
			rd_addr_layr_end_o <= 0;
		end
		else if(r_end_addr_flag || r_new_config_flag[1:1]) begin
			rd_addr_layr_end_o <= rd_addr_layr_start_o + r_addr_space_per_lay - 1;
		end
	end

	// End Address Flag
	always @(posedge clk_i) begin : END_ADDR_FLAG_TEMP
		if(~rst_n_i || rd_end_addr_flag_o || start_i) begin
			r_end_addr_flag <= 0;
		end 
		else if(exp_1x1_kerl_req_i) begin
			r_end_addr_flag <= rd_start_addr_flag_o;
		end
	end
	always @(posedge clk_i) begin : END_ADDR_FLAG
		if(~rst_n_i || (rd_end_addr_flag_o && exp_1x1_kerl_req_i)) begin
			rd_end_addr_flag_o <= 0;
		end
		else if(r_new_config_flag[1:1]) begin
			rd_end_addr_flag_o <= 1;
		end
		else if(exp_1x1_kerl_req_i) begin
			rd_end_addr_flag_o <= r_end_addr_flag;
		end
	end

	// FIRE Done Flag
	always @(posedge clk_i) begin : FIRE_DONE_FLAG_TEMP
		if(~rst_n_i || start_i) begin
			r_fire_rd_done_flag <= 0;
		end 
		else if(exp_1x1_kerl_req_i && r_row_flag && r_row_count == r_layer_dim) begin
			r_fire_rd_done_flag <= 1;
		end
	end
	always @(posedge clk_i) begin : FIRE_DONE_FLAG
		if(~rst_n_i || start_i || ~exp_1x1_kerl_en_o) begin
			fire_rd_done_flag_o <= 0;
		end  
		else if(exp_1x1_kerl_req_i) begin
			fire_rd_done_flag_o <= r_fire_rd_done_flag;
		end
	end

	// FIRE Done Layer Flag
	always @(posedge clk_i) begin : FIRE_DONE_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			fire_rd_done_lay_flag_o <= 0;
		end
		else if (exp_1x1_kerl_req_i && fire_rd_done_lay_flag_o) begin
			fire_rd_done_lay_flag_o <= 0;
		end 
		else if(exp_1x1_kerl_req_i) begin
			fire_rd_done_lay_flag_o <= (r_kernal_flag && r_row_count == 0 && r_kernal_count != r_kernal_per_fire);
		end
	end


//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------


endmodule

