module add_en_12(

	input 					clk_i,
	input 					rst_n_i,
	input 					add_en_i,
	input 					skip_neg_en_i,
	input		[11:0] 		data_1_i,
	input 		[11:0]  	data_2_i,
	output		[11:0]		data_sum_o
	);


//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	wire 					w_sgn_a;
	wire 					w_sgn_b;

	wire 		[4:0] 		w_exp_a;
	wire 		[4:0] 		w_exp_b;

	wire		[5:0]		w_man_a;
	wire		[5:0]		w_man_b;


// --------- first pipe line
	reg 					r_sgn_a;
	reg 					r_sgn_b;

	reg 		[4:0] 		r_exp_a;
	reg 		[4:0] 		r_exp_b;

	reg			[5:0]		r_man_a;
	reg			[5:0]		r_man_b;


	wire 				  	w_exp_a_gez;
	wire  		[5:0]      	w_exp_diff;

	reg 				  	r_exp_a_gez;
	reg  		[5:0]       r_exp_diff;

	reg 					r_skip_neg_en_p1;

	reg 					r_a_zero;
	reg 					r_b_zero;

//--------- second pipe line

	reg 		[9:0]		r_shft_mnt_a;
	reg 		[9:0]		r_shft_mnt_b;


	reg    					r_mag_a_geq;
	reg 					r_man_op_type;
	wire 					w_man_op_type;

	reg 		[5:0] 		r_exp_2;

	reg 					r_sgn_a2;
	reg 					r_sgn_b2;

	reg 					r_skip_neg_en_p2;

//---------- third pipe line

	wire 		[9:0] 		w_man_add;
	wire 		[9:0] 		w_man_sub;

	wire 		[9:0] 		w_man_inmt;
	reg 		[8:0] 		r_man_inmt;
	wire 		[8:0] 		w_man_inmt_roundoff;

	reg 		[5:0] 		r_exp_3;

	reg 					r_sgn_3;
	reg 					r_skip_neg_en_p3;

//--------- fourth pipe line

	reg 		[5:0] 		r_exp_shft;
	reg 		[7:0] 		r_new_man;

	reg 		[5:0] 		r_exp_4;
	reg 					r_sgn_4;
	reg 					r_skip_neg_en_p4;

//--------- fifth pipe line
	reg 		[6:0] 		r_man_x; 
	reg 		[4:0]		r_exp_x;
	reg 					r_sgn_x;	

//--------- final_round_off
	wire 		[12:0] 		w_add_out;
	wire 		[11:0] 		w_exp_mant_add1;
	wire 		[10:0]      w_exp_mant;

	// separating input bus
	assign w_sgn_a = data_1_i[11:11];
	assign w_sgn_b = add_en_i ? data_2_i[11:11] : 0;

	assign w_exp_a = data_1_i[10:6];
	assign w_exp_b = add_en_i ? data_2_i[10:6] : 0;

	assign w_man_a = data_1_i[5:0];
	assign w_man_b = add_en_i ? data_2_i[5:0] : 0;

	assign w_exp_a_gez = (w_exp_a > w_exp_b ? 1  : 0 );
	assign w_exp_diff = w_exp_a_gez ? w_exp_a - w_exp_b : w_exp_b - w_exp_a;


	always @(posedge clk_i) begin : proc_
		if(~rst_n_i) begin
			r_sgn_a <= 0;
			r_sgn_b <= 0;

			r_exp_a <= 0;
			r_exp_b <= 0;

			r_man_a <= 0;
			r_man_b <= 0;
		end else begin
			r_sgn_a <= w_sgn_a;
			r_sgn_b <= w_sgn_b;

			r_exp_a <= w_exp_a;
			r_exp_b <= w_exp_b;

			r_man_a <= w_man_a;
			r_man_b <= w_man_b;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_a_gez
		if(~rst_n_i) begin
			r_exp_a_gez <= 0;
		end else begin
			r_exp_a_gez <= w_exp_a_gez;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_diff
		if(~rst_n_i) begin
			r_exp_diff <= 0;
		end else begin
			r_exp_diff <= w_exp_diff;
		end
	end

	always @(posedge clk_i) begin : proc_r_skip_neg_en_p1
		if(~rst_n_i) begin
			r_skip_neg_en_p1 <= 0;
		end else begin
			r_skip_neg_en_p1 <= skip_neg_en_i;
		end
	end

	always @(posedge clk_i) begin : proc_r_a_zero
		if(~rst_n_i) begin
			r_a_zero <= 0;
		end else if(data_1_i[10:0] == 0) begin
			r_a_zero <= 1;
		end else begin
			r_a_zero <= 0;
		end
	end

	always @(posedge clk_i) begin : proc_r_b_zero
		if(~rst_n_i) begin
			r_b_zero <= 0;
		end else if(data_2_i[10:0] == 0 || ~add_en_i) begin
			r_b_zero <= 1;
		end else begin
			r_b_zero <= 0;
		end
	end
// ------------------ second pipe line
	always @(posedge clk_i) begin : proc_r_shft_mnt_a
		if(~rst_n_i || r_a_zero) begin
			r_shft_mnt_a <= 0;
		end else if(r_exp_a_gez)begin
			r_shft_mnt_a <= {1'b0, 1'b1, r_man_a, 2'b0};
		end else  begin
			case(r_exp_diff)
				6'b000000: r_shft_mnt_a <= {1'b0, 1'b1, r_man_a, 2'b0};
				6'b000001: r_shft_mnt_a <= {1'b0, 1'b0, 1'b1, r_man_a[5:0], 1'b0};
				6'b000010: r_shft_mnt_a <= {1'b0, 2'b0, 1'b1, r_man_a[5:0]};
				6'b000011: r_shft_mnt_a <= {1'b0, 3'b0, 1'b1, r_man_a[5:2], r_man_a[1:1] | (w_man_op_type & |(r_man_a[0:0]))};
				6'b000100: r_shft_mnt_a <= {1'b0, 4'b0, 1'b1, r_man_a[5:3], r_man_a[2:2] | (w_man_op_type & |(r_man_a[1:0]))};
				6'b000101: r_shft_mnt_a <= {1'b0, 5'b0, 1'b1, r_man_a[5:4], r_man_a[3:3] | (w_man_op_type & |(r_man_a[2:0]))};
				6'b000110: r_shft_mnt_a <= {1'b0, 6'b0, 1'b1, r_man_a[5:5], r_man_a[4:4] | (w_man_op_type & |(r_man_a[3:0]))};
				6'b000111: r_shft_mnt_a <= {1'b0, 7'b0, 1'b1, r_man_a[5:5] | (w_man_op_type & |(r_man_a[5:0]))};
				default	 : r_shft_mnt_a <= {1'b0, 8'b0, w_man_op_type};
			endcase // r_exp_diff
		end
	end

	always @(posedge clk_i) begin : proc_r_shft_mnt_b
		if(~rst_n_i || r_b_zero) begin
			r_shft_mnt_b <= 0;
		end else if(~r_exp_a_gez)begin
			r_shft_mnt_b <= {1'b0, 1'b1, r_man_b, 2'b0};
		end else  begin
			case(r_exp_diff)
				6'b000000: r_shft_mnt_b <= {1'b0, 1'b1, r_man_b, 2'b0};
				6'b000001: r_shft_mnt_b <= {1'b0, 1'b0, 1'b1, r_man_b[5:0], 1'b0};
				6'b000010: r_shft_mnt_b <= {1'b0, 2'b0, 1'b1, r_man_b[5:0]};
				6'b000011: r_shft_mnt_b <= {1'b0, 3'b0, 1'b1, r_man_b[5:2], r_man_b[1:1] | (w_man_op_type & |(r_man_b[0:0]))};
				6'b000100: r_shft_mnt_b <= {1'b0, 4'b0, 1'b1, r_man_b[5:3], r_man_b[2:2] | (w_man_op_type & |(r_man_b[1:0]))};
				6'b000101: r_shft_mnt_b <= {1'b0, 5'b0, 1'b1, r_man_b[5:4], r_man_b[3:3] | (w_man_op_type & |(r_man_b[2:0]))};
				6'b000110: r_shft_mnt_b <= {1'b0, 6'b0, 1'b1, r_man_b[5:5], r_man_b[4:4] | (w_man_op_type & |(r_man_b[3:0]))};
				6'b000111: r_shft_mnt_b <= {1'b0, 7'b0, 1'b1, r_man_b[5:5] | (w_man_op_type & |(r_man_b[5:0]))};
				default	 : r_shft_mnt_b <= {1'b0, 8'b0, w_man_op_type};
			endcase // r_exp_diff
		end
	end

	always @(posedge clk_i) begin : proc_r_mag_a_geq
		if(~rst_n_i) begin
			r_mag_a_geq <= 0;
		end else begin
			r_mag_a_geq <= (r_exp_a_gez || (r_exp_a == r_exp_b && r_man_a >= r_man_b)) ? 1 : 0;
		end
	end

	assign w_man_op_type = (r_sgn_a ^ r_sgn_b);
	always @(posedge clk_i) begin : proc_r_man_op_type
		if(~rst_n_i) begin
			r_man_op_type <= 0;
		end else begin
			r_man_op_type <= w_man_op_type;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_2
		if(~rst_n_i) begin
			r_exp_2 <= 0;
		end else if(r_exp_a_gez)begin
			r_exp_2 <= r_exp_a;
		end else begin
			r_exp_2 <= r_exp_b;
		end
	end

	always @(posedge clk_i) begin : proc_r_sgn_a2
		if(~rst_n_i) begin
			r_sgn_a2 <= 0;
			r_sgn_b2 <= 0;
		end else begin
			r_sgn_a2 <= r_sgn_a;
			r_sgn_b2 <= r_sgn_b;
		end
	end

	always @(posedge clk_i) begin : proc_r_skip_neg_en_p2
		if(~rst_n_i) begin
			r_skip_neg_en_p2 <= 0;
		end else begin
			r_skip_neg_en_p2 <= r_skip_neg_en_p1;
		end
	end

	//-------------- third pipline
	assign w_man_add = r_shft_mnt_a + r_shft_mnt_b;
	assign w_man_sub = (r_mag_a_geq ? r_shft_mnt_a - r_shft_mnt_b : r_shft_mnt_b - r_shft_mnt_a);


	assign w_man_inmt = r_man_op_type ? w_man_sub : w_man_add;
	always @(posedge clk_i) begin : proc_r_man_inmt
		if(~rst_n_i) begin
			r_man_inmt <= 0;
		end else begin
			r_man_inmt <= w_man_inmt[9:1];
		end
	end

	always @(posedge clk_i) begin : proc_r_sgn_3
		if(~rst_n_i) begin
			r_sgn_3 <= 0;
		end else if(r_mag_a_geq)begin
			r_sgn_3 <= r_sgn_a2;
		end else begin
			r_sgn_3 <= r_sgn_b2;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_3
		if(~rst_n_i) begin
			r_exp_3 <= 0;
		end else begin
			r_exp_3 <= r_exp_2;
		end
	end

	always @(posedge clk_i) begin : proc_r_skip_neg_en_p3
		if(~rst_n_i) begin
			r_skip_neg_en_p3 <= 0;
		end else begin
			r_skip_neg_en_p3 <= r_skip_neg_en_p2;
		end
	end

	//----------- fourth pipeline

	assign w_man_inmt_roundoff = r_man_inmt[0] ? r_man_inmt +1 : r_man_inmt;
	always @(posedge clk_i) begin : proc_r_exp_shft
		if(~rst_n_i) begin
			r_exp_shft <= 0;
			r_new_man <= 0;
		end else begin
			casex(r_man_inmt)
				9'b1xxxxxxxx : begin r_exp_shft <= 16; r_new_man <= r_man_inmt[7:1]; end
				9'b01xxxxxxx : begin r_exp_shft <= 15; r_new_man <= r_man_inmt[6:0]; end
				9'b001xxxxxx : begin r_exp_shft <= 14; r_new_man <= {r_man_inmt[5:0], 1'b0}; end
				9'b0001xxxxx : begin r_exp_shft <= 13; r_new_man <= {r_man_inmt[4:0], 2'b0}; end
				9'b00001xxxx : begin r_exp_shft <= 12; r_new_man <= {r_man_inmt[3:0], 3'b0}; end
				9'b000001xxx : begin r_exp_shft <= 11; r_new_man <= {r_man_inmt[2:0], 4'b0}; end
				9'b0000001xx : begin r_exp_shft <= 10; r_new_man <= {r_man_inmt[1:0], 5'b0}; end
				9'b00000001x : begin r_exp_shft <= 9; r_new_man <=  {r_man_inmt[0:0], 6'b0}; end
				9'b000000001 : begin r_exp_shft <= 8; r_new_man <=  {7'b0}; end
				9'b000000000 : begin r_exp_shft <= 0; r_new_man <=  {7'b0}; end
				default : begin r_exp_shft <= 0; r_new_man <=  {7'b0}; end
			endcase // r_man_inmt
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_4
		if(~rst_n_i) begin
			r_exp_4 <= 0;
		end else begin
			r_exp_4 <= r_exp_3;
		end
	end

	always @(posedge clk_i) begin : proc_r_sgn_4
		if(~rst_n_i) begin
			r_sgn_4 <= 0;
		end else begin
			r_sgn_4 <= r_sgn_3;
		end
	end

	always @(posedge clk_i) begin : proc_r_skip_neg_en_p4
		if(~rst_n_i) begin
			r_skip_neg_en_p4 <= 0;
		end else begin
			r_skip_neg_en_p4 <= r_skip_neg_en_p3;
		end
	end

	//-------------------- fifth pipeline

	always @(posedge clk_i) begin : proc_r_man_x
		if(~rst_n_i || r_exp_shft == 0 || (r_skip_neg_en_p4 & r_sgn_4) || (r_exp_4 < (15 - r_exp_shft)) && ~r_exp_shft[4]) begin
			r_man_x <= 0;
			r_sgn_x <= 0;
		end else begin
			r_man_x <= r_new_man;
			r_sgn_x <= r_sgn_4;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_x
		if(~rst_n_i || r_exp_shft == 0 || (r_skip_neg_en_p4 & r_sgn_4) || (r_exp_4 < (15 - r_exp_shft)) && ~r_exp_shft[4]) begin
			r_exp_x <= 0;
		end else if((r_exp_shft[4] && r_exp_4 == 31) ) begin
			r_exp_x <= r_exp_4;
		end else begin
			r_exp_x <= r_exp_4 + r_exp_shft - 15;
		end
	end

	assign w_add_out = {r_sgn_x, r_exp_x, r_man_x[6:0]};
	assign w_exp_mant_add1 = w_add_out[11:0] + 1;
	assign w_exp_mant = w_add_out[11:1] == 11'h7ff ? w_add_out[11:1] : w_exp_mant_add1[11:1];
	assign data_sum_o = {r_sgn_x, w_exp_mant};

endmodule