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

module exp_3x3_ker_read_cont(
	clk_i,
	rst_n_i,

	exp_3x3_ram_rd_addr_o,

	exp_3x3_kerl_req_i,
	exp_3x3_kerl_ready_o,

	start_i,
	one_exp3_ker_addr_limit_i,
	exp3_ker_depth_i,
	layer_dimension_i,

	layer_1_ready_i,
	layer_1_done_o,
	layer_2_ready_i,
	layer_2_done_o
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
		Configurations :-
		one_exp3_ker_addr_limit_i 	:- [NO of expand kernals / 4]
		exp3_ker_depth_i 	  		:- [depth - 1]
		layer_dimension_i 			:- [dimnision -1]
	*/
	
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// EXPAND 3x3 Kernal RAM Read Control Signals
	output 	reg 			[6:0] 									exp_3x3_ram_rd_addr_o;														

	// EXPAND 3x3 Kernal RAM Control Signals
	input 															exp_3x3_kerl_req_i;
	output 	reg	 													exp_3x3_kerl_ready_o;

	// Configuration Control Signals
	input 															start_i;
	input 						[6:0] 								one_exp3_ker_addr_limit_i;
	input 						[5:0] 								exp3_ker_depth_i;
	input 						[6:0]								layer_dimension_i;

	// EXPAND 3x3 RAM Layer Status COntrol Signal
	input  		 													layer_1_ready_i;
	output reg														layer_1_done_o;
	input  		 													layer_2_ready_i;
	output reg														layer_2_done_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Layer Control Signals
	reg  															r_chk_nxt_addr_limt;
	wire 					[6:0] 									w_rd_end_addr;
	wire 															w_layer_select;
	wire 															w_new_layer_flag;
	wire 															w_fire_end_flag;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// EXPAND 3x3 Kernal Ready
	always @(posedge clk_i) begin : EXP_3x3_KERL_READY
		if(~rst_n_i || start_i) begin
			exp_3x3_kerl_ready_o <= 0;
		end 
		else if(w_fire_end_flag && exp_3x3_kerl_ready_o) begin
			exp_3x3_kerl_ready_o <= ~exp_3x3_kerl_req_i;
		end 
		else begin
			exp_3x3_kerl_ready_o <= ((layer_1_ready_i || layer_2_ready_i) && ~w_fire_end_flag);
		end
	end

	// Layer Done
	always @(posedge clk_i) begin : LAYER_DONE_1
		if(~rst_n_i || start_i || layer_1_done_o) begin
			layer_1_done_o <= 0;
		end
		else if(exp_3x3_kerl_req_i)begin
			layer_1_done_o <= (w_layer_select && w_new_layer_flag);
		end
	end
	always @(posedge clk_i) begin : LAYER_DONE_2
		if(~rst_n_i || start_i || layer_2_done_o) begin
			layer_2_done_o <= 0;
		end
		else if(exp_3x3_kerl_req_i)begin
			layer_2_done_o <= (~w_layer_select && w_new_layer_flag);
		end
	end

	// EXPAND 3x3 RAM Read Address
	always @(posedge clk_i) begin : EXP_3X3_RAM_RDADDR
		if(~rst_n_i) begin
			exp_3x3_ram_rd_addr_o <= 0;
		end 
		else if(exp_3x3_kerl_req_i && exp_3x3_ram_rd_addr_o == w_rd_end_addr) begin
			exp_3x3_ram_rd_addr_o <= (w_layer_select) ? 64 : 0;
		end
		else if(exp_3x3_kerl_req_i) begin
			exp_3x3_ram_rd_addr_o <= exp_3x3_ram_rd_addr_o + 1;
		end
	end

	// Check Next Address Limit
	always @(posedge clk_i) begin : CHK_NXT_ADDR_LIMIT
		if(~rst_n_i || start_i) begin
			r_chk_nxt_addr_limt <= 0;
		end 
		else if(exp_3x3_kerl_req_i && r_chk_nxt_addr_limt) begin
			r_chk_nxt_addr_limt <= 0;
		end 
		else if(exp_3x3_kerl_req_i) begin
			r_chk_nxt_addr_limt <= (exp_3x3_ram_rd_addr_o == w_rd_end_addr - 4 && exp_3x3_kerl_ready_o);
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Read Config EXAPND 3x3
	read_config_exp_3x3 read_config_exp_3x3_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.one_exp3_ker_addr_limit_i 			(one_exp3_ker_addr_limit_i),
		.exp3_ker_depth_i 					(exp3_ker_depth_i),
		.layer_dimension_i 					(layer_dimension_i),

		.chk_nxt_addr_limt_i 				(r_chk_nxt_addr_limt),
		.exp_3x3_kerl_req_i 				(exp_3x3_kerl_req_i),
		.rd_end_addr_o 						(w_rd_end_addr),
		.layer_select_o 					(w_layer_select),
		.new_layer_flag_o 					(w_new_layer_flag),
		.fire_end_flag_o 					(w_fire_end_flag)
	);

endmodule

