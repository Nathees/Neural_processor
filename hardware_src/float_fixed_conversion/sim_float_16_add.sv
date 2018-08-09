module sim_float_add();

// import "DPI-C" pure function real float_add_c(real a, real b); 

	reg 							clk;
	reg 							reset_n;

	reg 			[15:0] 			fp_a;
	reg 			[15:0] 			fp_b;
	wire 			[15:0] 			fp_x;

	wire 	signed	[42:0]			w_fixed_a;
	wire 	signed	[42:0]			w_fixed_b;
	wire	signed 	[42:0]			w_fixed_result_inmt;
	wire	signed 	[42:0]			w_fixed_result;


	wire 			[16:0] 			fp_x_expected_inmt;
	wire 			[16:0] 			fp_x_expected_inmt_1;
	wire 			[15:0] 			fp_x_expected;

	reg 			[15:0] 			fP_expected_p1;
	reg 			[15:0] 			fP_expected_p2;
	reg 			[15:0] 			fP_expected_p3;
	reg 			[15:0] 			fP_expected_p4;
	reg 			[15:0] 			fP_expected_p5;


	
	
	real                           		real_a;
	real                           		real_b;
	real                           		real_x_expected;
	real                           		real_x_actual;

	wire			[22:0]				w_real_shorten_x;

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
	wire 			[10:0]				fp_expected_man;

	






	initial begin
		clk = 0;
		reset_n = 0;

		#40 reset_n = 1;
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
    		fp_a <= $urandom_range(65536, 0);
    		fp_b <= $urandom_range(65536, 0);
    	end
    end

    // bits to real
    assign real_a_bits[63:63] = fp_a[10:0] == 0 ? 0: fp_a[15:15];
    assign real_a_bits[62:52] = fp_a[10:0] == 0 ? 0: fp_a[14:10] + 1023 - 15;
    assign real_a_bits[51:0] =  fp_a[10:0] == 0 ? 0: {fp_a[9:0] , 42'b0};

    assign real_b_bits[63:63] = fp_b[10:0] == 0? 0: fp_b[15:15];
    assign real_b_bits[62:52] = fp_b[10:0] == 0? 0: fp_b[14:10] + 1023 - 15;
    assign real_b_bits[51:0] =  fp_b[10:0] == 0? 0: {fp_b[9:0] , 42'b0};

    assign real_x_bits[63:63] = fp_x[15:15];
    assign real_x_bits[62:52] = fp_x[14:10] + 1023 - 15;
    assign real_x_bits[51:0] = {fp_x[9:0] , 42'b0};

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
			fP_expected_p5 <= 0;
    	end else begin
    		fP_expected_p1 <= fp_x_expected;
			fP_expected_p2 <= fP_expected_p1;
			fP_expected_p3 <= fP_expected_p2;
			fP_expected_p4 <= fP_expected_p3;
			fP_expected_p5 <= fP_expected_p4;
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

    assign w_real_shorten_x = w_real_x_expected[63:41];
    assign fp_expected_sgn = (w_real_shorten_x[21:11] < 1008) ? 0 : w_real_shorten_x[22:22];
    assign fp_expected_exp = (w_real_shorten_x[21:11] > 1039 ) ? 31 : ((w_real_shorten_x[21:11] < 1008) ? 0 :(w_real_shorten_x[21:11] - 1023 + 15));
    assign fp_expected_man = (w_real_shorten_x[21:11] < 1008) ? 0 :  (w_real_shorten_x[21:11] > 1039 ) ? 11'h7ff : w_real_shorten_x[10:0];


    assign fp_x_expected_inmt = {fp_expected_sgn, fp_expected_exp, fp_expected_man};
    assign fp_x_expected_inmt_1 = fp_x_expected_inmt + 1;
    assign fp_x_expected = fp_x_expected_inmt[16:1] == 16'hffff ? fp_x_expected_inmt[16:1] : fp_x_expected_inmt_1[16:1];

    // error bit
    wire[15:0] diff = (fP_expected_p5 >= fp_x)  ? fP_expected_p5 - fp_x :  fp_x - fP_expected_p5;
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


//----------------------------------------------------------------------------------------
//------------------------- DUT ----------------------------------------------------------
//----------------------------------------------------------------------------------------

	float2fixed float2fixed_inst_a(
			.clk(clk),
			.reset_n(reset_n), 
			.float_in(fp_a),
			.fixed_out(w_fixed_a)
		);

	float2fixed float2fixed_inst_b(
			.clk(clk),
			.reset_n(reset_n), 
			.float_in(fp_b),
			.fixed_out(w_fixed_b)
		);
		
	assign w_fixed_result_inmt = w_fixed_a + w_fixed_b;
	assign w_fixed_result = (w_fixed_a[42] & w_fixed_b[42]) &  ~w_fixed_result_inmt[42]? {1'b1, 42'h00000000001} : ((~w_fixed_a[42] & ~w_fixed_b[42]) &  w_fixed_result_inmt[42]) ? {1'b0, 42'h3ffffffffff} : w_fixed_result_inmt[42:0];

	fixed2float fixed2float_inst(
			.clk(clk),
			.reset_n(reset_n),
			.fixed_in(w_fixed_result[42:0]),
			.float_out(fp_x)
	);


endmodule