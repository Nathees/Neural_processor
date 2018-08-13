
module int2float8(
	input				clk,
	input 				reset_n,
	input 				cast_,
	input	[15:0] 		int16_in,
	output	[15:0]		out_fl16
	);

	reg 				r_sgn_1;
	wire 	[7:0]		w_neg_magnitude_1;
	wire 	[7:0]		w_magnitude_1;
	reg 	[15:0]		r_magnitude_1;
	reg 				r_cast_1;

	reg 				r_sgn_2;
	reg 	[9:0]		r_mant_2;
	reg  	[4:0]    	r_exp_2;
	reg 				r_cast_2;


	wire 	[15:0] 		w_float16;

//---------------------------------------------------------------------------------
//------------ Pipe Line 1 --------------------------------------------------------
//---------------------------------------------------------------------------------

	always @(posedge clk) begin : proc_r_sgn_1
		if(~reset_n) begin
			r_sgn_1 <= 0;
		end else begin
			r_sgn_1 <= int16_in[15:15];
		end 
	end


	assign w_neg_magnitude_1 = (~(int16_in -1));
	assign w_magnitude_1 = int16_in[15:15] ? w_neg_magnitude_1 ? int16_in[7:0];

	always @(posedge clk) begin : proc_r_magnitude_1
		if(~reset_n) begin
			r_magnitude_1 <= 0;
		end else if(cast_) begin
			r_magnitude_1 <= {8'b0, w_magnitude_1};
		end else begin
			r_magnitude_1 <= int16_in;
		end
	end
	
	always @(posedge clk) begin : proc_r_cast_1
		if(~reset_n) begin
			r_cast_1 <= 0;
		end else begin
			r_cast_1 <= cast_;
		end
	end


//----------------------------------------------------------------------------------
//----------- pipe line 2 ----------------------------------------------------------
//----------------------------------------------------------------------------------

	always @(posedge clk) begin : proc_r_sgn_2
		if(~reset_n) begin
			r_sgn_2 <= 0;
		end else begin
			r_sgn_2 <= r_sgn_1;
		end
	end

	always @(posedge clk) begin : proc_float_out
		if(~reset_n) begin
			r_mant_2 <= 0;
			r_exp <= 0;
		end else if(r_cast_1) begin
			casex(r_magnitude_1[7:0])
				8'b1xxxxxxx : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= r_magnitude_1r_magnitude_1[6:0]; r_exp <= 22; end
				8'b01xxxxxx : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= {r_magnitude_1r_magnitude_1[5:0], 1'b0}; r_exp <= 21; end
				8'b001xxxxx : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= {r_magnitude_1r_magnitude_1[4:0], 2'b0}; r_exp <= 20; end
				8'b0001xxxx : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= {r_magnitude_1r_magnitude_1[3:0], 3'b0}; r_exp <= 19; end
				8'b00001xxx : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= {r_magnitude_1r_magnitude_1[2:0], 4'b0}; r_exp <= 18; end
				8'b000001xx : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= {r_magnitude_1r_magnitude_1[1:0], 5'b0}; r_exp <= 17; end
				8'b0000001x : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= {r_magnitude_1r_magnitude_1[0:0], 6'b0}; r_exp <= 16; end
				8'b00000001 : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= 0; 			 r_exp <= 15; end
				8'b00000000 : begin  r_mant_2[2:0] <= 0; r_mant_2[9:3] <= 0; 			 r_exp <= 0; end
			endcase
		end else begin
			r_exp <= r_magnitude_1[14:10];
			r_mant_2 <= {r_magnitude_1[9:0]};
		end
	end

	always @(posedge clk) begin : proc_r_cast_1
		if(~reset_n) begin
			r_cast_2 <= 0;
		end else begin
			r_cast_2 <= r_cast_1;
		end
	end

//---------------------------------------------------------------------------------
//---------------------- Pipe line 3 ----------------------------------------------
//---------------------------------------------------------------------------------

	assign w_float16 = {r_sgn, r_exp, r_mant};
	assign out_fl16  = w_float16;
	
endmodule // int2float8