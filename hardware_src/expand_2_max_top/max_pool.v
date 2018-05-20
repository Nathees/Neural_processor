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

module max_pool(
	clk_i,
	rst_n_i,

	data_1_i,
	data_2_i,
	data_max_o,
	max_en_i
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

	// Max-pool Control Signals
	input 						[47:0]								data_1_i;
	input 						[47:0]								data_2_i;
	output 	reg					[47:0]								data_max_o;
	input 															max_en_i;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	reg 						[47:0] 								r_data_1;
	reg 						[47:0] 								r_data_2;
	reg 															r_max_en;

	wire 						[10:0] 								w_data_1_1; 
	wire 						[10:0] 								w_data_1_2; 
	wire 						[10:0] 								w_data_1_3; 
	wire 						[10:0] 								w_data_1_4; 

	wire 						[10:0] 								w_data_2_1; 
	wire 						[10:0] 								w_data_2_2; 
	wire 						[10:0] 								w_data_2_3; 
	wire 						[10:0] 								w_data_2_4; 

	wire 						[11:0] 								w_data_max_1; 
	wire 						[11:0] 								w_data_max_2; 
	wire 						[11:0] 								w_data_max_3; 
	wire 						[11:0] 								w_data_max_4; 

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Input Control Signals
	always @(posedge clk_i) begin : INPUT_SIG
		if(~rst_n_i) begin
			r_data_1 <= 0;
			r_data_2 <= 0;
			r_max_en <= 0;
		end else begin
			r_data_1 <= data_1_i;
			r_data_2 <= data_2_i;
			r_max_en <= max_en_i;
		end
	end

	// Data 1
	assign w_data_1_1 = r_data_1[46:36];
	assign w_data_1_2 = r_data_1[34:24];
	assign w_data_1_3 = r_data_1[22:12];
	assign w_data_1_4 = r_data_1[10:00];

	// Data 2
	assign w_data_2_1 = r_data_2[46:36];
	assign w_data_2_2 = r_data_2[34:24];
	assign w_data_2_3 = r_data_2[22:12];
	assign w_data_2_4 = r_data_2[10:00];

	// Data MAX
	assign w_data_max_1[11:11] = 0;
	assign w_data_max_1[10:00] = (w_data_1_1 > w_data_2_1) ? w_data_1_1 : w_data_2_1;

	assign w_data_max_2[11:11] = 0;
	assign w_data_max_2[10:00] = (w_data_1_2 > w_data_2_2) ? w_data_1_2 : w_data_2_2;

	assign w_data_max_3[11:11] = 0;
	assign w_data_max_3[10:00] = (w_data_1_3 > w_data_2_3) ? w_data_1_3 : w_data_2_3;

	assign w_data_max_4[11:11] = 0;
	assign w_data_max_4[10:00] = (w_data_1_4 > w_data_2_4) ? w_data_1_4 : w_data_2_4;
	
	// DATA MAX
	always @(posedge clk_i) begin : DATA_MAX
		if(~rst_n_i) begin
			data_max_o <= 0;
		end 
		else if(r_max_en) begin
			data_max_o[47:36] <= w_data_max_1;
			data_max_o[35:24] <= w_data_max_2;
			data_max_o[23:12] <= w_data_max_3;
			data_max_o[11:00] <= w_data_max_4;
		end
		else begin
			data_max_o <= r_data_1;
		end
	end
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	
endmodule

