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

module write_config_squeeze(
	clk_i,
	rst_n_i,

	start_i,
	repeat_en_i,
	tot_squ_ker_addr_limit_i,
	one_squ_ker_addr_limit_i,
	tot_repeat_squ_kernals_i,

	repeat_en_o,
	repeat_flag_o,
	wr_addr_per_fire_o,
	wr_addr_per_layr_o,
	repeat_wr_addr_per_layr_o,
	tot_repeat_squ_kernals_o
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
		tot_squ_ker_addr_limit_i 	:- [(NO of squeeze kernals * depth / 8 ] - 1
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfiguration Control Signals
	input 															start_i;
	input 															repeat_en_i;
	input 						[11:0] 								tot_squ_ker_addr_limit_i;
	input 						[5:0] 								one_squ_ker_addr_limit_i;
	input 						[15:0] 								tot_repeat_squ_kernals_i;

	// FIRE Layer Control Signals
	output 	reg 													repeat_en_o;
	output 	reg 													repeat_flag_o;
	output 	reg					[11:0] 								wr_addr_per_fire_o;
	output  reg 				[5:0] 								wr_addr_per_layr_o;
	output 	reg 				[6:0] 								repeat_wr_addr_per_layr_o;
	output 	reg 				[15:0] 								tot_repeat_squ_kernals_o;									

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// COnfig
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			repeat_en_o 				<= 0;
			wr_addr_per_fire_o 			<= 0;
			wr_addr_per_layr_o 			<= 0;
			tot_repeat_squ_kernals_o 	<= 0;
			repeat_wr_addr_per_layr_o 	<= 0;
		end 
		else if(start_i) begin
			repeat_en_o 				<= repeat_en_i;
			wr_addr_per_fire_o 			<= tot_squ_ker_addr_limit_i;
			wr_addr_per_layr_o 			<= one_squ_ker_addr_limit_i - 1;
			tot_repeat_squ_kernals_o 	<= tot_repeat_squ_kernals_i;
			repeat_wr_addr_per_layr_o 	<= one_squ_ker_addr_limit_i + one_squ_ker_addr_limit_i - 1;
		end
	end

	// Repeat Flag
	always @(posedge clk_i) begin : REPEAT_FLAT
		if(~rst_n_i || repeat_flag_o) begin
			repeat_flag_o <= 0;
		end 
		else if(start_i) begin
			repeat_flag_o <= repeat_en_i;
		end
	end


	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------


endmodule

