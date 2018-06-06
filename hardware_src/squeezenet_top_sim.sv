//**************************************************************************************************
// Project/Product : IDCT
// Description     : Inverse Discrete Cosine Transform 
//                   row and column 1D IDCT operation 
//                   with 3 stage pipeline in each 1D IDCT
// Dependencies    : global_defs.v, global_func.v, synch_fifo.v
// References      : 
//
//**************************************************************************************************
   
`timescale 1ns / 1ps

`include "squeezenet_top.v"

`include "expand_convolution/expand_convolution.v"
`include "expand_convolution/exp_3x3_conv.v"
`include "expand_convolution/exp_1x1_conv.v"
`include "expand_convolution/exp_3x3_conv_add_fifo/exp_3x3_conv_add_fifo.v"
`include "expand_convolution/expand_conv_fifo/expand_conv_fifo.v"

`include "exp_3x3_kernal_controller/exp_3x3_kernal_controller.v"
`include "exp_3x3_kernal_controller/exp_3x3_ker_write_cont.v"
`include "exp_3x3_kernal_controller/write_config_exp_3x3.v"
`include "exp_3x3_kernal_controller/exp_3x3_ker_read_cont.v"
`include "exp_3x3_kernal_controller/read_config_exp_3x3.v"
`include "exp_3x3_kernal_controller/exp_3x3_kernal_fifo/exp_3x3_kernal_fifo.v"
`include "exp_3x3_kernal_controller/exp_3x3_ker_fifo_64/exp_3x3_ker_fifo_64.v"
`include "exp_3x3_kernal_controller/exp_3x3_ker_fifo_8/exp_3x3_ker_fifo_8.v"
`include "exp_3x3_kernal_controller/exp_3x3_kernal_ram/exp_3x3_kernal_ram.v"

`include "exp_1x1_kernal_controller/exp_1x1_kernal_controller.v"
`include "exp_1x1_kernal_controller/exp_1x1_ker_write_cont.v"
`include "exp_1x1_kernal_controller/write_config_exp_1x1.v"
`include "exp_1x1_kernal_controller/exp_1x1_ker_read_cont.v"
`include "exp_1x1_kernal_controller/read_config_exp_1x1.v"
`include "exp_1x1_kernal_controller/exp_1x1_kernal_fifo/exp_1x1_kernal_fifo.v"
`include "exp_1x1_kernal_controller/exp_1x1_kernal_ram/exp_1x1_kernal_ram.v"

`include "expand_2_max_top/expand_2_max_top.v"
`include "expand_2_max_top/expand_ram_controller.v"
`include "expand_2_max_top/fire_config_expand.v"
`include "expand_2_max_top/max_ram_controller.v"
`include "expand_2_max_top/exp_bash_controller.v"
`include "expand_2_max_top/bash_add.v"
`include "expand_2_max_top/expand_add.v"
`include "expand_2_max_top/max_pool.v"
`include "expand_2_max_top/exp_bash_fifo/exp_bash_fifo.v"
`include "expand_2_max_top/exp_bash_ram/exp_bash_ram.v"
`include "expand_2_max_top/expand_ram/expand_ram.v"
`include "expand_2_max_top/max_ram/max_ram.v"
`include "expand_2_max_top/squeeze_fifo/squeeze_fifo.v"

`include "squeeze_kernal_controller/squeeze_kernal_controller.v"
`include "squeeze_kernal_controller/squeeze_ker_write_cont.v"
`include "squeeze_kernal_controller/write_config_squeeze.v"
`include "squeeze_kernal_controller/squeeze_ker_read_cont.v"
`include "squeeze_kernal_controller/read_config_squeeze.v"
`include "squeeze_kernal_controller/squeeze_kernal_fifo/squeeze_kernal_fifo.v"
`include "squeeze_kernal_controller/squeeze_kernal_ram/squeeze_kernal_ram.v"

`include "max_2_squeeze_top/max_2_squeeze_top.v"
`include "max_2_squeeze_top/squeeze_ram_controller.v"
`include "max_2_squeeze_top/squeeze_convolution.v"
`include "max_2_squeeze_top/last_squ_add.v"
`include "max_2_squeeze_top/squ_bash_controller.v"
`include "max_2_squeeze_top/average_pool.v"
`include "max_2_squeeze_top/squeeze_ram/squeeze_ram.v"
`include "max_2_squeeze_top/squ_bash_fifo/squ_bash_fifo.v"
`include "max_2_squeeze_top/squ_bash_ram/squ_bash_ram.v"
`include "max_2_squeeze_top/average_fifo/average_fifo.v"
`include "max_2_squeeze_top/output_fifo/output_fifo.v"

`include "float_arith/add/add_12.v"
`include "float_arith/add/add_en_12.v"
`include "float_arith/mult/mult_12.v"
`include "float_arith/multiplier/multiplier_7x7.v"

//`include "float_arith/int/add_12.v"
//`include "float_arith/int/add_en_12.v"
//`include "float_arith/int/mult_12.v"
//
`define EOF -1

module squeezenet_top_sim(
);


//----------------------------------------------------------------------------------------------------------------------
// Global constant and function headers
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// parameter definitions
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// localparam definitions
//----------------------------------------------------------------------------------------------------------------------

	/*
		Configurations :- EXPAND 3X3 KERNAL CONTROLLER
		one_exp3_ker_addr_limit_i 	:- [NO of expand kernals / 4]
		exp3_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1] // After Expand

		Configurations :- EXPAND 1X1 KERNAL CONTROLLER
		tot_exp1_ker_addr_limit_i 	:- [(NO of expand kernals * depth) / 4 ] - 1
		one_exp1_ker_addr_limit_i 	:- [NO of expand kernals / 4]
		exp1_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1]

		Configurations :- 
		one_exp_layer_addr_limit_i 	:- [(dimension * expand kernals / 4)] - 1
		exp_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1]
		no_of_exp_kernals_i 		:- [2 * NO of expand kernals / 8 - 1]

		exp_123_addr_space_i 		:- [expand kernal / 4 * 3] - 1 	
		exp_12_addr_space_i 		:- [expand kernal / 4 * 2]
		exp_1_addr_space_i 			:- [expand kernal / 4 * 1] - 1
		exp_tot_addr_space_i 		:- [expand layer dim * expand kernal / 4] - 2
		max_tot_addr_space_i 		:- [max layer dim * expand kernal / 4] - 2

		Configurations :- Squeeze KERNAL CONTROLLER
		tot_squ_ker_addr_limit_i 	:- [(NO of squeeze kernals * depth / 8 ] - 1
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
		squ_kernals_63_i 			:- [No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
		layer_dimension_i 			:- [dimension - 1]

		Configurations :- MAX 2 SQUEEZE
		tot_squ_addr_limit_i 		:- [(dimension * depth / 2) / 8] - 1 // After max pool
		no_of_squ_kernals_i 		:- [No of squeeze kernal - 1]
		squ_3x3_ker_depth_i 		:- [squeeze 3x3 depth]
		layer_dim_i 				:- [dimension - 1]
		squ_layer_dimension_i 		:- [Squeeze layer dimension - 1] // After max pool
	*/


//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	reg 															clk_i;
	reg 															rst_n_i;

	// Configuration Control Signals
	wire 															start_i;
	wire 															exp_1x1_en_i;
	wire 															max_en_i;
	wire 					[6:0] 									one_exp_ker_addr_limit_i;
	wire 					[5:0] 									exp_ker_depth_i;
	wire 					[6:0]									layer_dimension_i;
	wire 					[11:0] 									tot_exp1_ker_addr_limit_i;
	wire  					[10:0] 									one_exp_layer_addr_limit_i;
	wire  					[5:0] 									no_of_exp_kernals_i;
	wire  					[7:0] 									exp_123_addr_space_i;
	wire  					[7:0] 									exp_12_addr_space_i;
	wire  					[7:0] 									exp_1_addr_space_i;
	wire  					[10:0] 									exp_tot_addr_space_i;
	wire  					[9:0] 									max_tot_addr_space_i;

	wire 															squ_repeat_en_i;
	wire 															avg_en_i;
	wire 					[11:0] 									tot_squ_ker_addr_limit_i;
	wire 					[5:0] 									one_squ_ker_addr_limit_i;
	wire 					[5:0]									squ_kernals_63_i; 
	wire 					[8:0] 									tot_squ_addr_limit_i;
	wire 					[9:0]									no_of_squ_kernals_i;
	wire 					[8:0]									squ_3x3_ker_depth_i;
	wire 					[6:0]	 								squ_layer_dimension_i;
	
	// Layer Control Signals
	wire 															layer_req_o;
	reg 															layer_ready_i;
	reg 					[71:0] 									layer_data_i;

	// EXPAND 3x3 Kernal FIFO control Signals
	reg 					[63:0]									fifo_exp_3x3_wr_data_i;
	reg 															fifo_exp_3x3_wr_en_i;
	wire 					[7:0] 									fifo_exp_3x3_data_count_o;

	// EXPAND 1X1 Kernal FIFO control Signals
	reg 					[63:0]									fifo_exp_1x1_wr_data_i;
	reg 															fifo_exp_1x1_wr_en_i;
	wire 					[7:0] 									fifo_exp_1x1_data_count_o;	

	// Expand Bash FIFO COntrol Signals
	reg 					[63:0] 									fifo_exp_bash_wr_data_i;
	reg 															fifo_exp_bash_wr_en_i;
	wire 					[6:0] 									fifo_exp_bash_data_count_o;

	reg 					[63:0]									fifo_squeeze_wr_data_i;
	reg 															fifo_squeeze_wr_en_i;
	wire 					[7:0] 									fifo_squeeze_data_count_o; 	

	// Squeeze Bash FIFO COntrol Signals
	reg 					[63:0] 									fifo_squ_bash_wr_data_i;
	reg 															fifo_squ_bash_wr_en_i;
	wire 					[3:0] 									fifo_squ_bash_data_count_o;

	// Output FIFO Control Signals
	wire 					[7:0] 									fifo_out_rd_data_o;
	wire 															fifo_out_rd_en_i;
	wire 															fifo_out_empty_o;

	reg 					[63:0] 									r_out_3x3;
	reg 					[63:0] 									r_out_1x1;

	reg 					[63:0] 									r_max_3x3;
	reg 					[63:0] 									r_max_1x1;

	reg 					[7:0] 									r_squ_out;
	reg 					[7:0] 									r_avg_out;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	always #2.5 clk_i = ~clk_i;

	integer layer, kernal_3x3, kernal_1x1, exp_bash, squeeze, squ_bash;
	integer out_3x3, out_1x1;
	integer max_3x3, max_1x1;
	integer squ_out, avg_out;
	integer a,b,c,d,e,f;
	initial begin
		clk_i = 0;
		rst_n_i = 0;

		kernal_3x3 = $fopen("../sim_verify/ker_3x3.bin", "rb");
		kernal_1x1 = $fopen("../sim_verify/ker_1x1.bin", "rb");
		exp_bash = $fopen("../sim_verify/bias.bin", "rb");
		squeeze = $fopen("../sim_verify/sq_ker.bin", "rb");
		squ_bash = $fopen("../sim_verify/sq_bias.bin", "rb");

		//a = $fgetc(layer);
		b = $fgetc(kernal_3x3);
		c = $fgetc(kernal_1x1);
		d = $fgetc(exp_bash);
		e = $fgetc(squeeze);
		f = $fgetc(squ_bash);

		//out_3x3 = $fopen("../sim_verify/exp_3.bin", "rb");
		//out_1x1 = $fopen("../sim_verify/exp_1.bin", "rb");
		//max_3x3 = $fopen("../sim_verify/pool_3.bin", "rb");
		//max_1x1 = $fopen("../sim_verify/pool_1.bin", "rb");
		avg_out = $fopen("../sim_verify/av_pool_out.bin", "rb");
		squ_out = $fopen("../sim_verify/sq_out.bin", "rb");

		#100
		@(posedge clk_i)
		rst_n_i = 1;
	end


	initial begin
		layer = $fopen("../sim_verify/input_layer.bin", "rb");
		layer_data_i[71:64] = $fgetc(layer);
		layer_data_i[63:56] = $fgetc(layer);
		layer_data_i[55:48] = $fgetc(layer);
		layer_data_i[47:40] = $fgetc(layer);
		layer_data_i[39:32] = $fgetc(layer);
		layer_data_i[31:24] = $fgetc(layer);
		layer_data_i[23:16] = $fgetc(layer);
		layer_data_i[15:08] = $fgetc(layer);
		layer_data_i[07:00] = $fgetc(layer);
		a = $fgetc(layer);
		$display("update %h",layer_data_i);
	end

	reg [4:0] r_start_count;
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			r_start_count <= 0;
		end else if(r_start_count < 10) begin
			r_start_count <= r_start_count + 1;
		end
	end
	assign start_i = (r_start_count == 4);
 	// config 1 :- dim 6; ker 64; dep = 4; squ_ker 16; 
 	// config 2 :- dim 27; ker 64; dep = 16; squ_ker 32;
 	// config 3 :- dim 13; ker 64; dep = 16; squ_ker 32; avg_en = 1;
	assign exp_1x1_en_i = 1;
	assign max_en_i = 0;
	assign one_exp_ker_addr_limit_i = 16; //16; //16;
	assign exp_ker_depth_i = 15; //15; //3;
	assign layer_dimension_i = 12; //26; //5;
	assign tot_exp1_ker_addr_limit_i = 255; //255; //63;
	assign one_exp_layer_addr_limit_i = 207; //431; //95;
	assign no_of_exp_kernals_i = 15; //15; //15;
	assign exp_123_addr_space_i = 47; //47; //47;
	assign exp_12_addr_space_i = 32; //32; //32;
	assign exp_1_addr_space_i = 15; //15; //15;
	assign exp_tot_addr_space_i = 206; //430; //94;
	assign max_tot_addr_space_i = 94; //206; //30;

	assign squ_repeat_en_i = 0;
	assign avg_en_i = 0; //1;
	assign tot_squ_ker_addr_limit_i = 511; //511; //255;
	assign one_squ_ker_addr_limit_i = 8; //8; //8;
	assign squ_kernals_63_i = 31; //31; //15;
	assign tot_squ_addr_limit_i = 103; //215; //47;
	assign no_of_squ_kernals_i = 31; //31; //15;
	assign squ_3x3_ker_depth_i = 64; //64; //64;
	assign squ_layer_dimension_i = 12; //26; //5;
	
	// Squeezenet v1.1 Config
	//layer 1 :- 	dim = 113 		depth = 3 		exp_kernal = 64 	squ_kernal = 16 	exp_1x1_en = 0 		max_en = 1 		avg_en = 0
	//layer 2 :- 	dim = 56 		depth = 16 		exp_kernal = 64 	squ_kernal = 16 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
	//layer 3 :- 	dim = 56 		depth = 16 		exp_kernal = 64 	squ_kernal = 32 	exp_1x1_en = 1 		max_en = 1 		avg_en = 0
	//layer 4 :- 	dim = 27 		depth = 32 		exp_kernal = 128 	squ_kernal = 32 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
	//layer 5 :- 	dim = 27 		depth = 32 		exp_kernal = 128 	squ_kernal = 48 	exp_1x1_en = 1 		max_en = 1 		avg_en = 0
	//layer 6 :- 	dim = 13 		depth = 48 		exp_kernal = 192 	squ_kernal = 48 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
	//layer 7 :- 	dim = 13 		depth = 48 		exp_kernal = 192 	squ_kernal = 64 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
	//layer 8 :- 	dim = 13 		depth = 64 		exp_kernal = 256 	squ_kernal = 64 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
	//layer 9 :- 	dim = 13 		depth = 64 		exp_kernal = 256 	squ_kernal = 100 	exp_1x1_en = 1 		max_en = 0 		avg_en = 1
 
	/*assign exp_1x1_en_i =  1;
	assign max_en_i =  0;
	assign one_exp_ker_addr_limit_i =  64;
	assign exp_ker_depth_i =  63;
	assign layer_dimension_i =  12;
	assign tot_exp1_ker_addr_limit_i =  4095;
	assign one_exp_layer_addr_limit_i =  831;
	assign no_of_exp_kernals_i =  63;
	assign exp_123_addr_space_i =  191;
	assign exp_12_addr_space_i =  128;
	assign exp_1_addr_space_i =  63;
	assign exp_tot_addr_space_i =  830;
	assign max_tot_addr_space_i =  382;
	assign squ_repeat_en_i =  1;
	assign avg_en_i =  1;
	assign tot_squ_ker_addr_limit_i =  6399;
	assign one_squ_ker_addr_limit_i =  32;
	assign squ_kernals_63_i =  63;
	assign tot_squ_addr_limit_i =  415;
	assign no_of_squ_kernals_i =  99;
	assign squ_3x3_ker_depth_i =  256;
	assign squ_layer_dimension_i =  12;*/

	always @(posedge clk_i) begin
		if(~rst_n_i) begin
			layer_ready_i <= 0;
		end else begin
			layer_ready_i <= 1;
		end
	end
	always @(posedge clk_i) begin 
		/*if(~rst_n_i) begin
			layer_data_i <= 0;
		end*/
		if(layer_req_o) begin
			if(a != `EOF) begin
				layer_data_i[71:64] <= a;
				layer_data_i[63:56] <= $fgetc(layer);
				layer_data_i[55:48] <= $fgetc(layer);
				layer_data_i[47:40] <= $fgetc(layer);
				layer_data_i[39:32] <= $fgetc(layer);
				layer_data_i[31:24] <= $fgetc(layer);
				layer_data_i[23:16] <= $fgetc(layer);
				layer_data_i[15:08] <= $fgetc(layer);
				layer_data_i[07:00] <= $fgetc(layer);
				a = $fgetc(layer);
			end
		end
	end

	reg [6:0] wr_en_count;
	always_ff @(posedge clk_i) begin 
		if(~rst_n_i || wr_en_count == 30) begin
			wr_en_count <= 0;
		end else begin
			wr_en_count <= wr_en_count + 1;
		end
	end

	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_exp_3x3_wr_data_i <= 0;
		end
		else if(fifo_exp_3x3_data_count_o < 100 && r_start_count == 10) begin // && wr_en_count == 10
			if(b != `EOF) begin
				fifo_exp_3x3_wr_data_i[63:56] <= b; //$fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[55:48] <= $fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[47:40] <= $fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[39:32] <= $fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[31:24] <= $fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[23:16] <= $fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[15:08] <= $fgetc(kernal_3x3);
				fifo_exp_3x3_wr_data_i[07:00] <= $fgetc(kernal_3x3);
				b = $fgetc(kernal_3x3);
			end
		end
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_exp_3x3_wr_en_i <= 0;
		end else begin
			fifo_exp_3x3_wr_en_i <= (fifo_exp_3x3_data_count_o < 100 && r_start_count == 10); //  && wr_en_count == 10
		end
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_exp_1x1_wr_data_i <= 0;
		end
		else if(fifo_exp_1x1_data_count_o < 100 && r_start_count == 10) begin  //&& wr_en_count == 30
			if(c != `EOF) begin
				fifo_exp_1x1_wr_data_i[31:24] <= c; //$fgetc(kernal_1x1);
				fifo_exp_1x1_wr_data_i[23:16] <= $fgetc(kernal_1x1);
				fifo_exp_1x1_wr_data_i[15:08] <= $fgetc(kernal_1x1);
				fifo_exp_1x1_wr_data_i[07:00] <= $fgetc(kernal_1x1);
	
				fifo_exp_1x1_wr_data_i[63:56] <= $fgetc(kernal_1x1);
				fifo_exp_1x1_wr_data_i[55:48] <= $fgetc(kernal_1x1);
				fifo_exp_1x1_wr_data_i[47:40] <= $fgetc(kernal_1x1);
				fifo_exp_1x1_wr_data_i[39:32] <= $fgetc(kernal_1x1);
				c = $fgetc(kernal_1x1);
			end
		end	
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_exp_1x1_wr_en_i <= 0;
		end else begin
			fifo_exp_1x1_wr_en_i <= (fifo_exp_1x1_data_count_o < 100 && r_start_count == 10); // && wr_en_count == 30
		end
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_exp_bash_wr_data_i <= 0;
		end
		else if(fifo_exp_bash_data_count_o < 100 && r_start_count == 10) begin  //&& wr_en_count == 30
			if(d != `EOF) begin
				fifo_exp_bash_wr_data_i[63:56] <= d;
				fifo_exp_bash_wr_data_i[55:48] <= $fgetc(exp_bash);
				fifo_exp_bash_wr_data_i[47:40] <= $fgetc(exp_bash);
				fifo_exp_bash_wr_data_i[39:32] <= $fgetc(exp_bash);
				fifo_exp_bash_wr_data_i[31:24] <= $fgetc(exp_bash); 
				fifo_exp_bash_wr_data_i[23:16] <= $fgetc(exp_bash);
				fifo_exp_bash_wr_data_i[15:08] <= $fgetc(exp_bash);
				fifo_exp_bash_wr_data_i[07:00] <= $fgetc(exp_bash);
				d = $fgetc(exp_bash);
			end
		end	
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_exp_bash_wr_en_i <= 0;
		end else begin
			fifo_exp_bash_wr_en_i <= (fifo_exp_bash_data_count_o < 100 && r_start_count == 10); // && wr_en_count == 30
		end
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_squeeze_wr_data_i <= 0;
		end
		else if(fifo_squeeze_data_count_o < 100 && r_start_count == 10) begin  //&& wr_en_count == 30
			if(e != `EOF) begin
				fifo_squeeze_wr_data_i[63:56] <= e;
				fifo_squeeze_wr_data_i[55:48] <= $fgetc(squeeze);
				fifo_squeeze_wr_data_i[47:40] <= $fgetc(squeeze);
				fifo_squeeze_wr_data_i[39:32] <= $fgetc(squeeze);
				fifo_squeeze_wr_data_i[31:24] <= $fgetc(squeeze); 
				fifo_squeeze_wr_data_i[23:16] <= $fgetc(squeeze);
				fifo_squeeze_wr_data_i[15:08] <= $fgetc(squeeze);
				fifo_squeeze_wr_data_i[07:00] <= $fgetc(squeeze);
				e = $fgetc(squeeze);
			end
		end	
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_squeeze_wr_en_i <= 0;
		end else begin
			fifo_squeeze_wr_en_i <= (fifo_squeeze_data_count_o < 100 && r_start_count == 10); // && wr_en_count == 30
		end
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_squ_bash_wr_data_i <= 0;
		end
		else if(fifo_squ_bash_data_count_o < 100 && r_start_count == 10) begin  //&& wr_en_count == 30
			if(f != `EOF) begin
				fifo_squ_bash_wr_data_i[07:00] <= f;
				fifo_squ_bash_wr_data_i[15:08] <= $fgetc(squ_bash); 
				fifo_squ_bash_wr_data_i[23:16] <= $fgetc(squ_bash);
				fifo_squ_bash_wr_data_i[31:24] <= $fgetc(squ_bash);
				fifo_squ_bash_wr_data_i[39:32] <= $fgetc(squ_bash);
				fifo_squ_bash_wr_data_i[47:40] <= $fgetc(squ_bash);
				fifo_squ_bash_wr_data_i[55:48] <= $fgetc(squ_bash);
				fifo_squ_bash_wr_data_i[63:56] <= $fgetc(squ_bash);
				f = $fgetc(squ_bash);
			end
		end	
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			fifo_squ_bash_wr_en_i <= 0;
		end else begin
			fifo_squ_bash_wr_en_i <= (fifo_squ_bash_data_count_o < 10 && r_start_count == 10); // && wr_en_count == 30
		end
	end

	// OUTPUT
	reg [4:0] r_chk_out;
	always_ff @(posedge clk_i) begin
		if(~rst_n_i || r_chk_out == 10) begin
			r_chk_out <= 0;
		end else begin
			r_chk_out <= r_chk_out + 1;
		end
	end
	wire rd_en;
	assign rd_en = (~fifo_out_empty_o); // && r_chk_out == 10);
	always_ff @(posedge clk_i) begin 
		if(rd_en && ~avg_en_i) begin //  && r_chk_out == 10
			r_squ_out <= $fgetc(squ_out);
		end
	end
	always_ff @(posedge clk_i) begin 
		if(rd_en && avg_en_i) begin //  && r_chk_out == 10
			r_avg_out <= $fgetc(avg_out);
		end
	end

	reg chk_out;
	always_ff @(posedge clk_i) begin 
		if(~rst_n_i) begin
			chk_out <= 0;
		end else begin
			chk_out <= (rd_en); // && r_chk_out == 10);
		end
	end

	always_ff @(posedge clk_i) begin 
		if(chk_out && r_squ_out != fifo_out_rd_data_o && ~avg_en_i) begin
			$finish;
		end
	end
	always_ff @(posedge clk_i) begin 
		if(chk_out && r_avg_out != fifo_out_rd_data_o && avg_en_i) begin
			$finish;
		end
	end

	real real_a;
	assign real_a = $bitstoreal(1425);

/*	always_ff @(posedge clk_i) begin 
		if(chk_out && r_out_3x3 != fifo_squeeze_3x3_rd_data_o && ~max_en_i) begin
			$finish;
		end
	end

	always_ff @(posedge clk_i) begin 
		if(chk_out && r_max_1x1 != fifo_squeeze_1x1_rd_data_o && max_en_i) begin
			$finish;
		end
	end

	always_ff @(posedge clk_i) begin 
		if(chk_out && r_max_3x3 != fifo_squeeze_3x3_rd_data_o && max_en_i) begin
			$finish;
		end
	end
*/

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------
	
	squeezenet_top squeezenet_top_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.exp_1x1_en_i 						(exp_1x1_en_i),
		.max_en_i 							(max_en_i),
		.squ_repeat_en_i 					(squ_repeat_en_i),
		.avg_en_i 							(avg_en_i),
		.one_exp_ker_addr_limit_i 			(one_exp_ker_addr_limit_i),
		.exp_ker_depth_i 					(exp_ker_depth_i),
		.layer_dimension_i 					(layer_dimension_i),
		.tot_exp1_ker_addr_limit_i 			(tot_exp1_ker_addr_limit_i),
		.one_exp_layer_addr_limit_i 		(one_exp_layer_addr_limit_i),
		.no_of_exp_kernals_i 				(no_of_exp_kernals_i),
		.exp_123_addr_space_i 				(exp_123_addr_space_i),
		.exp_12_addr_space_i 				(exp_12_addr_space_i),
		.exp_1_addr_space_i 				(exp_1_addr_space_i),
		.exp_tot_addr_space_i 				(exp_tot_addr_space_i),
		.max_tot_addr_space_i 				(max_tot_addr_space_i),
		.tot_squ_ker_addr_limit_i 			(tot_squ_ker_addr_limit_i),
		.one_squ_ker_addr_limit_i 			(one_squ_ker_addr_limit_i),
		.squ_kernals_63_i 					(squ_kernals_63_i),
		.tot_squ_addr_limit_i 				(tot_squ_addr_limit_i),
		.no_of_squ_kernals_i 				(no_of_squ_kernals_i),
		.squ_3x3_ker_depth_i 				(squ_3x3_ker_depth_i),
		.squ_layer_dimension_i 				(squ_layer_dimension_i),


		.layer_req_o 						(layer_req_o),
		.layer_ready_i 						(layer_ready_i),
		.layer_data_i 						(layer_data_i),

		.fifo_exp_3x3_clr_i 				(~rst_n_i),
		.fifo_exp_3x3_wr_data_i 			(fifo_exp_3x3_wr_data_i),
		.fifo_exp_3x3_wr_en_i 				(fifo_exp_3x3_wr_en_i),
		.fifo_exp_3x3_data_count_o 			(fifo_exp_3x3_data_count_o),

		.fifo_exp_1x1_clr_i					(~rst_n_i),
		.fifo_exp_1x1_wr_data_i 			(fifo_exp_1x1_wr_data_i),
		.fifo_exp_1x1_wr_en_i 				(fifo_exp_1x1_wr_en_i),
		.fifo_exp_1x1_data_count_o 			(fifo_exp_1x1_data_count_o),

		.fifo_exp_bash_clr_i 				(~rst_n_i),
		.fifo_exp_bash_wr_data_i 			(fifo_exp_bash_wr_data_i),
		.fifo_exp_bash_wr_en_i 				(fifo_exp_bash_wr_en_i),
		.fifo_exp_bash_data_count_o 		(fifo_exp_bash_data_count_o),
	
		.fifo_squeeze_clr_i 				(~rst_n_i),
		.fifo_squeeze_wr_data_i 			(fifo_squeeze_wr_data_i),
		.fifo_squeeze_wr_en_i 				(fifo_squeeze_wr_en_i),
		.fifo_squeeze_data_count_o 			(fifo_squeeze_data_count_o),

		.fifo_squ_bash_clr_i 				(~rst_n_i),
		.fifo_squ_bash_wr_data_i 			(fifo_squ_bash_wr_data_i),
		.fifo_squ_bash_wr_en_i 				(fifo_squ_bash_wr_en_i),
		.fifo_squ_bash_data_count_o 		(fifo_squ_bash_data_count_o),
	
		.fifo_out_rd_data_o 				(fifo_out_rd_data_o),
		.fifo_out_rd_en_i 					(rd_en), //fifo_out_rd_en_i),
		.fifo_out_empty_o 					(fifo_out_empty_o)
	);

endmodule

