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

module exp_3x3_ker_write_cont(
	clk_i,
	rst_n_i,

	fifo_exp_3x3_clr_i,
	fifo_exp_3x3_wr_data_i,
	fifo_exp_3x3_wr_en_i,
	fifo_exp_3x3_data_count_o,

	exp_3x3_ram_wr_data_o,
	exp_3x3_ram_wr_addr_o,
	exp_3x3_ram_1_wr_en_o,
	exp_3x3_ram_2_wr_en_o,
	exp_3x3_ram_3_wr_en_o,
	exp_3x3_ram_4_wr_en_o,

	start_i,
	one_exp3_ker_addr_limit_i,
	exp3_ker_depth_i,
	layer_dimension_i,

	layer_1_ready_o,
	layer_1_done_i,
	layer_2_ready_o,
	layer_2_done_i
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

	// EXPAND 3x3 Kernal FIFO control Signals
	input 															fifo_exp_3x3_clr_i;
	input 					[63:0]									fifo_exp_3x3_wr_data_i;
	input 															fifo_exp_3x3_wr_en_i;
	output 					[7:0] 									fifo_exp_3x3_data_count_o;															

	// EXPAND 3X3 Kernal RAM Write Control Signals
	output 					[71:0] 									exp_3x3_ram_wr_data_o;
	output 	reg 			[6:0] 									exp_3x3_ram_wr_addr_o;
	output 	reg 													exp_3x3_ram_1_wr_en_o;
	output 	reg 													exp_3x3_ram_2_wr_en_o;
	output 	reg 													exp_3x3_ram_3_wr_en_o;
	output 	reg 													exp_3x3_ram_4_wr_en_o;

	// Configuration Control Signals
	input 															start_i;
	input 						[6:0] 								one_exp3_ker_addr_limit_i;
	input 						[5:0] 								exp3_ker_depth_i;
	input 						[6:0]								layer_dimension_i;

	// EXPAND 3x3 RAM Layer Status COntrol Signal
	output 	reg 													layer_1_ready_o;
	input 															layer_1_done_i;
	output 	reg 													layer_2_ready_o;
	input 															layer_2_done_i;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// EXP 3x3 FIFO Read Port Control Signals
	wire 					[63:0] 									w_fifo_rd_data;
	wire 															w_fifo_rd_en;
	reg 															r_start_read;
	wire 															w_fifo_empty;
	reg 					[3:0] 									r_fifo_count;

	// EXP 3x3 SUB FIFO Control Signals
	wire 					[7:0] 									w_fifo_64_data_count;
	reg 															r_fifo_64_wr_en;
	wire 															w_fifo_64_empty;
	wire 					[3:0] 									w_fifo_8_data_count;
	reg 															r_fifo_8_wr_en;
	wire 															w_fifo_8_empty;
	wire 															w_fifo_kernal_rd_en;

	// Expand 3x3 Kernal RAM Write Control Signals
	reg 					[1:0] 									r_ram_select;
	reg 															r_ram_wr_pause;	
	reg 															r_ram_init_sel;
	reg 					[9:0] 									r_tot_addr_count;

	// FIRE Layer Control Signals
	reg  															r_chk_nxt_addr_limt;
	wire 					[6:0] 									w_wr_end_addr;
	wire 															w_fire_end_flag;
	wire 					[9:0] 									w_tot_addr_limit;

	reg 															r_layer_1_ready;
	reg 															r_layer_2_ready;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// FIFO Select
	always @(posedge clk_i) begin : FIFO_SELECT
		if(~rst_n_i || (w_fifo_rd_en && r_fifo_count == 8) || start_i) begin
			r_fifo_count <= 0;
		end 
		else if(w_fifo_rd_en) begin
			r_fifo_count <= r_fifo_count + 1;
		end
	end

	// Start Read 
	always @(posedge clk_i) begin : START_READ
		if(~rst_n_i) begin
			r_start_read <= 0;
		end 
		else if(start_i) begin
			r_start_read <= 1;
		end
	end

	// Main FIFO Read Enable
	assign w_fifo_rd_en = (~w_fifo_empty && w_fifo_64_data_count < 250 && w_fifo_8_data_count < 14 && r_start_read);

	// SUB FIFO Write Enable
	always @(posedge clk_i) begin : SUB_FIFO_WR_EN
		if(~rst_n_i) begin
			r_fifo_64_wr_en <= 0;
			r_fifo_8_wr_en <= 0;
		end else begin
			r_fifo_64_wr_en <= (w_fifo_rd_en && r_fifo_count != 8);
			r_fifo_8_wr_en <= (w_fifo_rd_en && r_fifo_count == 8);
		end
	end

	// RAM Layer Status COntrol Signal
	always @(posedge clk_i) begin : LAYER_1_STATUS
		if(~rst_n_i) begin
			layer_1_ready_o <= 0;
			r_layer_1_ready <= 1;
		end
		else if(layer_1_done_i || start_i) begin
			layer_1_ready_o <= 0;
			r_layer_1_ready <= 0;
		end 
		else if(r_tot_addr_count == w_tot_addr_limit && ~r_ram_init_sel && w_fifo_kernal_rd_en)begin
			layer_1_ready_o <= 1;
			r_layer_1_ready <= 1;
		end
	end
	always @(posedge clk_i) begin : LAYER_2_STATUS
		if(~rst_n_i) begin
			layer_2_ready_o <= 0;
			r_layer_2_ready <= 1;
		end
		else if(layer_2_done_i || start_i) begin
			layer_2_ready_o <= 0;
			r_layer_2_ready <= 0;
		end 
		else if(r_tot_addr_count == w_tot_addr_limit && r_ram_init_sel && w_fifo_kernal_rd_en)begin
			layer_2_ready_o <= 1;
			r_layer_2_ready <= 1;
		end
	end

	// EXP 3x3 FIFO Read Enable
	assign w_fifo_kernal_rd_en = (~w_fifo_64_empty && ~w_fifo_8_empty && (~r_layer_1_ready || ~r_layer_2_ready) && ~w_fire_end_flag);

	// Total Addr Count
	always @(posedge clk_i) begin : TOT_ADDR
		if(~rst_n_i || start_i) begin
			r_tot_addr_count <= 0;
		end 
		else if(r_tot_addr_count == w_tot_addr_limit && w_fifo_kernal_rd_en) begin
			r_tot_addr_count <= 0;
		end 
		else if(w_fifo_kernal_rd_en) begin
			r_tot_addr_count <= r_tot_addr_count + 1;
		end
	end

	// EXP 3x3 RAM Select
	always @(posedge clk_i) begin : RAM_SELECT
		if(~rst_n_i || start_i) begin
			r_ram_select <= 0;
		end 
		else if(w_fifo_kernal_rd_en) begin
			r_ram_select <= r_ram_select + 1;
		end
	end

	// EXP 3x3 Write Enable
	always @(posedge clk_i) begin : RAM_WR_EN
		if(~rst_n_i || w_fire_end_flag) begin
			exp_3x3_ram_1_wr_en_o <= 0;
			exp_3x3_ram_2_wr_en_o <= 0;
			exp_3x3_ram_3_wr_en_o <= 0;
			exp_3x3_ram_4_wr_en_o <= 0;
		end else begin
			exp_3x3_ram_1_wr_en_o <= (w_fifo_kernal_rd_en && r_ram_select == 0);
			exp_3x3_ram_2_wr_en_o <= (w_fifo_kernal_rd_en && r_ram_select == 1);
			exp_3x3_ram_3_wr_en_o <= (w_fifo_kernal_rd_en && r_ram_select == 2);
			exp_3x3_ram_4_wr_en_o <= (w_fifo_kernal_rd_en && r_ram_select == 3);
		end
	end

	// EXP 3x3 RAM Write Address
	always @(posedge clk_i) begin : RAM_WR_ADDR
		if(~rst_n_i || start_i) begin
			exp_3x3_ram_wr_addr_o <= 0;
		end 
		else if(exp_3x3_ram_4_wr_en_o && exp_3x3_ram_wr_addr_o == w_wr_end_addr) begin
			exp_3x3_ram_wr_addr_o <= (r_ram_init_sel) ? 0 : 64;
		end
		else if(exp_3x3_ram_4_wr_en_o) begin
			exp_3x3_ram_wr_addr_o <= exp_3x3_ram_wr_addr_o + 1;
		end
	end

	// Initial Address Select
	always @(posedge clk_i) begin : INIT_ADDR_SEL
		if(~rst_n_i || start_i) begin
			r_ram_init_sel <= 0;
		end 
		else if(exp_3x3_ram_4_wr_en_o && exp_3x3_ram_wr_addr_o == w_wr_end_addr) begin
			r_ram_init_sel <= ~r_ram_init_sel;
		end
	end

	// Check Next Address Limit
	always @(posedge clk_i) begin : CHK_NXT_ADDR_LIMIT
		if(~rst_n_i || start_i) begin
			r_chk_nxt_addr_limt <= 0;
		end else begin
			r_chk_nxt_addr_limt <= (exp_3x3_ram_4_wr_en_o && exp_3x3_ram_wr_addr_o == w_wr_end_addr);
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// EXPAND 3x3 Kernal fifo instantiation
	exp_3x3_kernal_fifo exp_3x3_kernal_fifo_inst
	(
		.clock 									(clk_i),
		.aclr 									(fifo_exp_3x3_clr_i), //(~rst_n_i),

		.data 									(fifo_exp_3x3_wr_data_i),
		.wrreq 									(fifo_exp_3x3_wr_en_i),
		.usedw 									(fifo_exp_3x3_data_count_o),

		.q 										(w_fifo_rd_data),
		.rdreq 									(w_fifo_rd_en),
		.empty 									(w_fifo_empty)
	);

	// EXPAND 3x3 Kernal sub fifo instantiation
	exp_3x3_ker_fifo_64 exp_3x3_ker_fifo_64_inst
	(
		.clock 									(clk_i),
 		.aclr 									(fifo_exp_3x3_clr_i), //(~rst_n_i),

 		.data 									(w_fifo_rd_data),
 		.wrreq 									(r_fifo_64_wr_en),
 		.usedw 									(w_fifo_64_data_count),

 		.q 										(exp_3x3_ram_wr_data_o[71:08]),
 		.rdreq 									(w_fifo_kernal_rd_en),
 		.empty 									(w_fifo_64_empty)
	);

	// EXPAND 3x3 Kernal sub fifo instantiation
	exp_3x3_ker_fifo_8 exp_3x3_ker_fifo_8_inst
	(
 		.aclr 									(fifo_exp_3x3_clr_i), //(~rst_n_i),

 		.wrclk 									(clk_i),
 		.data 									(w_fifo_rd_data),
 		.wrreq 									(r_fifo_8_wr_en),
 		.wrusedw								(w_fifo_8_data_count),

 		.rdclk 									(clk_i),
 		.q 										(exp_3x3_ram_wr_data_o[07:00]),
 		.rdreq 									(w_fifo_kernal_rd_en),
 		.rdempty								(w_fifo_8_empty)
	);

	// Write Configuration for EXPAND 3x3 module Instantiation
	write_config_exp_3x3 write_config_exp_3x3_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.one_exp3_ker_addr_limit_i 				(one_exp3_ker_addr_limit_i),
		.exp3_ker_depth_i 						(exp3_ker_depth_i),
		.layer_dimension_i 						(layer_dimension_i),
	
		.chk_nxt_addr_limt_i 					(r_chk_nxt_addr_limt),
		.wr_end_addr_o 							(w_wr_end_addr),
		.fire_end_flag_o 						(w_fire_end_flag),
		.tot_addr_limit_o 						(w_tot_addr_limit)
	); 

endmodule

