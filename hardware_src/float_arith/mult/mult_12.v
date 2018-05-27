module mult_12(

	input 					clk_i,
	input 					rst_n_i,
	input		[11:0] 		data_1_i,
	input 		[11:0]  	data_2_i,
	output		[11:0]		data_mult_o
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

	wire        [6:0]       w_mult_a;
	wire        [6:0]       w_mult_b;
	wire        [7:0]       w_mult_ab;
	
	wire 		[13:0] 		w_mult_result;

	//------------ first pipeline
	reg 					r_sgn_x1;
	reg 		[6:0]  		r_exp_x1;
	reg 					r_multiply_by_zero_1;

	//------------ second pipeline
	reg 					r_sgn_x2;
	reg 		[5:0]  		r_exp_x2;

	reg 					r_incr_exp_flag;
	reg 					r_multiply_by_zero_2;
	reg 					r_zero_result_flag;
	reg 					r_exp_eq_14;

	//------------ third satge pipe line
	reg 		[5:0] 		r_mant_x;
	reg 		[4:0]  		r_exp_x;
	reg 					r_sgn_x;


	// separating input bus
	assign w_sgn_a = data_1_i[11:11];
	assign w_sgn_b = data_2_i[11:11];

	assign w_exp_a = data_1_i[10:6];
	assign w_exp_b = data_2_i[10:6];

	assign w_man_a = data_1_i[5:0];
	assign w_man_b = data_2_i[5:0];

	assign w_mult_a = {1'b1, w_man_a};
	assign w_mult_b = {1'b1, w_man_b};

	// altera instatiation
	multiplier_7x7 multiplier_7x7_inst(
	.clock			(clk_i),
	.dataa			(w_mult_a),
	.datab			(w_mult_b),
	.result			(w_mult_result)
	);
	assign w_mult_ab = w_mult_result[13:6];

	// xilinx instatiation
	 // multiplier_7x7 multiplier_7x7_inst
  //  	(
	 //     .CLK			     (clk_i),
	 //     .A 				(w_mult_a),
	 //     .B 				(w_mult_b),
	 //     .P 				(w_mult_result)
  //  	);

	// assuming two stage pipe line for mutiplier
	//----------- first pipe line
	always @(posedge clk_i) begin : proc_r_sgn_x1
		if(~rst_n_i) begin
			r_sgn_x1 <= 0;
		end else begin
			r_sgn_x1 <= w_sgn_a ^ w_sgn_b;
		end
	end

	always @(posedge clk_i) begin : proc_r_man_x1
		if(~rst_n_i) begin
			r_exp_x1 <= 0;
		end else begin
			r_exp_x1 <= w_exp_a + w_exp_b;
		end
	end

	
	always @(posedge clk_i) begin
		if(~rst_n_i) begin
			r_multiply_by_zero_1 <= 0;
		end else if( data_1_i == 0 || data_2_i == 0)begin
			r_multiply_by_zero_1 <= 1;
		end else begin
			r_multiply_by_zero_1 <= 0;
		end
	end

	//------ second pipe line
	always @(posedge clk_i) begin : proc_r_sgn_x2
		if(~rst_n_i) begin
			r_sgn_x2 <= 0;
		end else begin
			r_sgn_x2 <= r_sgn_x1;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_x2
		if(~rst_n_i) begin
			r_exp_x2 <= 0;
		end else if(r_exp_x1 >= 46) begin
			r_exp_x2 <= 31;
		end else if(r_exp_x1 >= 15) begin
			r_exp_x2 <= r_exp_x1 - 15;   // subtracting bias
		end else begin
			r_exp_x2 <= 0;
		end
	end

	
	always @(posedge clk_i) begin
		if(~rst_n_i) begin
			r_incr_exp_flag <= 0;
		end else if(r_exp_x1 >= 14 && r_exp_x1 < 46) begin
			r_incr_exp_flag <= 1;
		end else begin
			r_incr_exp_flag <= 0;
		end
	end 

	
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			r_multiply_by_zero_1 <= 0;
		end else begin
			r_multiply_by_zero_2 <= r_multiply_by_zero_1;
		end
	end

	always @(posedge clk_i) begin : proc_r_zero_result_flag
		if(~rst_n_i) begin
			r_zero_result_flag <= 0;
		end else if(r_exp_x1 <= 14) begin
			r_zero_result_flag <= 1;
		end else begin
			r_zero_result_flag <= 0;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_eq_14
		if(~rst_n_i) begin
			r_exp_eq_14 <= 0;
		end else if(r_exp_x1 == 14)begin
			r_exp_eq_14 <= 1;
		end else begin
			r_exp_eq_14 <= 0;
		end
	end

	//----- third stage pipe line
	always @(posedge clk_i) begin : proc_r_mant_x
		if(~rst_n_i || r_multiply_by_zero_2 || (r_zero_result_flag & ~(r_incr_exp_flag & w_mult_ab[7:7]))) begin
			r_mant_x <= 0;
			r_sgn_x <= 0;
		end else if(w_mult_ab[7:7]) begin
			r_mant_x <= w_mult_ab[6:1];
			r_sgn_x <= r_sgn_x2;
		end else begin
			r_mant_x <= w_mult_ab[5:0];
			r_sgn_x <= r_sgn_x2;
		end
	end

	always @(posedge clk_i) begin : proc_r_exp_x
		if(~rst_n_i || r_multiply_by_zero_2 || (r_zero_result_flag & ~(r_incr_exp_flag & w_mult_ab[7:7]))) begin
			r_exp_x <= 0;
		end else if(w_mult_ab[7:7] && r_incr_exp_flag && ~r_exp_eq_14) begin
			r_exp_x <= r_exp_x2 + 1;
		end else begin
			r_exp_x <= r_exp_x2;
		end
	end

	assign data_mult_o = {r_sgn_x, r_exp_x, r_mant_x};

endmodule // float_mult_12