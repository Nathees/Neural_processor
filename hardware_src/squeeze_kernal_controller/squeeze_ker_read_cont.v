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

module squeeze_ker_read_cont(
	clk_i,
	rst_n_i,

	start_i,
	repeat_en_i,
	one_squ_ker_addr_limit_i,
	squ_kernals_i,
	layer_dimension_i,
	tot_repeat_squ_kernals_i,

	squeeze_ram_rd_addr_o,

	squeeze_kerl_req_i,
	squeeze_kerl_ready_o,

	squeeze_layer_ready_no_i,
	conv_layer_ready_no_i,
	conv_rd_done_lay_flag_o
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
		one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8] 
		squ_kernals_i 				:- [No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
		layer_dimension_i 			:- [dimension - 1]
		tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
	*/
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// Configuration Control Signals
	input 															start_i;
	input 															repeat_en_i;
	input 						[5:0] 								one_squ_ker_addr_limit_i;
	input 						[5:0]								squ_kernals_i;   ///***************** conv
	input 						[6:0] 								layer_dimension_i;
	input 						[15:0] 								tot_repeat_squ_kernals_i;  ///***************** conv

	// Squeeze Kernal RAM Read Control Signals
	output 	reg 			[10:0] 									squeeze_ram_rd_addr_o;															

	// Squeeze Kernal RAM Control Signals
	input 															squeeze_kerl_req_i;
	output 	reg	 													squeeze_kerl_ready_o;

	// Squeeze Kernal RAM Write Control Signals
	input 		 			[6:0] 									squeeze_layer_ready_no_i;
	input 		 			[6:0] 									conv_layer_ready_no_i;
	output  	 													conv_rd_done_lay_flag_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Read Config Squeeze control Signals
	reg 															r_chk_nxt_addr_limt;
	wire 					[10:0] 									w_rd_addr_layr_start;
	wire 															w_rd_start_addr_flag;
	wire 					[10:0] 									w_rd_addr_layr_end;
	wire 															w_rd_end_addr_flag;
	wire 															w_repeat_en;
	wire 															w_fire_rd_done_flag;
	wire 															w_fire_rd_done_lay_flag;
	wire 															w_last_repeat_lay_flag;
	wire 															w_conv_rd_done_lay_flag;

	reg 					[10:0] 									r_rd_end_addr;

	// Squeeze Control Signals
	reg 					[5:0] 									r_rd_lay_done_count;
	wire 															w_rd_addr_enable_1;
	wire 															w_rd_addr_enable_2;
	reg 															r_rd_addr_enable;	
	reg 															r_fire_ready;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Read Layer Done Count
	always @(posedge clk_i) begin : READ_LAY_DONE_COUNT
		if(~rst_n_i || start_i) begin
			r_rd_lay_done_count <= 0;
		end 
		else if(squeeze_kerl_req_i && (w_fire_rd_done_lay_flag || w_conv_rd_done_lay_flag))begin
			r_rd_lay_done_count <= r_rd_lay_done_count + 1;
		end
	end

	// Squeeze RAM Read Address
	always @(posedge clk_i) begin : SQUEEZR_RAM_RDADDR
		if(~rst_n_i || start_i) begin
			squeeze_ram_rd_addr_o <= 0;
		end 
		else if(w_rd_start_addr_flag && squeeze_kerl_req_i) begin
			squeeze_ram_rd_addr_o <= w_rd_addr_layr_start;
		end
		else if(squeeze_kerl_req_i) begin
			squeeze_ram_rd_addr_o <= squeeze_ram_rd_addr_o + 1;
		end
	end

	// Read Address Enable
	assign w_rd_addr_enable_1 = ({1'b0,r_rd_lay_done_count} < squeeze_layer_ready_no_i);
	assign w_rd_addr_enable_2 = ({1'b0,r_rd_lay_done_count} < conv_layer_ready_no_i);
	always @(posedge clk_i) begin : READ_ADDR_ENABLE
		if(~rst_n_i) begin
			r_rd_addr_enable <= 0;
		end else begin
			r_rd_addr_enable <= (w_repeat_en) ? w_rd_addr_enable_2 : w_rd_addr_enable_1;
		end
	end

	// Squeeze Kernal Ready
	always @(posedge clk_i) begin : SQU_KERL_READY
		if(~rst_n_i || start_i) begin
			squeeze_kerl_ready_o <= 0;
		end 
		else if(w_fire_rd_done_flag && squeeze_kerl_ready_o) begin
			squeeze_kerl_ready_o <= ~squeeze_kerl_req_i;
		end 
		else begin
			squeeze_kerl_ready_o <= (r_rd_addr_enable && ~w_fire_rd_done_flag);
		end
	end

	// Layer Read End Address
	always @(posedge clk_i) begin : END_ADDRESS
		if(~rst_n_i) begin
			r_rd_end_addr <= 0;
		end 
		else if(w_rd_end_addr_flag) begin
			r_rd_end_addr <= w_rd_addr_layr_end - 5;
		end
	end

	// Check Next Address Limit
	always @(posedge clk_i) begin : CHK_NXT_ADDR_LIMIT
		if(~rst_n_i || start_i) begin
			r_chk_nxt_addr_limt <= 0;
		end
		else if(squeeze_kerl_req_i && r_chk_nxt_addr_limt) begin
			r_chk_nxt_addr_limt <= 0;
		end 
		else if(squeeze_kerl_req_i)begin
			r_chk_nxt_addr_limt <= (squeeze_ram_rd_addr_o == r_rd_end_addr);
		end
	end

	// Repeat Read done layer flag
	assign conv_rd_done_lay_flag_o = (squeeze_kerl_req_i && w_conv_rd_done_lay_flag);

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Read Config Squeeze
	read_config_squeeze read_config_squeeze_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.repeat_en_i 						(repeat_en_i),
		.one_squ_ker_addr_limit_i 			(one_squ_ker_addr_limit_i),
		.squ_kernals_i 						(squ_kernals_i),
		.layer_dimension_i 					(layer_dimension_i),
		.tot_repeat_squ_kernals_i 			(tot_repeat_squ_kernals_i),

		.chk_nxt_addr_limt_i 				(r_chk_nxt_addr_limt),
		.squeeze_kerl_req_i 				(squeeze_kerl_req_i),
		.rd_addr_layr_start_o 				(w_rd_addr_layr_start),
		.rd_start_addr_flag_o 				(w_rd_start_addr_flag),
		.rd_addr_layr_end_o 				(w_rd_addr_layr_end),
		.rd_end_addr_flag_o 				(w_rd_end_addr_flag),

		.repeat_en_o 						(w_repeat_en),
		.fire_rd_done_flag_o 				(w_fire_rd_done_flag),
		.fire_rd_done_lay_flag_o 			(w_fire_rd_done_lay_flag),
		.conv_rd_done_lay_flag_o 			(w_conv_rd_done_lay_flag)
	);
	
endmodule

