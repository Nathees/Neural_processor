module fixed2float (
	input 					clk,
	input 					reset_n,
	input 		[42:0] 		fixed_in,
	output 		[15:0]		float_out
	);

//----------------------------------------------------
//----------- Local paramets -------------------------
//----------------------------------------------------
	localparam F_WIDTH = 42;


//----------------------------------------------------
//----------- Wire and Register declaration ----------
//----------------------------------------------------




	wire 					w_sign;
	wire 		[42:0]		w_inverted;
	wire 		[41:0]		w_magnitude;

	// level 0
	reg 		[41:0]		r_magnitude_0;
	reg 					r_sign_0;

	// level 1
	reg 		[41:0]		r_magnitude_1;
	reg 		[10:0]		r_mant_1;
	reg 		[4:0]		r_rxp_1;
	reg 					r_sign_1;
	reg 					r_leading_one_found_1;

	// level 2
	reg 		[41:0]		r_magnitude_2;
	reg 		[10:0]		r_mant_2;
	reg 		[4:0]		r_rxp_2;
	reg 					r_sign_2;
	reg 					r_leading_one_found_2;

	// level 3
	reg 		[41:0]		r_magnitude_3;
	reg 		[10:0]		r_mant_3;
	reg 		[4:0]		r_rxp_3;
	reg 					r_sign_3;
	reg 					r_leading_one_found_3;

	// level 4
	reg 		[41:0]		r_magnitude_4;
	reg 		[10:0]		r_mant_4;
	reg 		[4:0]		r_rxp_4;
	reg 					r_sign_4;
	reg 					r_leading_one_found_4;


	// output 
	wire 		[16:0] 		w_float_17;
	wire 		[16:0] 		w_float_17_add;
	wire 		[15:0]		w_float_16;
	reg 		[15:0] 		r_float_16;


//----------------------------------------------------
//----------- Implementation  ------------------------
//----------------------------------------------------

	// converting to sign and magnitude
	assign w_sign = fixed_in[42:42];
	assign w_inverted = ~fixed_in;
	assign w_magnitude = w_inverted - 1;

	// registering sign and manitude

	always @(posedge clk) begin : proc_level_0
		if(~reset_n) begin
			r_magnitude_0 <= 0;
			r_sign_0 <= 0;
		end else begin
			r_magnitude_0 <= w_magnitude;
			r_sign_0 <= w_sign;
		end
	end


	//----------------------------------------------------
	//----------- magnitude to exp and mantissa ----------
	//----------------------------------------------------

	// level 1
	always @(posedge clk) begin : proc_r_sign_1
		if(~reset_n) begin
			r_sign_1 <= 0;
			r_magnitude_1 <= 0;
		end else begin
			r_magnitude_1 <= r_magnitude_0;
			r_sign_1 <= r_sign_0;
		end
	end

	always @(posedge clk) begin : proc_level_1
		if(~reset_n) begin
			r_mant_1 <= 0;
			r_rxp_1 <= 0;
			r_leading_one_found <= 0;
		end else begin
			 casex(r_magnitude_0)
			 	41'h1xxxxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-2:F_WIDTH-12]; r_rxp_1 <= 31; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h08xxxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-3:F_WIDTH-13]; r_rxp_1 <= 30; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h04xxxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-4:F_WIDTH-14]; r_rxp_1 <= 29; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h02xxxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-5:F_WIDTH-15]; r_rxp_1 <= 28; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h01xxxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-6:F_WIDTH-16]; r_rxp_1 <= 27; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h008xxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-7:F_WIDTH-17]; r_rxp_1 <= 26; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h004xxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-8:F_WIDTH-18]; r_rxp_1 <= 25; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	41'h002xxxxxxxx : begin	r_mant_1 <= r_magnitude_0[F_WIDTH-9:F_WIDTH-19]; r_rxp_1 <= 24; r_leading_one_found_1 <= 1;	end // 43'h4xxxxxxxxxx :
			 	default : begin	r_mant_1 <= 0; r_rxp_1 <= 0; r_leading_one_found_1 <= 0;	end // default :
			 endcase
		end
	end


	// level 2
	always @(posedge clk) begin : proc_r_sign_2
		if(~reset_n) begin
			r_sign_2 <= 0;
			r_magnitude_2 <= 0;
		end else begin
			r_magnitude_2 <= r_magnitude_1;
			r_sign_2 <= r_sign_1;
		end
	end

	always @(posedge clk) begin : proc_level_2
		if(~reset_n) begin
			r_mant_2 <= 0;
			r_rxp_2 <= 0;
			r_leading_one_found_2 <= 0;
		end else if(r_leading_one_found_1) begin
			r_mant_2 <= r_mant_1;
			r_rxp_2 <= r_rxp_1;
			r_leading_one_found_2 <= r_leading_one_found_1;
		end else begin
			 casex(r_magnitude_1)
			 	41'hxx1xxxxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-10:F_WIDTH-20]; r_rxp_2 <= 23; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx08xxxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-11:F_WIDTH-21]; r_rxp_2 <= 22; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx04xxxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-12:F_WIDTH-22]; r_rxp_2 <= 21; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx02xxxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-13:F_WIDTH-23]; r_rxp_2 <= 20; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx01xxxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-14:F_WIDTH-24]; r_rxp_2 <= 19; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx008xxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-15:F_WIDTH-25]; r_rxp_2 <= 18; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx004xxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-16:F_WIDTH-26]; r_rxp_2 <= 17; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxx002xxxxxx : begin	r_mant_2 <= r_magnitude_1[F_WIDTH-17:F_WIDTH-27]; r_rxp_2 <= 16; r_leading_one_found_2 <= 1; end // 43'h4xxxxxxxxxx :
			 	default : begin	r_mant_2 <= 0; r_rxp_2 <= 0; r_leading_one_found_2 <= 0;	end // default :
			 endcase
		end
	end


	// level 3
	always @(posedge clk) begin : proc_r_sign_3
		if(~reset_n) begin
			r_sign_3 <= 0;
			r_magnitude_3 <= 0;
		end else begin
			r_magnitude_3 <= r_magnitude_2;
			r_sign_3 <= r_sign_2;
		end
	end

	always @(posedge clk) begin : proc_level_3
		if(~reset_n) begin
			r_mant_3 <= 0;
			r_rxp_3 <= 0;
			r_leading_one_found_3 <= 0;
		end else if(r_leading_one_found_2) begin
			r_mant_3 <= r_mant_2;
			r_rxp_3 <= r_rxp_2;
			r_leading_one_found_3 <= r_leading_one_found_2;
		end else begin
			 casex(r_magnitude_2)
			 	41'hxxxx1xxxxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-18:F_WIDTH-28]; r_rxp_3 <= 15; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx08xxxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-19:F_WIDTH-29]; r_rxp_3 <= 14; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx04xxxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-20:F_WIDTH-30]; r_rxp_3 <= 13; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx02xxxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-21:F_WIDTH-31]; r_rxp_3 <= 12; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx01xxxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-22:F_WIDTH-32]; r_rxp_3 <= 11; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx008xxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-23:F_WIDTH-33]; r_rxp_3 <= 10; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx004xxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-24:F_WIDTH-34]; r_rxp_3 <= 09; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx002xxxx : begin	r_mant_3 <= r_magnitude_2[F_WIDTH-25:F_WIDTH-35]; r_rxp_3 <= 08; r_leading_one_found_3 <= 1; end // 43'h4xxxxxxxxxx :
			 	default : begin	r_mant_3 <= 0; r_rxp_3 <= 0; r_leading_one_found_3 <= 0;	end // default :
			 endcase
		end
	end


	// level 4
	always @(posedge clk) begin : proc_r_sign_4
		if(~reset_n) begin
			r_sign_4 <= 0;
			r_magnitude_4 <= 0;
		end else begin
			r_magnitude_4 <= r_magnitude_3;
			r_sign_4 <= r_sign_3;
		end
	end

	always @(posedge clk) begin : proc_level_4
		if(~reset_n) begin
			r_mant_4 <= 0;
			r_rxp_4 <= 0;
			r_leading_one_found_4 <= 0;
		end else if(r_leading_one_found_3) begin
			r_mant_4 <= r_mant_3;
			r_rxp_4 <= r_rxp_3;
			r_leading_one_found_4 <= r_leading_one_found_3;
		end else begin
			 casex(r_magnitude_3)
			 	41'hxxxx1xxxxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-26:F_WIDTH-36]; r_rxp_4 <= 07; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx08xxxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-27:F_WIDTH-37]; r_rxp_4 <= 06; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx04xxxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-28:F_WIDTH-38]; r_rxp_4 <= 05; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx02xxxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-29:F_WIDTH-39]; r_rxp_4 <= 04; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx01xxxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-30:F_WIDTH-40]; r_rxp_4 <= 03; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx008xxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-31:F_WIDTH-41]; r_rxp_4 <= 02; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx004xxxx : begin	r_mant_4 <= r_magnitude_3[F_WIDTH-32:F_WIDTH-43]; r_rxp_4 <= 01; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	41'hxxxx002xxxx : begin	r_mant_4 <= {r_magnitude_3[F_WIDTH-33:F_WIDTH-43], 1'b0}; r_rxp_4 <= 00; r_leading_one_found_4 <= 1; end // 43'h4xxxxxxxxxx :
			 	default : begin	r_mant_4 <= 0; r_rxp_4 <= 0; r_leading_one_found_4 <= 0;	end // default :
			 endcase
		end
	end

// concating and output roundoff
	assign w_float_17 = {r_sign_4, r_rxp_4, r_mant_4};
	assign w_float_17_add  = w_float_17 + 1;
	assign w_float_16 = w_float_17_add[16:1];

	always @(posedge clk) begin : proc_r_float_16
		if(~reset_n) begin
			r_float_16 <= 0;
		end else begin
			r_float_16 <= w_float_16;
		end
	end

	assign float_out = r_float_16;

endmodule // fixed2float