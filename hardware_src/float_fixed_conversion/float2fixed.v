module float2fixed (
	input				clk,
	input 				reset_n, 
	input 		[15:0]  float_in,
	output		[47:0]  fixed_out
	);

// wire and regs declarations

	wire 				w_sign;
	wire 		[4:0]	w_exp;
	wire 		[9:0]	w_mantissa;

	wire 		[10:0]  w_barrel_in;


// sign, exponent, manitissa separation
	assign w_sign = float_in[15:15];
	assign w_exp  = float_in[14:10];
	assign w_mantissa = float_in[9:0];

// 
	assign w_barrel_in = {1'b1, w_mantissa}

	barrel_shifter (
		.clk(clk),
		.reset_n(reset_n),
		.shft_amt_i(w_exp),
		.barrel_in(w_barrel_in),
		.barrel_o(fixed_out)
	);

endmodule // float2fixed


