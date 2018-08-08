module sim_float2fixed();



//----------------------------------------------------
//----------- Wire and Register declaration ----------
//----------------------------------------------------

	reg 				r_clk;
	reg 				r_reset_n;
	reg 		[15:0]	r_float_in;
	wire 		[43:0]	w_fixed_out;


	wire 				w_sign_g;
	wire 		[4:0]	w_exp_g;
	wire 		[9:0] 	w_mant_g;

	wire 		[42:0] 	w_fixed_mag_g;
	wire 		[43:0] 	w_fixed_twos_g;
	wire 		[43:0] 	w_fixed_out_g;
	reg 		[43:0] 	r_fixed_out_g;


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
			r_float_in <= 0;
		end else begin
			r_float_in <= $urandom_range(65536);
		end
	end

//----------------------------------------------------
//------------- Golden Model--------------------------
//----------------------------------------------------
	
	assign w_sign_g = r_float_in[15:15];
	assign w_exp_g = r_float_in[14:10];
	assign w_mant_g = r_float_in[9:0];

	assign w_fixed_mag_g = ({1'b1, w_mant_g} << w_exp_g);
	assign w_fixed_twos_g = ~w_fixed_mag_g + 1;
	assign w_fixed_out_g = w_sign_g ? w_fixed_twos_g : w_fixed_mag_g;

	always_ff @(posedge r_clk) begin : proc_r_fixed_out_g
		if(~r_reset_n) begin
			r_fixed_out_g <= 0;
		end else begin
			r_fixed_out_g <= w_fixed_out_g;
		end
	end

	assign w_error = r_fixed_out_g != w_fixed_out ? 1'b1 : 1'b0;
//----------------------------------------------------
//-----------instantiating DUT------------------------
//----------------------------------------------------

float2fixed float2fixed_isnt(
		.clk(r_clk),
		.reset_n(r_reset_n), 
		.float_in(r_float_in),
		.fixed_out(w_fixed_out)
	);


endmodule // sim_float2fixed