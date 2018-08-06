module barrel_shifter (
	input				clk,
	input 				reset_n,
	input 				sign_i,
	input		[4:0]	shft_amt_i,
	input 		[11:0]	barrel_in,
	output		[43:0]	barrel_o
	);

	localparam WIDTH = 44;
	genvar                         i;

	// wire declaration levels
	wire 		[31:0] 		  w_sign_adjust;
	wire 		[WIDTH -1 :0] w0_shft;
	wire 		[WIDTH -1 :0] w1_shft;
	wire 		[WIDTH -1 :0] w2_shft;
	wire 		[WIDTH -1 :0] w3_shft;
	reg 		[WIDTH -1 :0] r3_shft;
	reg 		[4:0]		  r_shft_amt;
	reg 					  r_sign;

	wire 		[WIDTH -1 :0] w4_shft;
	wire 		[WIDTH -1 :0] w5_shft;

	assign w_sign_adjust = sign_i ? 32'hffffffff : 32'b0;
	assign 	w0_shft = {w_sign_adjust, barrel_in};

	//level 1
    assign w1_shft[0] = shft_amt_i[0] ? sign_i : w0_shft[0];
    generate
        for(i = 1; i < WIDTH  ; i = i + 1) 			
        begin :level_1
            mux_2 level_1_mux(.in1_i(w0_shft[i]), .in2_i(w0_shft[i-1]), .sel_i(shft_amt_i[0]), .out_o(w1_shft[i]));
        end
    endgenerate
    //end level 1  


    //level 2
        assign w2_shft[0] = shft_amt_i[1] ? sign_i : w1_shft[0];
        assign w2_shft[1] = shft_amt_i[1] ? sign_i : w1_shft[1];
        
        generate
            for(i = 2; i < WIDTH ; i = i + 1) 			
            begin :level_2
                mux_2 level_2_mux(.in1_i(w1_shft[i]), .in2_i(w1_shft[i-2]), .sel_i(shft_amt_i[1]), .out_o(w2_shft[i]));
            end
        endgenerate
    //end level 2


    //level 3
        assign w3_shft[0] = shft_amt_i[2] ? sign_i :w2_shft[0];
        assign w3_shft[1] = shft_amt_i[2] ? sign_i :w2_shft[1];
        assign w3_shft[2] = shft_amt_i[2] ? sign_i :w2_shft[2];
        assign w3_shft[3] = shft_amt_i[2] ? sign_i :w2_shft[3];
        generate
            for(i = 4; i < WIDTH ; i = i + 1) 			
            begin :level_3
                mux_2 level_3_mux(.in1_i(w2_shft[i]),.in2_i(w2_shft[i-4]),.sel_i(shft_amt_i[2]),.out_o(w3_shft[i]));
            end
        endgenerate

        always @(posedge clk) begin : proc_r3_shft
        	if(~reset_n) begin
        		r3_shft <= 0;
        		r_shft_amt <= 0;
        		r_sign <= 0;
        	end else begin
        		r3_shft <= w3_shft;
        		r_shft_amt <= shft_amt_i;
        		r_sign <= sign_i;
        	end
        end
    
    //end level 3

    // level 4
        assign w4_shft[0] = shft_amt_i[3] ? r_sign :r3_shft[0];
        assign w4_shft[1] = shft_amt_i[3] ? r_sign :r3_shft[1];
        assign w4_shft[2] = shft_amt_i[3] ? r_sign :r3_shft[2];
        assign w4_shft[3] = shft_amt_i[3] ? r_sign :r3_shft[3];
        assign w4_shft[4] = shft_amt_i[3] ? r_sign :r3_shft[4];
        assign w4_shft[5] = shft_amt_i[3] ? r_sign :r3_shft[5];
        assign w4_shft[6] = shft_amt_i[3] ? r_sign :r3_shft[6];
        assign w4_shft[7] = shft_amt_i[3] ? r_sign :r3_shft[7];
        
        generate
            for(i = 8; i < WIDTH ; i = i + 1) 			
            begin :level_4
                mux_2 level_4_mux(.in1_i(r3_shft[i]),.in2_i(r3_shft[i-8]),.sel_i(r_shft_amt[3]),.out_o(w4_shft[i]));
            end
        endgenerate
    //end level 4


    // level 5
        assign w5_shft[0]   = shft_amt_i[4] ? r_sign : w4_shft[0];
        assign w5_shft[1]   = shft_amt_i[4] ? r_sign : w4_shft[1];
        assign w5_shft[2]   = shft_amt_i[4] ? r_sign : w4_shft[2];
        assign w5_shft[3]   = shft_amt_i[4] ? r_sign : w4_shft[3];
        assign w5_shft[4]   = shft_amt_i[4] ? r_sign : w4_shft[4];
        assign w5_shft[5]   = shft_amt_i[4] ? r_sign : w4_shft[5];
        assign w5_shft[6]   = shft_amt_i[4] ? r_sign : w4_shft[6];
        assign w5_shft[7]   = shft_amt_i[4] ? r_sign : w4_shft[7];
        assign w5_shft[8]   = shft_amt_i[4] ? r_sign : w4_shft[8];
        assign w5_shft[9]   = shft_amt_i[4] ? r_sign : w4_shft[9];
        assign w5_shft[10]  = shft_amt_i[4] ? r_sign : w4_shft[10];
        assign w5_shft[11]  = shft_amt_i[4] ? r_sign : w4_shft[11];
        assign w5_shft[12]  = shft_amt_i[4] ? r_sign : w4_shft[12];
        assign w5_shft[13]  = shft_amt_i[4] ? r_sign : w4_shft[13];
        assign w5_shft[14]  = shft_amt_i[4] ? r_sign : w4_shft[14];
        assign w5_shft[15]  = shft_amt_i[4] ? r_sign : w4_shft[15];
        
        generate
            for(i = 16; i < WIDTH ; i = i + 1) 			
            begin :level_5
                mux_2 level_4_mux(.in1_i(w4_shft[i]),.in2_i(w4_shft[i-16]),.sel_i(r_shft_amt[4]),.out_o(w5_shft[i]));
            end
        endgenerate
    // end level 5

    assign barrel_o = w5_shft;

endmodule // barrel_shifter