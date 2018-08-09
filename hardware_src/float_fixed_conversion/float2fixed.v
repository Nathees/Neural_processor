module float2fixed (
	input				clk,
	input 				reset_n, 
	input 		[15:0]  float_in,
	output		[43:0]  fixed_out
	);

// wire and regs declarations

	wire 				w_sign;
	wire 		[4:0]	w_exp;
	wire 				w_zero;
	wire 		[9:0]	w_mantissa;
	wire 		[10:0]  w_with_lead_one;
	wire 		[11:0]	w_mantissa_s;
	wire 		[10:0]	w_mantissa_add;

	wire 		[11:0]	w_barrel_mant;
	wire 				w_barrel_sign;
	wire 		[4:0]	w_barrel_exp;
	


// sign, exponent, manitissa separation
	assign w_exp  = float_in[14:10];
	assign w_zero = float_in[14:0] == 0 ? 1 : 0;
	assign w_sign = float_in[15:15];
	assign w_mantissa = float_in[9:0];
	assign w_with_lead_one = {1'b1, w_mantissa};


	assign w_mantissa_add = ~w_with_lead_one + 1;
	// convering to sign representation
	assign w_mantissa_s = w_sign ? {1'b1, w_mantissa_add} : {1'b0, w_with_lead_one};


	assign w_barrel_mant = w_zero ? 12'b0 : w_mantissa_s;
	assign w_barrel_sign = w_zero ? 0 : w_sign;
	assign w_barrel_exp = w_exp;

	barrel_shifter barrel_shifter_inst(
		.clk(clk),
		.reset_n(reset_n),
		.sign_i(w_barrel_sign),
		.shft_amt_i(w_barrel_exp),
		.barrel_in(w_barrel_mant),
		.barrel_o(fixed_out)
	);

endmodule // float2fixed


