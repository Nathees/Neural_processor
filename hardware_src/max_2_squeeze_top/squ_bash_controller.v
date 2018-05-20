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

module squ_bash_controller(
	clk_i,
	rst_n_i,

	start_i,
	no_of_squ_kernals_i,
	squ_layer_dimension_i,

	fifo_squ_bash_clr_i,
	fifo_squ_bash_wr_data_i,
	fifo_squ_bash_wr_en_i,
	fifo_squ_bash_data_count_o,

	bash_req_i,
	bash_ram_ready_o,
	bash_data_o
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
		no_of_squ_kernals_i 			:- [NO of squeeze kernals - 1]
		squ_layer_dimension_i 			:- [Squeeze layer dimension - 1] // After max pool
	*/
//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfig Control Signals
	input 															start_i;
	input 					[9:0] 									no_of_squ_kernals_i;
	input 					[6:0] 									squ_layer_dimension_i;

	// Squeeze Bash FIFO COntrol Signals
	input 															fifo_squ_bash_clr_i;
	input 					[63:0] 									fifo_squ_bash_wr_data_i;
	input 															fifo_squ_bash_wr_en_i;
	output 					[6:0] 									fifo_squ_bash_data_count_o;

	// RAM Control Signals
	input 															bash_req_i;
	output 	reg 													bash_ram_ready_o;
	output 					[7:0] 									bash_data_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// COnfig
	reg 					[9:0] 									r_no_of_squ_kernals;
	reg 					[6:0] 									r_layer_dimension;

	// FIFO COntrol Signals
	reg 															r_fifo_rd_start;
	wire  															w_fifo_rd_en;
	wire 															w_fifo_empty;
	reg 					[9:0] 									r_tot_addr;

	// Ram COntrol Signasl
	wire 					[7:0] 									w_ram_wr_data;
	reg 					[9:0] 									r_ram_wr_addr;
	reg 															r_ram_wr_en;
	reg 					[9:0] 									r_ram_rd_addr;

	reg 					[6:0] 									r_col_count;
	reg 															r_kernal_flag;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// COnfig
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_no_of_squ_kernals <= 0;
			r_layer_dimension 	<= 0;
		end 
		else if(start_i) begin
			r_no_of_squ_kernals <= no_of_squ_kernals_i;
			r_layer_dimension 	<= squ_layer_dimension_i;
		end
	end

	// FIFO Read Start
	always @(posedge clk_i) begin : FIFO_RD_START
		if(~rst_n_i) begin
			r_fifo_rd_start <= 0;
		end 
		else if(start_i) begin
			r_fifo_rd_start <= 1;
		end
		else if(r_tot_addr == r_no_of_squ_kernals && w_fifo_rd_en) begin
			r_fifo_rd_start <= 0;
		end 
	end

	// FIFO Read enable
	assign w_fifo_rd_en = (~w_fifo_empty && r_fifo_rd_start);

	// Toatal Address
	always @(posedge clk_i) begin : TOT_ADDR
		if(~rst_n_i || start_i) begin
			r_tot_addr <= 0;
		end 
		else if(w_fifo_rd_en) begin
			r_tot_addr <= r_tot_addr + 1;
		end
	end

	// RAM Write Enable
	always @(posedge clk_i) begin : RAM_WR_EN
		if(~rst_n_i || start_i) begin
			r_ram_wr_en <= 0;
		end else begin
			r_ram_wr_en <= w_fifo_rd_en;
		end
	end

	// RAM Wr address
	always @(posedge clk_i) begin : RAM_WR_ADDR
		if(~rst_n_i || start_i) begin
			r_ram_wr_addr <= 0;
		end 
		else if(r_ram_wr_en) begin
			r_ram_wr_addr <= r_ram_wr_addr + 1;
		end
	end

	// Bash RAM Ready
	always @(posedge clk_i) begin : BASH_RAM_READY
		if(~rst_n_i || start_i) begin
			bash_ram_ready_o <= 0;
		end 
		else if(r_tot_addr == r_no_of_squ_kernals && w_fifo_rd_en) begin
			bash_ram_ready_o <= 1;
		end
	end

	// Layer Column Count
	always @(posedge clk_i) begin : COL_COUNT
		if(~rst_n_i || start_i) begin
			r_col_count <= 0;
		end 
		else if(bash_req_i && r_col_count == r_layer_dimension) begin
			r_col_count <= 0;
		end
		else if(bash_req_i) begin
			r_col_count <= r_col_count + 1;
		end
	end

	// Kernal Flag
	always @(posedge clk_i) begin : KERNAL_FLAG
		if(~rst_n_i || start_i) begin
			r_kernal_flag <= 0;
		end else begin
			r_kernal_flag <= (bash_req_i && r_col_count == r_layer_dimension);
		end
	end

	// RAM Read Address
	always @(posedge clk_i) begin : RAM_RD_ADDR
		if(~rst_n_i || start_i) begin
			r_ram_rd_addr <= 0;
		end 
		else if(r_kernal_flag && r_ram_rd_addr == r_no_of_squ_kernals) begin
			r_ram_rd_addr <= 0;
		end 
		else if(r_kernal_flag) begin
			r_ram_rd_addr <= r_ram_rd_addr + 1;
		end
	end

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Squeeze BASH FIFO
	squ_bash_fifo squ_bash_fifo_inst
	(
		.aclr 				(fifo_squ_bash_clr_i),

		.wrclk 				(clk_i),
		.data 				(fifo_squ_bash_wr_data_i),
		.wrreq 				(fifo_squ_bash_wr_en_i),
		.wrusedw 			(fifo_squ_bash_data_count_o),

		.rdclk 				(clk_i),
		.rdreq 				(w_fifo_rd_en),
		.q 					(w_ram_wr_data),
		.rdempty 			(w_fifo_empty)
	);

	// EXPAND BASH Ram
	squ_bash_ram squ_bash_ram_inst
	(
		.clock 				(clk_i),

		.data 				(w_ram_wr_data),
		.wraddress 			(r_ram_wr_addr),
		.wren 				(r_ram_wr_en),

		.rdaddress 			(r_ram_rd_addr),
		.q 					(bash_data_o)
	);

endmodule

