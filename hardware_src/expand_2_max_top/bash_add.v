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

module bash_add(
	clk_i,
	rst_n_i,

	bash_1_i,
	bash_2_i,
	bash_3x3_o,
	bash_1x1_o,

	add_en_i,
	skip_neg_en_i
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

	// Add control Signals
	input 					[95:0] 									bash_1_i;
	input 					[63:0] 									bash_2_i;
	output 					[47:0] 									bash_3x3_o;
	output 					[47:0] 									bash_1x1_o;

	input 															add_en_i;
	input 															skip_neg_en_i;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	reg 					[63:0] 									r_bash_2;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Bash 2nd Input
	always @(posedge clk_i) begin : BASH_2ND_IN
		if(~rst_n_i) begin
			r_bash_2 <= 0;
		end else begin
			r_bash_2 <= bash_2_i;
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// EXP 3x3 BASH Add
	add_en_12 float_add_3x3_1_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[95:84]),
		.data_2_i 							({r_bash_2[63:56],4'b0000}),
		.data_sum_o 						(bash_3x3_o[47:36]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
	add_en_12 float_add_3x3_2_inst
	(
		.clk_i 				 				(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[83:72]),
		.data_2_i 							({r_bash_2[55:48],4'b0000}),
		.data_sum_o 						(bash_3x3_o[35:24]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
	add_en_12 float_add_3x3_3_inst
	(
		.clk_i 				 				(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[71:60]),
		.data_2_i 							({r_bash_2[47:40],4'b0000}),
		.data_sum_o 						(bash_3x3_o[23:12]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
	add_en_12 float_add_3x3_4_inst
	(
		.clk_i 				 				(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[59:48]),
		.data_2_i 							({r_bash_2[39:32],4'b0000}),
		.data_sum_o 						(bash_3x3_o[11:00]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);

	// EXP 1x1 BASH Add
	add_en_12 float_add_1x1_1_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[47:36]),
		.data_2_i 							({r_bash_2[31:24],4'b0000}),
		.data_sum_o 						(bash_1x1_o[47:36]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
	add_en_12 float_add_1x1_2_inst
	(
		.clk_i 				 				(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[35:24]),
		.data_2_i 							({r_bash_2[23:16],4'b0000}),
		.data_sum_o 						(bash_1x1_o[35:24]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
	add_en_12 float_add_1x1_3_inst
	(
		.clk_i 				 				(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[23:12]),
		.data_2_i 							({r_bash_2[15:08],4'b0000}),
		.data_sum_o 						(bash_1x1_o[23:12]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
	add_en_12 float_add_1x1_4_inst
	(
		.clk_i 				 				(clk_i),
		.rst_n_i 							(rst_n_i),

		.data_1_i 							(bash_1_i[11:00]),
		.data_2_i 							({r_bash_2[07:00],4'b0000}),
		.data_sum_o 						(bash_1x1_o[11:00]),

		.add_en_i 							(add_en_i),
		.skip_neg_en_i 						(skip_neg_en_i)
	);
endmodule

