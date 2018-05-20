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

module exp_1x1_ker_write_cont(
	clk_i,
	rst_n_i,

	fifo_exp_1x1_clr_i,
	fifo_exp_1x1_wr_data_i,
	fifo_exp_1x1_wr_en_i,
	fifo_exp_1x1_data_count_o,

	exp_1x1_ram_wr_data_o,
	exp_1x1_ram_wr_addr_o,
	exp_1x1_ram_wr_en_o,

	start_i,
	exp_1x1_en_i,
	tot_exp1_ker_addr_limit_i,
	one_exp1_ker_addr_limit_i,

	exp_1x1_layer_ready_no_o
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

	tot_exp1_ker_addr_limit_i :- [(NO of expand kernals * depth) / 4 ] - 1
	one_exp1_ker_addr_limit_i :- [NO of expand kernals / 4]

	*/
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i; 

	// EXPAND 1X1 Kernal FIFO control Signals
	input 															fifo_exp_1x1_clr_i;
	input 					[63:0]									fifo_exp_1x1_wr_data_i;
	input 															fifo_exp_1x1_wr_en_i;
	output 					[7:0] 									fifo_exp_1x1_data_count_o;															

	// EXPAND 1X1 Kernal RAM Write Control Signals
	output 					[31:0] 									exp_1x1_ram_wr_data_o;
	output 	reg 			[11:0] 									exp_1x1_ram_wr_addr_o;
	output 	reg 				 									exp_1x1_ram_wr_en_o;

	// COnfiguration Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 					[11:0] 									tot_exp1_ker_addr_limit_i;
	input 					[6:0] 									one_exp1_ker_addr_limit_i;

	// EXPAND 1X1 Kernal RAM Read Control Signals
	output 	reg 			[6:0] 									exp_1x1_layer_ready_no_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze FIFO Read Port Control Signals
	wire 															w_fifo_rd_en;
	wire 															w_fifo_empty;

	// Squeeze Kernal RAM Write Contro Signals
	reg 															r_ram_wr_pause;	
	reg 					[11:0] 									r_addr_count;

	// FIRE Layer Control Signals
	wire 															w_exp_1x1_en;
	wire					[11:0] 									w_wr_addr_per_fire;
	wire 					[6:0] 									w_wr_addr_per_layr;
	reg 					[6:0] 									r_kernal_count;	

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// EXP 1X1 FIFO Read Enable
	assign w_fifo_rd_en = (~w_fifo_empty && ~r_ram_wr_pause && w_exp_1x1_en);

	// EXP 1X1 RAM Write Address
	always @(posedge clk_i) begin : RAM_WR_ADDR
		if(~rst_n_i || start_i) begin
			exp_1x1_ram_wr_addr_o <= 0;
		end 
		else if(exp_1x1_ram_wr_en_o) begin
			exp_1x1_ram_wr_addr_o <= exp_1x1_ram_wr_addr_o + 1;
		end
	end
	always @(posedge clk_i) begin : ADDR_COUNT
		if(~rst_n_i || start_i) begin
			r_addr_count <= 0;
		end 
		else if(w_fifo_rd_en) begin
			r_addr_count <= r_addr_count + 1;
		end
	end

	// EXP 1X1 RAM Write Enable
	always @(posedge clk_i) begin : RAM_WR_ENABLE
		if(~rst_n_i) begin
			exp_1x1_ram_wr_en_o <= 0;
		end else begin
			exp_1x1_ram_wr_en_o <= w_fifo_rd_en;
		end
	end

	// EXP 1X1 RAM Write Pause
	always @(posedge clk_i) begin : RAM_WR_PAUSE
		if(~rst_n_i) begin
			r_ram_wr_pause <= 1;
		end
		else if(start_i) begin
			r_ram_wr_pause <= 0;
		end 
		else if(r_addr_count == w_wr_addr_per_fire && ~w_fifo_empty) begin
			r_ram_wr_pause <= 1;
		end
	end

	// Kernal Count within a layer
	always @(posedge clk_i) begin : KERNAL_COUNT
		if(~rst_n_i || start_i) begin
			r_kernal_count <= 0;
		end 
		else if(exp_1x1_ram_wr_en_o && r_kernal_count == w_wr_addr_per_layr) begin
			r_kernal_count <= 0;
		end
		else if(exp_1x1_ram_wr_en_o) begin
			r_kernal_count <= r_kernal_count + 1;
		end
	end

	// EXPAND 1X1 Layer Ready Number
	always @(posedge clk_i) begin : EXP_1X1_LAYER_READY_NO
		if(~rst_n_i || start_i) begin
			exp_1x1_layer_ready_no_o <= 0;
		end 
		else if(exp_1x1_ram_wr_en_o && r_kernal_count == w_wr_addr_per_layr) begin
			exp_1x1_layer_ready_no_o <= exp_1x1_layer_ready_no_o + 1;
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// EXPAND 1X1 Kernal fifo instantiation
	exp_1x1_kernal_fifo exp_1x1_kernal_fifo_inst
	(
		.aclr 									(fifo_exp_1x1_clr_i),

		.wrclk 									(clk_i),
		.data 									(fifo_exp_1x1_wr_data_i),
		.wrreq 									(fifo_exp_1x1_wr_en_i),
		.wrusedw 								(fifo_exp_1x1_data_count_o),

		.rdclk 									(clk_i),
		.rdreq 									(w_fifo_rd_en),
		.q 										(exp_1x1_ram_wr_data_o),
		.rdempty 								(w_fifo_empty)
	);

	// Write Configuration for EXPAND 1x1 module Instantiation
	write_config_exp_1x1 write_config_exp_1x1_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.exp_1x1_en_i 							(exp_1x1_en_i),
		.tot_exp1_ker_addr_limit_i 				(tot_exp1_ker_addr_limit_i),
		.one_exp1_ker_addr_limit_i 				(one_exp1_ker_addr_limit_i),
	
		.exp_1x1_en_o 							(w_exp_1x1_en),
		.wr_addr_per_fire_o 					(w_wr_addr_per_fire),
		.wr_addr_per_layr_o 					(w_wr_addr_per_layr)
	);

endmodule

