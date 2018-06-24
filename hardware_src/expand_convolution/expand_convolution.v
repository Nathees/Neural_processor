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

module expand_convolution(
	clk_i,
	rst_n_i,

	start_i,
	one_exp_ker_addr_limit_i,

	layer_req_o,
	layer_ready_i,
	layer_data_i,

	exp_3x3_kerl_req_o,
	exp_3x3_kerl_ready_i,
	exp_3x3_kerl_1_data_i,
	exp_3x3_kerl_2_data_i,
	exp_3x3_kerl_3_data_i,
	exp_3x3_kerl_4_data_i,
	
	exp_1x1_kerl_req_o,
	exp_1x1_kerl_ready_i,
	exp_1x1_kerl_data_i,

	fifo_exp_3x3_rd_data_o,
	fifo_exp_3x3_rd_en_i,
	fifo_exp_3x3_empty_o,

	fifo_exp_1x1_rd_data_o,
 	fifo_exp_1x1_rd_en_i,
 	fifo_exp_1x1_empty_o
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

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	input 															start_i;
	input 					[6:0] 								one_exp_ker_addr_limit_i;

	// Layer Control Signals
	output 															layer_req_o;
	input 															layer_ready_i;
	input 					[71:0] 									layer_data_i;

	// EXPAND 3x3 Kernal RAM Control Signals
	output 															exp_3x3_kerl_req_o;
	input 		 													exp_3x3_kerl_ready_i;	
	input 					[71:0] 									exp_3x3_kerl_1_data_i;
	input 					[71:0] 									exp_3x3_kerl_2_data_i;
	input 					[71:0] 									exp_3x3_kerl_3_data_i;					
	input 					[71:0] 									exp_3x3_kerl_4_data_i;

	// EXPAND 1X1 Kernal RAM Control Signals
	output 															exp_1x1_kerl_req_o;		
	input 			 												exp_1x1_kerl_ready_i;
	input 					[31:0] 									exp_1x1_kerl_data_i;

	// FIFO Expand 3x3 COntrol Signals
	output 					[47:0] 									fifo_exp_3x3_rd_data_o;
	input 															fifo_exp_3x3_rd_en_i;
	output 															fifo_exp_3x3_empty_o;

	// FIFO Expand 1x1 COntrol Signals
	output 					[47:0] 									fifo_exp_1x1_rd_data_o;
	input 															fifo_exp_1x1_rd_en_i;
	output 															fifo_exp_1x1_empty_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Exapnd FIFO Control Signals	
	wire  					[7:0] 									w_fifo_exp_3x3_data_count;
	wire  					[7:0] 									w_fifo_exp_1x1_data_count;
	reg 															r_fifo_ready;

	// Control Signals
	wire 															w_data_req;

	// Kernal and Layer storage
	reg 					[71:0] 									r_layer_data_temp;
	reg 					[71:0] 									r_layer_data;

	reg 					[71:0] 									r_exp_3x3_1_kernal;
	reg 					[71:0] 									r_exp_3x3_2_kernal;
	reg 					[71:0] 									r_exp_3x3_3_kernal;
	reg 					[71:0] 									r_exp_3x3_4_kernal;

	reg 					[31:0] 									r_exp_1x1_kernal;

	// Data flag
	reg 						 									r_data_flag_temp;
	reg 															r_data_flag;

	reg 					[5:0] 									r_repeat_no;
	reg 					[5:0] 									r_repeat_count;
	reg 															r_layer_req;
//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------
		
	// Config
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_repeat_no <= 0;
		end 
		else if(start_i) begin
			r_repeat_no <= one_exp_ker_addr_limit_i - 1;
		end
	end

	// FIFO Ready
	always @(posedge clk_i) begin : FIFO_READY
		if(~rst_n_i) begin
			r_fifo_ready <= 0;
		end else begin
			r_fifo_ready <= (w_fifo_exp_3x3_data_count < 230 && w_fifo_exp_1x1_data_count < 230);
		end
	end

	// Kernals and Layer request
	assign w_data_req = (layer_ready_i && exp_3x3_kerl_ready_i && exp_1x1_kerl_ready_i && r_fifo_ready);
	assign layer_req_o			= (w_data_req && r_layer_req);
	assign exp_3x3_kerl_req_o	= w_data_req;
	assign exp_1x1_kerl_req_o	= w_data_req;
	 
	// Layer Data
	always @(posedge clk_i) begin : LAYER_DATA
		if(~rst_n_i) begin
			r_layer_data_temp 	<= 0;
			r_layer_data 		<= 0;
		end else begin
			r_layer_data_temp 	<= layer_data_i;
			r_layer_data 		<= r_layer_data_temp;
		end
	end

	// EXP 3X3 KERNAl
	always @(posedge clk_i) begin : EXP_3X3_KERNAL
		if(~rst_n_i) begin
			r_exp_3x3_1_kernal <= 0;
			r_exp_3x3_2_kernal <= 0;
			r_exp_3x3_3_kernal <= 0;
			r_exp_3x3_4_kernal <= 0;
		end else begin
			r_exp_3x3_1_kernal <= exp_3x3_kerl_1_data_i;
			r_exp_3x3_2_kernal <= exp_3x3_kerl_2_data_i;
			r_exp_3x3_3_kernal <= exp_3x3_kerl_3_data_i;
			r_exp_3x3_4_kernal <= exp_3x3_kerl_4_data_i;
		end
	end

	// EXP 1x1 KERNAl
	always @(posedge clk_i) begin : EXP_1X1_KERNAL
		if(~rst_n_i) begin
			r_exp_1x1_kernal <= 0;
		end else begin
			r_exp_1x1_kernal <= exp_1x1_kerl_data_i;
		end
	end

	// Data Flag
	always @(posedge clk_i) begin : DATA_FLAG
		if(~rst_n_i || start_i) begin
			r_data_flag_temp 	<= 0;
			r_data_flag 		<= 0;
		end else begin
			r_data_flag_temp	<= w_data_req;
			r_data_flag 		<= r_data_flag_temp;
		end
	end

	// Repeat COunt
	always @(posedge clk_i) begin : REPEAT_COUNT
		if(~rst_n_i || start_i) begin
			r_repeat_count <= 0;
		end 
		else if(r_repeat_count == r_repeat_no && w_data_req) begin
			r_repeat_count <= 0;
		end 
		else if(w_data_req) begin
			r_repeat_count <= r_repeat_count + 1;
		end
	end

	// Layer Request
	always @(posedge clk_i) begin : LAYER_REQUEST
		if(~rst_n_i || start_i) begin
			r_layer_req <= 0;
		end 
		else if(r_repeat_count == r_repeat_no - 1 && w_data_req) begin
			r_layer_req <= 1;
		end
		else if(r_layer_req && w_data_req) begin
			r_layer_req <= 0;
		end
	end
	
	reg [15:0] r_in_count  /*synthesis noprune */;
	always @(posedge clk_i) begin 
		if(~rst_n_i || start_i) begin
			r_in_count <= 0;
		end else if(layer_req_o) begin
			r_in_count <= r_in_count + 1;
		end
	end
	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------
	
	// Expand 3x3 Convolution Instantiation
	exp_3x3_conv exp_3x3_conv_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),
		.start_i 								(start_i),

		.layer_data_i 							(r_layer_data),

		.kernal_1_data_i 						(r_exp_3x3_1_kernal),
		.kernal_2_data_i 						(r_exp_3x3_2_kernal),
		.kernal_3_data_i 						(r_exp_3x3_3_kernal),
		.kernal_4_data_i 						(r_exp_3x3_4_kernal),

		.data_flag_i 							(r_data_flag),

		.fifo_exp_3x3_rd_data_o 				(fifo_exp_3x3_rd_data_o),
		.fifo_exp_3x3_data_count_o 				(w_fifo_exp_3x3_data_count),
		.fifo_exp_3x3_rd_en_i 					(fifo_exp_3x3_rd_en_i),
		.fifo_exp_3x3_empty_o 					(fifo_exp_3x3_empty_o)
	);

	// Expand 1x1 Convolution Instantiation
	exp_1x1_conv exp_1x1_conv_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),
		.start_i 								(start_i),

		.layer_data_i 							(r_layer_data[39:32]),

		.kernal_1_data_i 						(r_exp_1x1_kernal[31:24]),
		.kernal_2_data_i 						(r_exp_1x1_kernal[23:16]),
		.kernal_3_data_i 						(r_exp_1x1_kernal[15:08]),
		.kernal_4_data_i 						(r_exp_1x1_kernal[07:00]),

		.data_flag_i 							(r_data_flag),

		.fifo_exp_1x1_rd_data_o 				(fifo_exp_1x1_rd_data_o),
		.fifo_exp_1x1_data_count_o 				(w_fifo_exp_1x1_data_count),
		.fifo_exp_1x1_rd_en_i 					(fifo_exp_1x1_rd_en_i),
		.fifo_exp_1x1_empty_o 					(fifo_exp_1x1_empty_o)
	);

	
endmodule

