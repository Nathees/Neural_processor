module sim_fixed2float();



//----------------------------------------------------
//----------- Wire and Register declaration ----------
//----------------------------------------------------

	reg 				r_clk;
	reg 				r_reset_n;
	reg 		[42:0]	r_fixed_in;
	wire 		[15:0]	w_float_out;


	wire 				w_sign_fixed;
	wire 		[41:0] 	w_neg_sgn_adjusted;
	wire 		[41:0] 	w_magnitude_fixed;

	reg 				r_sign_g;
	reg 		[4:0]	r_exp_g;
	reg 		[10:0] 	r_mant_g;

	wire 		[16:0] 	w_float_out_g;
	wire 		[16:0] 	w_float_out_g_add;
	reg 		[15:0] 	r_float_out_g;


	wire 				w_error;

//----------------------------------------------------
//---------- Initialisation ------------------------
//----------------------------------------------------
	initial begin
		r_clk = 0;
		r_reset_n = 0;

		#50 r_reset_n = 1;

	end // initial


//----------------------------------------------------
//---------- clock generation ------------------------
//----------------------------------------------------

always #5 r_clk = ~r_clk;


//---------------------------------------------------
//-------------- Test Vector  -----------------------
//---------------------------------------------------

	always_ff @(posedge r_clk) begin : proc_r_float_in
		if(~r_reset_n) begin
			r_fixed_in <= 0;
		end else begin
			r_fixed_in[15:0] <= $urandom_range(65536);
			r_fixed_in[31:16] <= $urandom_range(65536);
			r_fixed_in[42:32] <= $urandom_range(2048);
		end
	end

//----------------------------------------------------
//------------- Golden Model--------------------------
//----------------------------------------------------
	
	assign w_sign_fixed = r_fixed_in[42:42];
	assign w_neg_sgn_adjusted = ~(r_fixed_in[42:0] - 1) ;
	assign w_magnitude_fixed = w_sign_fixed ? w_neg_sgn_adjusted : r_fixed_in[41:0];
	assign w_sign_g = w_sign_fixed;

	always_ff @(posedge r_clk) begin : proc_r_float_cal
		r_sign_g <= w_sign_g;
		r_exp_g <= 0;
		r_mant_g <= 0;
	  	for(int i = 41; i >= 10; i--) begin
	  	  	if(w_magnitude_fixed[i]) begin
	  	  		r_exp_g <= i - 10;
	  	  		r_mant_g <= i > 11 ? (w_magnitude_fixed >> (i - 11)) : (w_magnitude_fixed >> (i - 10));
	  	  		break;
	  	  	end // if(w_magnitude_fixed[i])
	  	end
	end


	assign w_float_out_g = {r_sign_g, r_exp_g, r_mant_g};
	assign w_float_out_g_add = w_float_out_g + 1;
	always_ff @(posedge r_clk) begin : proc_r_float_out_g
		if(~r_reset_n) begin
			r_float_out_g <= 0;
		end else begin
			r_float_out_g <= w_float_out_g_add[16:1];
		end
	end

	assign w_error = 1'b0; //r_fixed_out_g != w_fixed_out ? 1'b1 : 1'b0;
//----------------------------------------------------
//-----------instantiating DUT------------------------
//----------------------------------------------------

fixed2float fixed2float_inst(
		.clk(r_clk),
		.reset_n(r_reset_n),
		.fixed_in(r_fixed_in),
		.float_out(w_float_out)
	);

endmodule // sim_float2fixed