module sim_float2fixed();



//----------------------------------------------------
//----------- Wire and Register declaration ----------
//----------------------------------------------------

	reg 				r_clk;
	reg 				r_reset_n;
	reg 		[15:0]	r_float_in;
	wire 		[43:0]	w_fixed_out;


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
			r_float_in <= $urandom_range(4096);
		end
	end


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