
module int2float8(
	input				clk,
	input 				reset_n,
	input 				cast_,
	input	[7:0] 		int8_in,
	output	[7:0]		out_fl8);

	reg 				r_sgn;
	reg 	[2:0]		r_mant;
	reg  	[4:0]    	r_exp;


	wire 	[8:0] 		w_float9;
	wire 	[8:0] 		w_float9_add;
	always @(posedge clk) begin : proc_r_sgn
		if(~reset_n) begin
			r_sgn <= 0;
		end else if(cast_) begin
			r_sgn <= 0;
		end else begin
			r_sgn <= int8_in[7:7];
		end
	end

	always @(posedge clk) begin : proc_float_out
		if(~reset_n) begin
			r_mant <= 0;
			r_exp <= 0;
		end else if(cast_) begin
			casex(int8_in)
				8'b1xxxxxxx : begin  r_mant <= int8_in[6:4]; r_exp <= 22; end
				8'b01xxxxxx : begin  r_mant <= int8_in[5:3]; r_exp <= 21; end
				8'b001xxxxx : begin  r_mant <= int8_in[4:2]; r_exp <= 20; end
				8'b0001xxxx : begin  r_mant <= int8_in[3:1]; r_exp <= 19; end
				8'b00001xxx : begin  r_mant <= int8_in[2:0]; r_exp <= 18; end
				8'b000001xx : begin  r_mant <= {int8_in[1:0], 1'b0}; r_exp <= 17; end
				8'b0000001x : begin  r_mant <= {int8_in[0:0], 2'b0}; r_exp <= 16; end
				8'b00000001 : begin  r_mant <= 0; 			 r_exp <= 15; end
				8'b00000000 : begin  r_mant <= 0; 			 r_exp <= 0; end
			endcase
		end else begin
			r_exp <= int8_in[6:2];
			r_mant <= {int8_in[1:0], 1'b0};
		end
	end

	assign w_float9 = {r_sgn, r_exp, r_mant};
	assign w_float9_add = (w_float9[7:0] == 8'hff) ?  w_float9 : w_float9 + 1; 
	assign out_fl8 = w_float9_add[8:1];

endmodule // int2float8