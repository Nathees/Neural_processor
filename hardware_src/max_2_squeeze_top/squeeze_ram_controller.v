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

module squeeze_ram_controller(
	clk_i,
	rst_n_i,

	start_i,
	exp_1x1_en_i,
	tot_squ_addr_limit_i,
	squ_kernals_i,

	fifo_squ_3x3_rd_data_i,
	fifo_squ_3x3_rd_en_o,
	fifo_squ_3x3_empty_i,

	fifo_squ_1x1_rd_data_i,
	fifo_squ_1x1_rd_en_o,
	fifo_squ_1x1_empty_i,

	squ_data_req_i,
	squ_data_ready_o,
	squ_3x3_data_o,
	squ_1x1_data_o
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
	tot_squ_addr_limit_i 		:- [(dimension * depth / 2) / 8] - 1
	squ_kernals_i 				:- [No of squeeze kernal - 1]

	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfig Control Signals
	input 															start_i;
	input 															exp_1x1_en_i;
	input 				[8:0] 										tot_squ_addr_limit_i;
	input 				[9:0]										squ_kernals_i;

	// SQUEEZE 3x3 FIFO Control Signals
	input 				[95:0]										fifo_squ_3x3_rd_data_i;
	output 															fifo_squ_3x3_rd_en_o;
	input 															fifo_squ_3x3_empty_i;

	// SQUEEZE 3x3 FIFO Control Signals
	input 				[95:0]										fifo_squ_1x1_rd_data_i;
	output 															fifo_squ_1x1_rd_en_o;
	input 															fifo_squ_1x1_empty_i;

	// Squeeze Request data control Signals
	input 															squ_data_req_i;
	output 	reg 													squ_data_ready_o;
	output 				[95:0] 										squ_3x3_data_o;
	output 				[95:0] 										squ_1x1_data_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------


	// COnfig COntrol Signals
	reg 															r_exp_1x1_en;
	reg 				[8:0] 										r_tot_squ_addr_limit;
	reg 				[9:0] 										r_squ_kernals;

	reg 															r_kernal_flag;
	reg 				[9:0] 										r_kernal_count;

	// RAM COntrol Signls
	reg 															r_ram_busy;
	wire 															w_fifo_rd_en;

	reg 															r_ram_wr_en;
	reg 				[8:0] 										r_ram_wr_addr;
	wire 				[95:0] 										w_ram_3x3_wr_data;
	wire 				[95:0] 										w_ram_1x1_wr_data;
	reg 				[8:0] 										r_tot_addr;
	reg 				[8:0] 										r_ram_rd_addr;

	wire 				[107:0] 									w_ram_3x3_rd_data;
	wire 				[107:0] 									w_ram_1x1_rd_data;
	
//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// COnfiguration
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_exp_1x1_en 			<= 0;
			r_tot_squ_addr_limit 	<= 0;
			r_squ_kernals 			<= 0;
		end 
		else if(start_i) begin
			r_exp_1x1_en 			<= exp_1x1_en_i;
			r_tot_squ_addr_limit 	<= tot_squ_addr_limit_i;
			r_squ_kernals 			<= squ_kernals_i;
		end
	end

	// RAM Busy
	always @(posedge clk_i) begin : RAM_BUSY
		if(~rst_n_i || start_i) begin
			r_ram_busy <= 0;
		end 
		else if(squ_data_req_i && r_kernal_flag && r_kernal_count == r_squ_kernals) begin
			r_ram_busy <= 0;
		end
		else if(r_tot_addr == r_tot_squ_addr_limit && ~fifo_squ_3x3_empty_i) begin
			r_ram_busy <= 1;
		end
	end

	// FIFO read enable
	assign w_fifo_rd_en = (~fifo_squ_3x3_empty_i && ~r_ram_busy);
	assign fifo_squ_3x3_rd_en_o = w_fifo_rd_en;
	assign fifo_squ_1x1_rd_en_o = w_fifo_rd_en;

	// RAM Write Enable
	always @(posedge clk_i) begin : RAM_WR_EN
		if(~rst_n_i || start_i) begin
			r_ram_wr_en <= 0;
		end else begin
			r_ram_wr_en <= w_fifo_rd_en;
		end
	end

	// RAM Write Address
	always @(posedge clk_i) begin : RAM_WR_ADDR
		if(~rst_n_i || start_i) begin
			r_ram_wr_addr <= 0;
		end 
		else if(r_ram_wr_en && r_ram_wr_addr == r_tot_squ_addr_limit) begin
			r_ram_wr_addr <= 0;
		end 
		else if(r_ram_wr_en) begin
			r_ram_wr_addr <= r_ram_wr_addr + 1;
		end
	end
	always @(posedge clk_i) begin : TOT_ADDR
		if(~rst_n_i || start_i) begin
			r_tot_addr <= 0;
		end 
		else if(r_tot_addr == r_tot_squ_addr_limit && ~fifo_squ_3x3_empty_i) begin
			r_tot_addr <= 0;
		end 
		else if(w_fifo_rd_en) begin
			r_tot_addr <= r_tot_addr + 1;
		end
	end

	// Squeeze Data Ready
	always @(posedge clk_i) begin : SQU_DATA_READY
		if(~rst_n_i || start_i) begin
			squ_data_ready_o <= 0;
		end 
		else if(squ_data_req_i && r_kernal_flag && r_kernal_count == r_squ_kernals) begin
			squ_data_ready_o <= 0;
		end
		else if(r_ram_busy) begin
			squ_data_ready_o <= 1;
		end
	end

	// RAM Read Address
	always @(posedge clk_i) begin : RAM_RD_ADDR
		if(~rst_n_i || start_i) begin
			r_ram_rd_addr <= 0;
		end 
		else if(r_kernal_flag && squ_data_req_i) begin
			r_ram_rd_addr <= 0;
		end
		else if(squ_data_req_i) begin
			r_ram_rd_addr <= r_ram_rd_addr + 1;
		end
	end

	// Kernal Flag
	always @(posedge clk_i) begin : KERNAL_FLAG
		if(~rst_n_i || start_i) begin
			r_kernal_flag <= 0;
		end 
		else if(squ_data_req_i && r_kernal_flag) begin
			r_kernal_flag <= 0;
		end
		else if(squ_data_req_i) begin
			r_kernal_flag <= (r_ram_rd_addr == r_tot_squ_addr_limit - 1);  
		end
	end

	// Kernal Count
	always @(posedge clk_i) begin : KERNAL_COUNT
		if(~rst_n_i || start_i) begin
			r_kernal_count <= 0;
		end 
		else if(squ_data_req_i && r_kernal_flag && r_kernal_count == r_squ_kernals) begin
			r_kernal_count <= 0;
		end
		else if(squ_data_req_i && r_kernal_flag) begin
			r_kernal_count <= r_kernal_count + 1;
		end
	end

	// RAM Write Data
	assign w_ram_3x3_wr_data[95:48] = fifo_squ_3x3_rd_data_i[47:00];
	assign w_ram_3x3_wr_data[47:00] = fifo_squ_3x3_rd_data_i[95:48];

	assign w_ram_1x1_wr_data[95:48] = fifo_squ_1x1_rd_data_i[47:00];
	assign w_ram_1x1_wr_data[47:00] = fifo_squ_1x1_rd_data_i[95:48];

	// Squeeze data out
	assign squ_3x3_data_o = w_ram_3x3_rd_data[95:00];
	assign squ_1x1_data_o = w_ram_1x1_rd_data[95:00];
	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// SQUEEZE Ram 3x3 Instantiation
	squeeze_ram squeeze_ram_3x3_inst
	(
		.clock 								(clk_i),

		.data 								({12'd0,w_ram_3x3_wr_data}),
		.wraddress 							(r_ram_wr_addr),
		.wren 								(r_ram_wr_en),

		.rdaddress 							(r_ram_rd_addr),
		.q 									(w_ram_3x3_rd_data)
	);

	// SQUEEZE Ram 1x1 Instantiation
	squeeze_ram squeeze_ram_1x1_inst
	(
		.clock 								(clk_i),

		.data 								({12'd0,w_ram_1x1_wr_data}),
		.wraddress 							(r_ram_wr_addr),
		.wren 								(r_ram_wr_en),

		.rdaddress 							(r_ram_rd_addr),
		.q 									(w_ram_1x1_rd_data)
	);


endmodule

