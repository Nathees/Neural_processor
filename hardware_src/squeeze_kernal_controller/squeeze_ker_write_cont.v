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

module squeeze_ker_write_cont(
	clk_i,
	rst_n_i,

	start_i,
	repeat_en_i,
	tot_squ_ker_addr_limit_i,
	one_squ_ker_addr_limit_i,
	tot_repeat_squ_kernals_i,

	fifo_squeeze_clr_i,
	fifo_squeeze_wr_data_i,
	fifo_squeeze_wr_en_i,
	fifo_squeeze_data_count_o,

	squeeze_ram_wr_data_o,
	squeeze_ram_1_wr_addr_o,
	squeeze_ram_2_wr_addr_o,
	squeeze_ram_1_wr_en_o,
	squeeze_ram_2_wr_en_o,

	squeeze_layer_ready_no_o,
	conv_layer_ready_no_o,
	conv_rd_done_lay_flag_i
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

	// State Decleration
	localparam 								IDEAL 	 					=	2'b00;
	localparam								CHK_ADDR 					=	2'b01;
	localparam 								LOAD_RAM 					=	2'b10;
	localparam 								CHECK_FREE 					=	2'b11;

	/*
		tot_squ_ker_addr_limit_i 	:- [(NO of squeeze kernals * depth / 8 ] - 1
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i; 

	// COnfiguration Control Signals
	input 															start_i;
	input 															repeat_en_i;
	input 					[11:0] 									tot_squ_ker_addr_limit_i;
	input 					[5:0] 									one_squ_ker_addr_limit_i;
	input 					[15:0] 									tot_repeat_squ_kernals_i;

	// Squeeze Kernal FIFO control Signals
	input 															fifo_squeeze_clr_i;
	input 					[63:0]									fifo_squeeze_wr_data_i;
	input 															fifo_squeeze_wr_en_i;
	output 					[7:0] 									fifo_squeeze_data_count_o;															

	// Squeeze Kernal RAM Write Control Signals
	output 					[63:0] 									squeeze_ram_wr_data_o;
	output 	reg 			[10:0] 									squeeze_ram_1_wr_addr_o;
	output 	reg 			[10:0] 									squeeze_ram_2_wr_addr_o;
	output 	reg 				 									squeeze_ram_1_wr_en_o;
	output 	reg 				 									squeeze_ram_2_wr_en_o;

	// Squeeze Kernal RAM Read Control Signals
	output 	reg 			[6:0] 									squeeze_layer_ready_no_o;
	output 	reg 			[6:0] 									conv_layer_ready_no_o;
	input 															conv_rd_done_lay_flag_i;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze FIFO Read Port Control Signals
	wire 															w_fifo_rd_en;
	wire 															w_fifo_empty;

	// Squeeze Kernal RAM Write Contro Signals
	reg 															r_ram_wr_pause;	
	reg 															r_ram_select;

	// FIRE Layer Control Signals
	reg 					[11:0] 									r_total_addr;
	wire					[11:0] 									w_wr_addr_per_fire;
	wire 					[5:0] 									w_wr_addr_per_layr;
	wire 					[6:0] 									w_repeat_wr_addr_per_layr;
	wire 															w_repeat_en;
	wire 															w_repeat_flag;
	wire 					[15:0] 									w_tot_repeat_squ_kernals;

	reg 					[5:0] 									r_kernal_count;	
	reg 					[2:0] 									r_fire_count;

	// CONV 10 Layer Control Signals
	reg 					[1:0] 									state;
	reg 					[11:0] 									r_conv_wr_end_addr;
	reg 					[15:0] 									r_conv_tot_lay_count;
	reg 					[5:0] 									r_conv_done_count;
	reg 															r_load_nxt_conv_layer_flag;
	reg 					[5:0] 									r_conv_lay_ready_no_temp;
	reg 															r_conv_override_flag;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze FIFO Read Enable
	assign w_fifo_rd_en = (~w_fifo_empty && ~r_ram_wr_pause);

	// Squeeze RAM Write Address
	always @(posedge clk_i) begin : RAM_1_WR_ADDR
		if(~rst_n_i || start_i) begin
			squeeze_ram_1_wr_addr_o <= 0;
		end 
		else if(squeeze_ram_1_wr_en_o) begin
			squeeze_ram_1_wr_addr_o <= squeeze_ram_1_wr_addr_o + 1;
		end
	end
	always @(posedge clk_i) begin : RAM_2_WR_ADDR
		if(~rst_n_i || start_i) begin
			squeeze_ram_2_wr_addr_o <= 0;
		end 
		else if(squeeze_ram_2_wr_en_o) begin
			squeeze_ram_2_wr_addr_o <= squeeze_ram_2_wr_addr_o + 1;
		end
	end
	always @(posedge clk_i) begin : TOTAL_ADDR
		if(~rst_n_i || start_i) begin
			r_total_addr <= 0;
		end 
		else if(w_fifo_rd_en) begin
			r_total_addr <= r_total_addr + 1;
		end
	end

	// Squeeze RAM Select
	always @(posedge clk_i) begin : RAM_SELECT
		if(~rst_n_i || start_i) begin
			r_ram_select <= 0;
		end 
		else if(w_fifo_rd_en) begin
			r_ram_select <= ~r_ram_select;
		end
	end
	// Squeeze RAM Write Enable
	always @(posedge clk_i) begin : RAM_WR_ENABLE
		if(~rst_n_i || start_i) begin
			squeeze_ram_1_wr_en_o <= 0;
			squeeze_ram_2_wr_en_o <= 0;
		end else begin
			squeeze_ram_1_wr_en_o <= (w_fifo_rd_en && ~r_ram_select);
			squeeze_ram_2_wr_en_o <= (w_fifo_rd_en && r_ram_select);
		end
	end

	// Squeeze RAM Write Pause
	always @(posedge clk_i) begin : RAM_WR_PAUSE
		if(~rst_n_i) begin
			r_ram_wr_pause <= 1;
		end 
		else if(start_i || state == CHK_ADDR) begin
			r_ram_wr_pause <= 0;
		end
		else if(~w_repeat_en && r_total_addr == w_wr_addr_per_fire && ~w_fifo_empty) begin
			r_ram_wr_pause <= 1;
		end
		else if(state == LOAD_RAM && r_total_addr == r_conv_wr_end_addr && ~w_fifo_empty ) begin
			r_ram_wr_pause <= 1;
		end
	end

	// Kernal Count within a layer
	always @(posedge clk_i) begin : KERNAL_COUNT
		if(~rst_n_i || start_i) begin
			r_kernal_count <= 0;
		end 
		else if(w_repeat_en || (squeeze_ram_2_wr_en_o && r_kernal_count == w_wr_addr_per_layr)) begin
			r_kernal_count <= 0;
		end
		else if(squeeze_ram_2_wr_en_o) begin
			r_kernal_count <= r_kernal_count + 1;
		end
	end

	// Squeeze Layer Ready Number
	always @(posedge clk_i) begin : SQUEEZE_LAYER_READY_NO
		if(~rst_n_i || w_repeat_en || start_i) begin
			squeeze_layer_ready_no_o <= 0;
		end 
		else if(squeeze_ram_2_wr_en_o && r_kernal_count == w_wr_addr_per_layr) begin
			squeeze_layer_ready_no_o <= squeeze_layer_ready_no_o + 1;
		end
	end

	// FSM for CONV Layer
	always @(posedge clk_i) begin : FSM_CONV
		if(~rst_n_i || start_i) begin
			state <= IDEAL;
			r_conv_wr_end_addr <= 0;
			r_conv_tot_lay_count <= 0;
		end else begin
			case(state)
				IDEAL 		:	begin
									r_conv_wr_end_addr <= 0;
									r_conv_tot_lay_count <= 0;
									if(w_repeat_flag)
										state <= CHK_ADDR;
								end
				CHK_ADDR 	:	begin
									state <= LOAD_RAM;
									r_conv_wr_end_addr <= r_conv_wr_end_addr + w_repeat_wr_addr_per_layr; // 31  63
								end
				LOAD_RAM 	:	begin
									if(r_ram_wr_pause) begin
										state <= CHECK_FREE;
										r_conv_tot_lay_count <= r_conv_tot_lay_count + 1;
									end
								end
				CHECK_FREE 	:	begin
									if(r_load_nxt_conv_layer_flag)  begin
										if(r_conv_tot_lay_count == w_tot_repeat_squ_kernals)
											state <= IDEAL;
										else begin
											state <= CHK_ADDR;
											r_conv_wr_end_addr <= r_conv_wr_end_addr + 1;
										end
									end
								end
			endcase
		end
	end

	// Conv Layer Count
	always @(posedge clk_i) begin : CONV_LAYER_COUNT
		if(~rst_n_i || start_i) begin
			r_conv_done_count <= 0;
		end 
		else if(conv_rd_done_lay_flag_i) begin
			r_conv_done_count <= r_conv_done_count + 1;
		end
	end

	// CONV Layer Ready Number
	always @(posedge clk_i) begin : CONV_LAYER_READY_NO_TEMP
		if(~rst_n_i || start_i) begin
			r_conv_lay_ready_no_temp <= 0;
		end 
		else if(state == LOAD_RAM && r_ram_wr_pause) begin
			r_conv_lay_ready_no_temp <= r_conv_lay_ready_no_temp + 1;
		end
	end
	always @(posedge clk_i) begin : CONV_LAYER_READY_NO
		if(~rst_n_i || start_i) begin
			conv_layer_ready_no_o <= 0;
		end 
		else if(r_conv_override_flag) begin 
			conv_layer_ready_no_o <= 64;
		end
		else begin 
			conv_layer_ready_no_o <= {1'b0, r_conv_lay_ready_no_temp};
		end
	end
	
	// Conv Override Flag
	always @(posedge clk_i) begin : CONV_OVERRIDE_FLAG
		if(~rst_n_i || start_i) begin
			r_conv_override_flag <= 0;
		end 
		else if(state == LOAD_RAM && r_ram_wr_pause && r_conv_lay_ready_no_temp == 63) begin
			r_conv_override_flag <= 1;
		end
		else if(r_conv_override_flag && conv_rd_done_lay_flag_i && r_conv_done_count == 63) begin
			r_conv_override_flag <= 0;
		end
	end

	// Load next conv layer flag
	always @(posedge clk_i) begin : LOAD_NXT_CONV_LAYER
		if(~rst_n_i || start_i) begin
			r_load_nxt_conv_layer_flag <= 0;
		end 
		else if(state == CHECK_FREE && ~r_conv_override_flag) begin
			r_load_nxt_conv_layer_flag <= 1;
		end
		else if(state == CHECK_FREE && r_conv_override_flag && r_conv_lay_ready_no_temp < r_conv_done_count) begin
			r_load_nxt_conv_layer_flag <= 1;
		end
		else begin
			r_load_nxt_conv_layer_flag <= 0;
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze Kernal fifo instantiation
	squeeze_kernal_fifo squeeze_kernal_fifo_inst
	(
		.clock 									(clk_i),
		.aclr 									(fifo_squeeze_clr_i), //(~rst_n_i),

		.data 									(fifo_squeeze_wr_data_i),
		.wrreq 									(fifo_squeeze_wr_en_i),
		.usedw 									(fifo_squeeze_data_count_o),

		.q 										(squeeze_ram_wr_data_o),
		.rdreq 									(w_fifo_rd_en),
		.empty 									(w_fifo_empty)
	);

	// Write Configuration for Squeeze module Instantiation
	write_config_squeeze write_config_squeeze_inst
	(
		.clk_i 									(clk_i),
		.rst_n_i 								(rst_n_i),

		.start_i 								(start_i),
		.repeat_en_i 							(repeat_en_i),
		.tot_squ_ker_addr_limit_i 				(tot_squ_ker_addr_limit_i),
		.one_squ_ker_addr_limit_i 				(one_squ_ker_addr_limit_i),
		.tot_repeat_squ_kernals_i 				(tot_repeat_squ_kernals_i),
	
		.repeat_en_o 							(w_repeat_en),
		.repeat_flag_o 							(w_repeat_flag),
		.wr_addr_per_fire_o 					(w_wr_addr_per_fire),
		.wr_addr_per_layr_o 					(w_wr_addr_per_layr),
		.tot_repeat_squ_kernals_o 				(w_tot_repeat_squ_kernals),
		.repeat_wr_addr_per_layr_o 				(w_repeat_wr_addr_per_layr)
	);

endmodule

