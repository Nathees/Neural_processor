module sim_float_12 ();

// import "DPI-C" pure function real float_add_c(real a, real b); 

	reg 							clk;
	reg 							reset_n;

	reg 			[11:0] 			fp_a;
	reg 			[11:0] 			fp_b;
	wire 			[11:0] 			fp_x;
	wire 			[11:0] 			fp_x_expected;

	reg 			[11:0] 			fP_expected_p1;
	reg 			[11:0] 			fP_expected_p2;
	reg 			[11:0] 			fP_expected_p3;
	reg 			[11:0] 			fP_expected_p4;


	
	
	real                           		real_a;
	real                           		real_b;
	real                           		real_x_expected;
	real                           		real_x_actual;

	real                           		real_x_expected_p1;
	real                           		real_x_expected_p2;
	real                           		real_x_expected_p3;
	real                           		real_x_expected_p4;

	wire 			[63:0] 				real_a_bits;
	wire 			[63:0] 				real_b_bits;
	wire 			[63:0] 				real_x_bits;
	wire			[63:0]				w_real_x_expected;

	wire								fp_expected_sgn;
	wire			[4:0] 				fp_expected_exp;
	wire 			[5:0]				fp_expected_man;

	


	// module instatiation
	add_12 add_12_inst(
		.clk_i(clk),
		.rst_n_i(reset_n),
		.data_1_i(fp_a),
		.data_2_i(fp_b),
		.data_sum_o(fp_x)
	);
	integer a;


	initial begin
		clk = 0;
		reset_n = 0;
		a = $bits(real_a);

		#40 reset_n = 1;
		
//		$display("%f", real_x);
		#1000000000
		$finish();
	end

    // clock
    always #5 clk = ~clk;

    // random inputs
    always_ff @(posedge clk) begin : proc_ran_inputs
    	if(~reset_n) begin
    		fp_a <= 0;
    		fp_b <= 0;
    	end else begin
    		fp_a <= $urandom_range(4095, 0);
    		fp_b <= $urandom_range(4095, 0);
    	end
    end

    // bits to real
    assign real_a_bits[63:63] = fp_a[10:0] == 0 ? 0: fp_a[11:11];
    assign real_a_bits[62:52] = fp_a[10:0] == 0 ? 0: fp_a[10:6] + 1023 - 15;
    assign real_a_bits[51:0] =  fp_a[10:0] == 0 ? 0: {fp_a[5:0] , 46'b0};

    assign real_b_bits[63:63] = fp_b[10:0] == 0? 0: fp_b[11:11];
    assign real_b_bits[62:52] = fp_b[10:0] == 0? 0: fp_b[10:6] + 1023 - 15;
    assign real_b_bits[51:0] =  fp_b[10:0] == 0? 0: {fp_b[5:0] , 46'b0};

    assign real_x_bits[63:63] = fp_x[11:11];
    assign real_x_bits[62:52] = fp_x[10:6] + 1023 - 15;
    assign real_x_bits[51:0] = {fp_x[5:0] , 46'b0};

    always_ff @(posedge clk) begin : proc_real_a_b
    	if(~reset_n) begin
    		real_a <= 0;
    		real_b <= 0;
    		real_x_expected <= 0;
    		real_x_actual <= 0;
    	end else begin
    		real_a <= $bitstoreal(real_a_bits);
    		real_b <= $bitstoreal(real_b_bits);
    		real_x_expected <= (real_a + real_b);
    		real_x_actual <= $bitstoreal(real_x_bits);
    	end
    end

    always_ff @(posedge clk) begin : proc_fp_expected_pipes
    	if(~reset_n) begin
    		fP_expected_p1 <= 0;
			fP_expected_p2 <= 0;
			fP_expected_p3 <= 0;
			fP_expected_p4 <= 0;
    	end else begin
    		fP_expected_p1 <= fp_x_expected;
			fP_expected_p2 <= fP_expected_p1;
			fP_expected_p3 <= fP_expected_p2;
			fP_expected_p4 <= fP_expected_p3;
    	end
    end

    always_ff @(posedge clk) begin : proc_real_x_expected_pipes
    	if(~reset_n) begin
    		real_x_expected_p1 <= 0;
			real_x_expected_p2 <= 0;
			real_x_expected_p3 <= 0;
			real_x_expected_p4 <= 0;
    	end else begin
    		real_x_expected_p1 <= real_x_expected;
			real_x_expected_p2 <= real_x_expected_p1;
			real_x_expected_p3 <= real_x_expected_p2;
			real_x_expected_p4 <= real_x_expected_p3;
    	end
    end

    // expected real
    assign w_real_x_expected = $realtobits(real_x_expected);
    assign fp_expected_sgn = w_real_x_expected[63:63];
    assign fp_expected_exp = (w_real_x_expected[62:52] > 1039 ) ? 31 : ((w_real_x_expected[62:52] < 1008) ? 0 :(w_real_x_expected[62:52] - 1023 + 15));
    assign fp_expected_man = w_real_x_expected[51:46];
    //assign fp_expected_man = w_real_x_expected[45:45] ? w_real_x_expected[51:46] + 1: w_real_x_expected[51:46];
    assign fp_x_expected = (w_real_x_expected == 0 ) ? 12'b0 :  {fp_expected_sgn, fp_expected_exp, fp_expected_man};

    // error bit
    wire[11:0] diff = (fP_expected_p3 >= fp_x)  ? fP_expected_p3 - fp_x :  fp_x - fP_expected_p3;
    wire error = (diff == 0) ? 0 : 1;

    reg r_error;
    always_ff @(posedge clk) begin : proc_r_error
    	if(~reset_n) begin
    		r_error <= 0;
    	end else begin
    		r_error <= error;
    	end
    end
    always_ff @(posedge clk) begin : proc_print
    	if(reset_n & r_error) begin
    		$display("Mismatch detected\n");
            //$finish();
    	end
    end
	
	
endmodule