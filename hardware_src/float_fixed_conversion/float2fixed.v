module float2fixed (
	input				clk,
	input 				reset_n, 
	input 		[15:0]  float_in,
	output		[43:0]  fixed_out
	);

// wire and regs declarations

	wire 				w_sign;
	wire 		[4:0]	w_exp;
	wire 		[9:0]	w_mantissa;
	wire 		[10:0]  w_with_lead_one;
	wire 		[11:0]	w_mantissa_s;
	wire 		[10:0]	w_mantissa_add;
	


// sign, exponent, manitissa separation
	assign w_sign = float_in[15:15];
	assign w_exp  = float_in[14:10];
	assign w_mantissa = float_in[9:0];
	assign w_with_lead_one = {1'b1, w_mantissa};


	assign w_mantissa_add = ~w_with_lead_one + 1;
	// convering to sign representation
	assign w_mantissa_s = w_sign ? {1'b1, w_mantissa_add} : {1'b0, w_with_lead_one};



	barrel_shifter barrel_shifter_inst(
		.clk(clk),
		.reset_n(reset_n),
		.sign_i(w_sign),
		.shft_amt_i(w_exp),
		.barrel_in(w_mantissa_s),
		.barrel_o(fixed_out)
	);

endmodule // float2fixed


