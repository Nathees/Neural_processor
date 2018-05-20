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

module temp_mult(
	clk_i,
	rst_n_i,

	data_1_i,
	data_2_i,
	data_mult_o
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

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	input 				[11:0] 										data_1_i;
	input 				[11:0] 										data_2_i;
	output 	reg 		[11:0] 										data_mult_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------
			
	reg 				[11:0] 										r_mult_1;
	reg 				[11:0] 										r_mult_2;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			r_mult_1 <= 0;
			r_mult_2 <= 0;
			data_mult_o <= 0;
		end 
		else begin
			r_mult_1[11:4] <= data_1_i[11:4] * data_2_i[11:4];
			r_mult_1[3:0] <= 0;
			r_mult_2 <= r_mult_1;
			data_mult_o <= r_mult_2;
		end
	end


//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	
endmodule

