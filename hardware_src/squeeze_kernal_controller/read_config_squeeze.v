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

module read_config_squeeze(
	clk_i,
	rst_n_i,

	start_i,
	repeat_en_i,
	one_squ_ker_addr_limit_i,
	squ_kernals_i,
	layer_dimension_i,
	tot_repeat_squ_kernals_i,

	chk_nxt_addr_limt_i,
	squeeze_kerl_req_i,
	rd_addr_layr_start_o,
	rd_start_addr_flag_o,
	rd_addr_layr_end_o,
	rd_end_addr_flag_o,

	repeat_en_o,
	fire_rd_done_flag_o,
	fire_rd_done_lay_flag_o,
	conv_rd_done_lay_flag_o
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
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8] 
		squ_kernals_i 				:- [No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
		layer_dimension_i 			:- [dimension - 1]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// Configuration Control Signals
	input 															start_i;
	input 															repeat_en_i;
	input 						[5:0] 								one_squ_ker_addr_limit_i;
	input 						[5:0]								squ_kernals_i;   ///***************** conv
	input 						[6:0] 								layer_dimension_i;
	input 						[15:0] 								tot_repeat_squ_kernals_i;  ///***************** conv

	// Squeeze RAM Control Signals
	input 															chk_nxt_addr_limt_i;
	input 															squeeze_kerl_req_i;
	output 	reg					[10:0] 								rd_addr_layr_start_o;
	output 	reg 													rd_start_addr_flag_o;
	output 	reg					[10:0] 								rd_addr_layr_end_o;
	output 	reg 													rd_end_addr_flag_o;

	// FIRE & CONV Control Signals
	output 	reg 													repeat_en_o;
	output 	reg 													fire_rd_done_flag_o;
	output 	reg 													fire_rd_done_lay_flag_o;
	output 	reg 													conv_rd_done_lay_flag_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------
			
	// COnfig Control Signals
	reg 						[5:0] 								r_addr_space_per_lay;
	reg 						[5:0] 								r_kernal_per_fire;  ///***************** conv
	reg 						[6:0] 								r_layer_dim;
	reg 						[15:0] 								r_tot_repeat_squ_kernals;

	reg 						[2:0] 								r_new_config_flag;


	reg 						[6:0] 								r_col_count;
	reg 															r_kernal_flag;
	reg 						[5:0] 								r_kernal_count;   ///***************** conv
	reg 															r_row_flag;
	reg 						[6:0] 								r_row_count;

	reg 						[15:0] 								r_repeat_tot_lay_count;

	// Data Flag COntrol Signals
	reg 						[3:0] 								r_start_addr_flag;
	reg 															r_end_addr_flag;
	reg 															r_fire_rd_done_flag;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// COnfig
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			repeat_en_o 				<= 0;
			r_addr_space_per_lay 		<= 0;
			r_kernal_per_fire 			<= 0;
			r_layer_dim 				<= 0;
			//r_tot_repeat_squ_kernals	<= 0;
		end 
		else if(start_i) begin
			repeat_en_o 				<= repeat_en_i;
			r_addr_space_per_lay 		<= one_squ_ker_addr_limit_i;
			r_kernal_per_fire 			<= squ_kernals_i;
			r_layer_dim 				<= layer_dimension_i;
			//r_tot_repeat_squ_kernals	<= tot_repeat_squ_kernals_i;
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
		else if(squeeze_kerl_req_i && chk_nxt_addr_limt_i && r_col_count == r_layer_dim) begin
			r_col_count <= 0;
		end 
		else if(squeeze_kerl_req_i && chk_nxt_addr_limt_i) begin
			r_col_count <= r_col_count + 1;
		end
	end

	// New Kernal Flag
	always @(posedge clk_i) begin : KERNAL_FLAG
		if(~rst_n_i || start_i) begin
			r_kernal_flag <= 0;
		end 
		else if(squeeze_kerl_req_i && r_kernal_flag) begin
			r_kernal_flag <= 0;
		end
		else if(squeeze_kerl_req_i) begin
			r_kernal_flag <= (chk_nxt_addr_limt_i && r_col_count == r_layer_dim);
		end
	end

	// FIRE Kernal Count
	always @(posedge clk_i) begin : KERNAL_COUNT
		if(~rst_n_i || start_i) begin
			r_kernal_count <= 0;
		end 
		else if(squeeze_kerl_req_i && r_kernal_flag && r_kernal_count == r_kernal_per_fire) begin
			r_kernal_count <= 0;
		end
		else if(squeeze_kerl_req_i && r_kernal_flag) begin
			r_kernal_count <= r_kernal_count + 1;
		end
	end

	// New ROW Flag
	always @(posedge clk_i) begin : ROW_FLAG
		if(~rst_n_i || start_i) begin
			r_row_flag <= 0;
		end 
		else if(squeeze_kerl_req_i && r_row_flag) begin
			r_row_flag <= 0;
		end
		else if(squeeze_kerl_req_i) begin
			r_row_flag <= (r_kernal_flag && r_kernal_count == r_kernal_per_fire && ~repeat_en_o);
		end
	end

	// FIRE Row Count
	always @(posedge clk_i) begin : ROW_COUNT
		if(~rst_n_i || start_i) begin
			r_row_count <= 0;
		end 
		else if(squeeze_kerl_req_i && r_row_flag && r_row_count == r_layer_dim) begin
			r_row_count <= 0;
		end
		else if(squeeze_kerl_req_i && r_row_flag) begin
			r_row_count <= r_row_count + 1;
		end
	end

	// Read Address Start
	always @(posedge clk_i) begin : RD_ADDR_START
		if(~rst_n_i || r_row_flag || start_i) begin
			rd_addr_layr_start_o <= 0;
		end 
		else if(r_row_flag && squeeze_kerl_req_i) begin
			rd_addr_layr_start_o <= 0;
		end 
		else if(squeeze_kerl_req_i && r_kernal_flag) begin
			rd_addr_layr_start_o <= rd_addr_layr_start_o + r_addr_space_per_lay;
		end
	end

	// Start Address Flag
	always @(posedge clk_i) begin : START_ADDR_FLAG_TEMP
		if(~rst_n_i || rd_start_addr_flag_o || start_i) begin
			r_start_addr_flag <= 0;
		end 
		else if(chk_nxt_addr_limt_i && squeeze_kerl_req_i) begin
			r_start_addr_flag[1:0] <= 2'b11;
			r_start_addr_flag[3:2] <= 0;
		end
		else if(chk_nxt_addr_limt_i) begin
			r_start_addr_flag[0:0] <= 1'b1;
			r_start_addr_flag[3:1] <= 0;
		end
		else if(squeeze_kerl_req_i) begin
			r_start_addr_flag[1:1] <= r_start_addr_flag[0:0];
			r_start_addr_flag[2:2] <= r_start_addr_flag[1:1];
			r_start_addr_flag[3:3] <= r_start_addr_flag[2:2];
		end
	end
	always @(posedge clk_i) begin : START_ADDR_FLAG
		if(~rst_n_i || start_i) begin
			rd_start_addr_flag_o <= 0;
		end 
		else if(rd_start_addr_flag_o && squeeze_kerl_req_i) begin
			rd_start_addr_flag_o <= 0;
		end 
		else if(squeeze_kerl_req_i) begin
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
		else if(squeeze_kerl_req_i)begin
			r_end_addr_flag <= rd_start_addr_flag_o;
		end
	end
	always @(posedge clk_i) begin : END_ADDR_FLAG
		if(~rst_n_i || (squeeze_kerl_req_i && rd_end_addr_flag_o)) begin
			rd_end_addr_flag_o <= 0;
		end 
		else if(r_new_config_flag[1:1]) begin
			rd_end_addr_flag_o <= 1;
		end
		else if(squeeze_kerl_req_i) begin
			rd_end_addr_flag_o <= r_end_addr_flag;
		end
	end

	// FIRE Done Flag
	always @(posedge clk_i) begin : FIRE_DONE_FLAG_TEMP
		if(~rst_n_i || start_i) begin
			r_fire_rd_done_flag <= 0;
		end 
		else if(squeeze_kerl_req_i && r_row_flag && r_row_count == r_layer_dim) begin
			r_fire_rd_done_flag <= 1;
		end
	end
	always @(posedge clk_i) begin : FIRE_DONE_FLAG
		if(~rst_n_i || start_i) begin
			fire_rd_done_flag_o <= 0;
		end  
		else if(squeeze_kerl_req_i && ~repeat_en_o) begin  //  && ~repeat_en_o
			fire_rd_done_flag_o <= r_fire_rd_done_flag;
		end
	end

	// FIRE Done Layer Flag
	always @(posedge clk_i) begin : FIRE_DONE_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			fire_rd_done_lay_flag_o <= 0;
		end
		else if (squeeze_kerl_req_i && fire_rd_done_lay_flag_o) begin
			fire_rd_done_lay_flag_o <= 0;
		end 
		else if(squeeze_kerl_req_i && ~repeat_en_o) begin
			fire_rd_done_lay_flag_o <= (r_kernal_flag && r_row_count == 0 && r_kernal_count != r_kernal_per_fire);
		end
	end

	// CONV Layer Done Flag
	always @(posedge clk_i) begin : CONV_LAY_DONE_FLAG
		if(~rst_n_i || start_i) begin
			conv_rd_done_lay_flag_o <= 0;
		end 
		else if (squeeze_kerl_req_i && conv_rd_done_lay_flag_o) begin
			conv_rd_done_lay_flag_o <= 0;
		end
		else if(squeeze_kerl_req_i) begin
			conv_rd_done_lay_flag_o <= (r_kernal_flag && repeat_en_o);
		end
	end

	// Total repeat layer count
	/*always @(posedge clk_i) begin : TOT_REPEAT_LAYER_COUNT
		if(~rst_n_i || start_i) begin
			r_repeat_tot_lay_count <= 0;
		end 
		else if(squeeze_kerl_req_i && r_kernal_flag && repeat_en_o) begin
			r_repeat_tot_lay_count <= r_repeat_tot_lay_count + 1;
		end
	end*/

	// Last Conv Layer Flag
/*	always @(posedge clk_i) begin : LAST_LAYER_CONV_FLAG
		if(~rst_n_i || start_i) begin
			last_repeat_lay_flag_o <= 0;
		end 
		else if(squeeze_kerl_req_i && repeat_en_o && r_kernal_flag && r_repeat_tot_lay_count == r_tot_repeat_squ_kernals) begin
			last_repeat_lay_flag_o <= 0;//(repeat_en_o && r_kernal_flag && r_repeat_tot_lay_count == r_tot_repeat_squ_kernals);
		end
	end
*/



//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------


endmodule

