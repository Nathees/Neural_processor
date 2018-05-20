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

module exp_1x1_ker_read_cont(
	clk_i,
	rst_n_i,

	exp_1x1_ram_rd_addr_o,

	exp_1x1_kerl_req_i,
	exp_1x1_kerl_ready_o,

	start_i,
	exp_1x1_en_i,
	one_exp1_ker_addr_limit_i,
	exp1_ker_depth_i,
	layer_dimension_i,

	exp_1x1_layer_ready_no_i
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
	Configurations

	one_exp1_ker_addr_limit_i 	:- [NO of expand kernals / 4]
	exp1_ker_depth_i 	  		:- [depth - 1]
	layer_dimension_i 			:- [dimnision -1]

	*/
	
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// EXPAND 1X1 Kernal RAM Read Control Signals
	output 	reg 			[11:0] 									exp_1x1_ram_rd_addr_o;														

	// EXPAND 1X1 Kernal RAM Control Signals
	input 															exp_1x1_kerl_req_i;
	output 	reg	 													exp_1x1_kerl_ready_o;

	// COnfiguration Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 					[6:0] 									one_exp1_ker_addr_limit_i;
	input 					[5:0] 									exp1_ker_depth_i;
	input 					[6:0] 									layer_dimension_i;

	// EXPAND 1X1 Kernal RAM Write Control Signals
	input 		 			[6:0] 									exp_1x1_layer_ready_no_i;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Read Config Squeeze control Signals
	reg 															r_chk_nxt_fire_addr_limt;
	wire 					[11:0] 									w_rd_addr_layr_start;
	wire 															w_rd_start_addr_flag;
	wire 					[11:0] 									w_rd_addr_layr_end;
	wire 															w_rd_end_addr_flag;
	wire 															w_fire_rd_done_lay_flag;
	wire  															w_fire_rd_done_flag;
	wire 															w_exp_1x1_kerl_en;

	reg 					[11:0] 									r_rd_end_addr;

	// expand 1x1 Control Signals
	reg 					[5:0] 									r_rd_lay_done_count;
	reg 															r_data_select;
	wire 															w_rd_addr_enable;
	reg 															r_rd_addr_enable;	

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Read Layer Done Count
	always @(posedge clk_i) begin : READ_LAY_DONE_COUNT
		if(~rst_n_i || start_i) begin
			r_rd_lay_done_count <= 0;
		end 
		else if(w_fire_rd_done_lay_flag && exp_1x1_kerl_req_i)begin
			r_rd_lay_done_count <= r_rd_lay_done_count + 1;
		end
	end

	// EXPAND 1X1 RAM Read Address
	always @(posedge clk_i) begin : EXP_1X1_RAM_RDADDR
		if(~rst_n_i || start_i) begin
			exp_1x1_ram_rd_addr_o <= 0;
		end 
		else if(w_rd_start_addr_flag && exp_1x1_kerl_req_i) begin
			exp_1x1_ram_rd_addr_o <= w_rd_addr_layr_start;
		end
		else if(exp_1x1_kerl_req_i) begin
			exp_1x1_ram_rd_addr_o <= exp_1x1_ram_rd_addr_o + 1;
		end
	end

	
	// Read Address Enable
	assign w_rd_addr_enable = ({1'b0,r_rd_lay_done_count} < exp_1x1_layer_ready_no_i);
	always @(posedge clk_i) begin : READ_ADDR_ENABLE
		if(~rst_n_i || start_i) begin
			r_rd_addr_enable <= 0;
		end 
		else if(~w_exp_1x1_kerl_en) begin
			r_rd_addr_enable <= 1;
		end
		else begin
			r_rd_addr_enable <= w_rd_addr_enable;
		end
	end

	// EXPAND 1X1 Kernal Ready
	/*always @(posedge clk_i) begin : EXP_1X1_KERL_READY
		if(~rst_n_i) begin
			exp_1x1_kerl_ready_o <= 0;
		end else begin
			exp_1x1_kerl_ready_o <= (r_rd_addr_enable && ~w_fire_rd_done_flag);
		end
	end*/
	always @(posedge clk_i) begin : EXP_1X1_KERL_READY
		if(~rst_n_i || start_i) begin
			exp_1x1_kerl_ready_o <= 0;
		end 
		else if(w_fire_rd_done_flag && exp_1x1_kerl_ready_o) begin
			exp_1x1_kerl_ready_o <= ~exp_1x1_kerl_req_i;
		end 
		else begin
			exp_1x1_kerl_ready_o <= (r_rd_addr_enable && ~w_fire_rd_done_flag);
		end
	end

	// Layer Read End Address
	always @(posedge clk_i) begin : END_ADDRESS
		if(~rst_n_i) begin
			r_rd_end_addr <= 0;
		end 
		else if(w_rd_end_addr_flag) begin // exp_1x1_kerl_req_i
			r_rd_end_addr <= w_rd_addr_layr_end - 5;
		end
	end

	// Check Next Address Limit
	always @(posedge clk_i) begin : CHK_NXT_ADDR_LIMIT
		if(~rst_n_i || start_i) begin
			r_chk_nxt_fire_addr_limt <= 0;
		end
		else if(exp_1x1_kerl_req_i && r_chk_nxt_fire_addr_limt) begin
			r_chk_nxt_fire_addr_limt <= 0;
		end 
		else if(exp_1x1_kerl_req_i)begin
			r_chk_nxt_fire_addr_limt <= (exp_1x1_ram_rd_addr_o == r_rd_end_addr);
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Read Config EXAPND 1X1
	read_config_exp_1x1 read_config_exp_1x1_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.exp_1x1_en_i 							(exp_1x1_en_i),
		.one_exp1_ker_addr_limit_i 				(one_exp1_ker_addr_limit_i),
		.exp1_ker_depth_i 						(exp1_ker_depth_i),
		.layer_dimension_i 						(layer_dimension_i),

		.chk_nxt_fire_addr_limt_i 				(r_chk_nxt_fire_addr_limt),
		.exp_1x1_kerl_req_i 					(exp_1x1_kerl_req_i),
		.exp_1x1_kerl_en_o 						(w_exp_1x1_kerl_en),
		.rd_addr_layr_start_o 					(w_rd_addr_layr_start),
		.rd_start_addr_flag_o 					(w_rd_start_addr_flag),
		.rd_addr_layr_end_o 					(w_rd_addr_layr_end),
		.rd_end_addr_flag_o 					(w_rd_end_addr_flag),

		.fire_rd_done_flag_o 					(w_fire_rd_done_flag),
		.fire_rd_done_lay_flag_o 				(w_fire_rd_done_lay_flag)
	);

endmodule

