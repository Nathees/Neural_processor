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

module write_config_exp_1x1(
	clk_i,
	rst_n_i,

	start_i,
	exp_1x1_en_i,
	tot_exp1_ker_addr_limit_i,
	one_exp1_ker_addr_limit_i,
	
	exp_1x1_en_o,
	wr_addr_per_fire_o,
	wr_addr_per_layr_o
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

	// COnfiguration Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 						[11:0] 								tot_exp1_ker_addr_limit_i;
	input 						[6:0] 								one_exp1_ker_addr_limit_i;

	// FIRE Layer Control Signals
	output 	reg 													exp_1x1_en_o;
	output 	reg					[11:0] 								wr_addr_per_fire_o;
	output  reg 				[6:0] 								wr_addr_per_layr_o;	

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Exp 1x1 Enable
	always @(posedge clk_i) begin : EXP_1X1_EN
		if(~rst_n_i) begin
			exp_1x1_en_o <= 0;
		end 
		else if(start_i)begin
			exp_1x1_en_o <= exp_1x1_en_i;
		end
	end

	// COnfiguration COntrol Signals
	always @(posedge clk_i) begin : CONFIG_SIGNAL
		if(~rst_n_i) begin
			wr_addr_per_fire_o 		<= 0;
			wr_addr_per_layr_o 		<= 0;
		end 
		else if(start_i) begin
			wr_addr_per_fire_o 		<= tot_exp1_ker_addr_limit_i;
			wr_addr_per_layr_o 		<= one_exp1_ker_addr_limit_i - 1;
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------


endmodule

