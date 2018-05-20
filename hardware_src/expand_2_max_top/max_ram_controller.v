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

module max_ram_controller(
	clk_i,
	rst_n_i,

	start_i,
	max_en_i,
	exp_123_addr_space_i,
	exp_12_addr_space_i,
	exp_1_addr_space_i,
	exp_tot_addr_space_i,
	max_tot_addr_space_i,

	expand_3x3_data_i,
	expand_1x1_data_i,
	expand_flag_i,

	max_3x3_rd_data_i,
	max_1x1_rd_data_i,
	max_rd_addr_o,
	max_ready_flag_i,

	exp_lst_layer_flag_i,
	squeeze_fifo_busy_o,

	fifo_squeeze_3x3_rd_data_o,
	fifo_squeeze_3x3_rd_en_i,
	fifo_squeeze_3x3_empty_o,

	fifo_squeeze_1x1_rd_data_o,
	fifo_squeeze_1x1_rd_en_i,
	fifo_squeeze_1x1_empty_o
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

	// States Decleration
	localparam 								IDEAL 				=		2'b00;
	localparam 								MAX_OPER 			=		2'b01;
	localparam 								DECISION 			=		2'b10;	
	localparam 								SEND_DATA  			= 		2'b11;	
	/*

	Configurations :- 
	exp_123_addr_space_i 		:- [expand kernal / 4 * 3] - 1 	
	exp_12_addr_space_i 		:- [expand kernal / 4 * 2]
	exp_1_addr_space_i 			:- [expand kernal / 4 * 1] - 1
	exp_tot_addr_space_i 		:- [expand layer dim * expand kernal / 4] - 2
	max_tot_addr_space_i 		:- [max layer dim * expand kernal / 4] - 2

	*/		

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// Config Control Signals
	input 															start_i;
	input 															max_en_i;
	input 				[7:0] 										exp_123_addr_space_i;
	input 				[7:0] 										exp_12_addr_space_i;
	input 				[7:0] 										exp_1_addr_space_i;
	input 				[10:0] 										exp_tot_addr_space_i;
	input 				[9:0] 										max_tot_addr_space_i;

	// MAX Pool COntrol Signals
	input  				[47:0]										expand_3x3_data_i;
	input  				[47:0]										expand_1x1_data_i;
	input 															expand_flag_i;

	input 				[47:0] 										max_3x3_rd_data_i;
	input 				[47:0] 										max_1x1_rd_data_i;
	output reg			[10:0] 										max_rd_addr_o;
	input 		 													max_ready_flag_i;

	input 															exp_lst_layer_flag_i;
	output 	reg 													squeeze_fifo_busy_o;

	// Squeeze 3x3 FIFO Control Signals
	output 				[95:0] 										fifo_squeeze_3x3_rd_data_o;
	input 															fifo_squeeze_3x3_rd_en_i;
	output 															fifo_squeeze_3x3_empty_o;

	// Squeeze 1x1 FIFO Control Signals
	output 				[95:0] 										fifo_squeeze_1x1_rd_data_o;
	input 															fifo_squeeze_1x1_rd_en_i;
	output 															fifo_squeeze_1x1_empty_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// COnfig Control Signals
	reg 															r_max_en;
	reg  				[7:0]										r_exp_123_addr_space;
	reg  				[7:0]										r_exp_12_addr_space;
	reg  				[7:0]										r_exp_max_1_addr_space;
	reg 				[10:0] 										r_exp_tot_addr_apace;
	reg 				[9:0] 										r_max_tot_addr_apace;

	// State Control Signals
	reg 				[1:0] 										state;
	reg 				[2:0] 										r_max_oper_end_flag; 
	reg 															r_max_oper_flag;

	// EXPAND RAM COntrol Signals
	reg 				[1:0] 										r_line_count;
	reg 				[1:0]										r_maxpool_en;
	wire 															w_maxpool_en;
	wire 															w_exp_end_flag;
	reg 															r_exp_end_flag;
	reg 															r_update_exp_addr;

	// Expand RAM Address Space Control Signals
	reg 				[10:0] 										r_exp_strt_addr;
	reg 				[10:0] 										r_exp_end_addr;
	reg 				[10:0] 										r_exp_1_addr;

	// MAX Ram COntrol Signals
	reg 															r_update_max_rd_addr;
	reg 				[2:0] 										r_update_max_wr_addr;

	reg 				[9:0] 										r_max_strt_addr;
	reg 				[9:0] 										r_max_end_addr;
	reg 				[1:0] 										r_max_1_addr_space_count;
	wire 															w_max_send_end_flag;
	reg 															r_max_send_end_flag;
	reg 															r_max_ram_rd_en;
	reg 															r_max_data_flag;
	wire 															w_max_wr_end_flag;

	// Block RAM Control Signals
	wire 				[47:0] 										w_max_ram_3x3_wr_data;
	wire 				[47:0] 										w_max_ram_1x1_wr_data;
	wire 				[63:0] 										w_max_ram_3x3_rd_data;
	wire 				[63:0] 										w_max_ram_1x1_rd_data;

	reg 				[9:0] 										r_max_ram_wr_addr;
	reg 				[9:0] 										r_max_ram_rd_addr;
	reg 															r_max_ram_wr_en;
	reg 				[2:0] 										r_max_ram_wr_en_temp;

	// FIFO Control Signals
	reg 				[47:0] 										r_fifo_3x3_wr_data;
	reg 				[47:0] 										r_fifo_1x1_wr_data;
	reg 															r_fifo_wr_en;
	wire 				[8:0] 										w_wr_3x3_data_count;

	// Busy Contol Signal
	reg 															r_busy_1;
	reg 															r_busy_2;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Configuration
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_max_en 				<= 0;
			r_exp_123_addr_space 	<= 0;
			r_exp_12_addr_space 	<= 0;
			r_exp_max_1_addr_space 	<= 0;
			r_exp_tot_addr_apace 	<= 0;
			r_max_tot_addr_apace 	<= 0;
		end 
		else if(start_i) begin
			r_max_en 				<= max_en_i;
			r_exp_123_addr_space 	<= exp_123_addr_space_i;
			r_exp_12_addr_space 	<= exp_12_addr_space_i;
			r_exp_max_1_addr_space 	<= exp_1_addr_space_i;
			r_exp_tot_addr_apace 	<= exp_tot_addr_space_i;
			r_max_tot_addr_apace 	<= max_tot_addr_space_i;
		end
	end

	// FSM
	always @(posedge clk_i) begin : FSM_MAX
		if(~rst_n_i || start_i) 
			state <= IDEAL;
		else begin
			case(state)
				IDEAL 		:	if(max_ready_flag_i) 
									state <= MAX_OPER;
				MAX_OPER 	:	if(w_exp_end_flag) 
									state <= DECISION;
				DECISION 	:	if(r_line_count == 2)  
									state <= SEND_DATA;
								else if(r_line_count == 3)  
									state <= MAX_OPER;
								else 
									state <= IDEAL;
				SEND_DATA 	:	if(w_max_send_end_flag) 
									state <= DECISION;

			endcase
		end
	end

	// MAX Operation Flag
	always @(posedge clk_i) begin : MAX_OPER_FLAG
		if(~rst_n_i || start_i) begin
			r_max_oper_end_flag <= 0;
			r_max_oper_flag <= 0;
		end else begin
			r_max_oper_flag <= (state == MAX_OPER);
			r_max_oper_end_flag[0:0] <= (state != MAX_OPER);
			r_max_oper_end_flag[1:1] <= r_max_oper_end_flag[0:0];
			r_max_oper_end_flag[2:2] <= r_max_oper_end_flag[1:1];
		end
	end

	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////    EXPAND RAM READ Address Control Signals   ///////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////

	// EXPAND RAM Read Address
	always @(posedge clk_i) begin : EXPAND_RAM_RD_ADDR
		if(~rst_n_i || state != MAX_OPER) begin
			max_rd_addr_o <= 0;
		end 
		else if(r_update_exp_addr) begin
			max_rd_addr_o <= r_exp_strt_addr;
		end
		else begin
			max_rd_addr_o <= max_rd_addr_o + 1;
		end
	end

	// MAX END Flag
	assign w_exp_end_flag = (max_rd_addr_o == r_exp_tot_addr_apace);
	always @(posedge clk_i) begin : MAX_END_FLAG
		if(~rst_n_i || start_i) begin
			r_exp_end_flag <= 0;
		end else begin
			r_exp_end_flag <= w_exp_end_flag;
		end
	end

	// EXPAND Start and End Address
	always @(posedge clk_i) begin : EXPAND_START_ADDR
		if(~rst_n_i || r_max_oper_end_flag[0:0]) begin // state != MAX_OPER
			r_exp_strt_addr <= 0;
			r_exp_end_addr <= {3'b0,r_exp_123_addr_space};
			r_exp_1_addr <= {3'b0,r_exp_max_1_addr_space};
		end 
		else if(max_rd_addr_o == r_exp_end_addr - 1) begin
			r_exp_strt_addr <= r_exp_strt_addr + {3'b0,r_exp_12_addr_space};
			r_exp_end_addr <= r_exp_end_addr + {3'b0,r_exp_12_addr_space};
			r_exp_1_addr <= r_exp_1_addr + {3'b0,r_exp_12_addr_space};
		end
	end
	always @(posedge clk_i) begin : EXPAND_ADDR_UPDATE
		if(~rst_n_i || r_update_exp_addr || start_i) begin
			r_update_exp_addr <= 0;
		end 
		else if(max_rd_addr_o == r_exp_end_addr - 1) begin
			r_update_exp_addr <= 1;
		end
	end

	// MAX POOL Enable
	always @(posedge clk_i) begin : MAX_POOL_EN
		if(~rst_n_i || start_i) begin
			r_maxpool_en <= 0;
		end
		else if(state == DECISION && r_line_count == 3)
			r_maxpool_en <= 0;
		else begin
			r_maxpool_en[0:0] <= (max_rd_addr_o > r_exp_1_addr || r_line_count != 0);
			r_maxpool_en[1:1] <= r_maxpool_en[0:0];
		end
	end
	assign w_maxpool_en = (r_maxpool_en[0:0] || r_maxpool_en[1:1]);

	// Line COunt
	always @(posedge clk_i) begin : LINE_COUNT
		if(~rst_n_i || start_i) begin
			r_line_count <= 0;
		end 
		else if(state == DECISION)begin
			r_line_count <= r_line_count + 1;
		end
	end

	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////    MAX RAM  Control Signals   //////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////

	// MAX RAM Read address
	always @(posedge clk_i) begin : MAX_RAM_RD_ADDR
		if(~rst_n_i || state == IDEAL || state == DECISION) begin
			r_max_ram_rd_addr <= 0;
		end 
		else if(r_update_max_rd_addr)begin
			r_max_ram_rd_addr <= r_max_strt_addr;
		end
		else if(r_max_ram_rd_en) begin
			r_max_ram_rd_addr <= r_max_ram_rd_addr + 1;
		end
	end

	// MAX End Flag
	assign w_max_send_end_flag = (r_max_ram_rd_addr == r_max_tot_addr_apace && r_max_ram_rd_en && state == SEND_DATA);
	always @(posedge clk_i) begin : MAX_SEND_END_FLAG
		if(~rst_n_i || start_i) begin
			r_max_send_end_flag <= 0;
		end else begin
			r_max_send_end_flag <= w_max_send_end_flag;
		end
	end

	// MAX Start and End Address
	always @(posedge clk_i) begin : MAX_ADDR_SPACE
		if(~rst_n_i || state != MAX_OPER) begin /// state != MAX_OPER r_max_oper_end_flag[2:2]
			r_max_strt_addr <= 0;
			r_max_end_addr <= {2'b0,r_exp_max_1_addr_space};
		end 
		else if(r_max_ram_rd_addr == r_max_end_addr - 1 && r_max_1_addr_space_count == 2) begin
			r_max_strt_addr <= r_max_strt_addr + {2'b0,r_exp_max_1_addr_space} + 1;
			r_max_end_addr <= r_max_end_addr + {2'b0,r_exp_max_1_addr_space} + 1;
		end
	end
	always @(posedge clk_i) begin : MAX_RD_ADDR_UPDATE
		if(~rst_n_i || r_update_max_rd_addr) begin
			r_update_max_rd_addr <= 0;
		end 
		else if(state == MAX_OPER && r_max_ram_rd_addr == r_max_end_addr - 1) begin
			r_update_max_rd_addr <= 1;
		end
	end
	always @(posedge clk_i) begin : MAX_WR_ADDR_UPDATE
		if(~rst_n_i || start_i) begin
			r_update_max_wr_addr <= 0;
		end else begin
			r_update_max_wr_addr[0:0] <= r_update_max_rd_addr;
			r_update_max_wr_addr[1:1] <= r_update_max_wr_addr[0:0];
			r_update_max_wr_addr[2:2] <= r_update_max_wr_addr[1:1];
		end
	end

	// MAX 1 Addr space count
	always @(posedge clk_i) begin : MAX_1_ADDR_SPAC_COUNT
		if(~rst_n_i || (r_max_ram_rd_addr == r_max_end_addr - 1 && r_max_1_addr_space_count == 2) || start_i) begin
			r_max_1_addr_space_count <= 0;
		end 
		else if(state == DECISION || r_max_send_end_flag) begin
			r_max_1_addr_space_count <= 0;
		end
		else if(r_max_ram_rd_addr == r_max_end_addr - 1) begin
			r_max_1_addr_space_count <= r_max_1_addr_space_count + 1;
		end
	end

	// MAX RAM Read ENable
	always @(posedge clk_i) begin : MAX_RAM_RD_EN
		if(~rst_n_i || start_i) begin
			r_max_ram_rd_en <= 0;
		end 
		else if(state == SEND_DATA) begin 		
			r_max_ram_rd_en <= (w_wr_3x3_data_count < 500); 
		end
		else begin
			r_max_ram_rd_en <= (max_ready_flag_i || state == MAX_OPER || (state == DECISION && r_line_count == 3));
		end
	end

	// MAX Data flag
	always @(posedge clk_i) begin : MAX_DATA_FLAG
		if(~rst_n_i) begin
			r_max_data_flag <= 0;
		end else begin
			r_max_data_flag <= ((state == SEND_DATA && r_max_ram_rd_en) || r_max_send_end_flag);
		end
	end

	// MAX Ram Write Address
	always @(posedge clk_i) begin : MAX_RAM_WR_ADDR
		if(~rst_n_i || r_max_oper_end_flag[2:2]) begin //  state != MAX_OPER
			r_max_ram_wr_addr <= 0;
		end 
		else if(r_update_max_wr_addr[2:2] && r_max_ram_wr_en) begin
			r_max_ram_wr_addr <= r_max_strt_addr;
		end
		else if(r_max_ram_wr_en) begin
			r_max_ram_wr_addr <= r_max_ram_wr_addr + 1;
		end
	end

	// MAX Wr addr End Flag
	assign w_max_wr_end_flag = (r_max_ram_wr_addr == r_max_tot_addr_apace);

	// MAX RAM Write enable
	always @(posedge clk_i) begin : MAX_WR_EN
		if(~rst_n_i || start_i) begin
			r_max_ram_wr_en <= 0;
			r_max_ram_wr_en_temp <= 0;
		end else begin
			r_max_ram_wr_en_temp[0:0] <= (state == MAX_OPER || r_max_oper_flag);
			r_max_ram_wr_en_temp[1:1] <= r_max_ram_wr_en_temp[0:0];
			r_max_ram_wr_en <= r_max_ram_wr_en_temp[1:1];
		end
	end

	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////    FIFO   Control Signals        ///////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////

	// FIFO Write Data
	always @(posedge clk_i) begin : FIFO_WR_DATA
		if(~rst_n_i) begin
			r_fifo_3x3_wr_data <= 0;
			r_fifo_1x1_wr_data <= 0;
		end else begin
			r_fifo_3x3_wr_data <= (expand_flag_i) ? expand_3x3_data_i : w_max_ram_3x3_rd_data[47:00];
			r_fifo_1x1_wr_data <= (expand_flag_i) ? expand_1x1_data_i : w_max_ram_1x1_rd_data[47:00];
		end
	end

	// FIFO Write EN
	always @(posedge clk_i) begin : FIFO_WR_EN
		if(~rst_n_i || start_i) begin
			r_fifo_wr_en <= 0;
		end else begin
			r_fifo_wr_en <= (expand_flag_i || r_max_data_flag); 
		end
	end

	////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////    BUSY   Control Signals        ///////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////

	// MAX_OPERATION BUSY
	always @(posedge clk_i) begin : BUSY_1
		if(~rst_n_i) begin
			r_busy_1 <= 0;
		end else begin
			r_busy_1 <= (state != IDEAL && exp_lst_layer_flag_i && w_wr_3x3_data_count > 500);
		end
	end

	// Expand Operation Busy
	always @(posedge clk_i) begin : BUSY_2
		if(~rst_n_i) begin
			r_busy_2 <= 0;
		end else begin
			r_busy_2 <= (~r_max_en && exp_lst_layer_flag_i && w_wr_3x3_data_count > 500);
		end
	end

	// Squeeze FIFO Busy
	always @(posedge clk_i) begin : SQUEEZE_FIFO_BUSY
		if(~rst_n_i) begin
			squeeze_fifo_busy_o <= 0;
		end else begin
			squeeze_fifo_busy_o <= (r_busy_1 || r_busy_2);
		end
	end


//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// MAX-RAM 3x3 Instantiation
	max_ram max_3x3_ram_inst
	(
		.clock 							(clk_i),

		.data 							({16'd0,w_max_ram_3x3_wr_data}),
		.wraddress 						(r_max_ram_wr_addr),
		.wren 							(r_max_ram_wr_en),

		.rdaddress 						(r_max_ram_rd_addr),
		.q 								(w_max_ram_3x3_rd_data)
	);

	// MAX-RAM 1x1 Instantiation
	max_ram max_1x1_ram_inst
	(
		.clock 							(clk_i),

		.data 							({16'd0,w_max_ram_1x1_wr_data}),
		.wraddress 						(r_max_ram_wr_addr),
		.wren 							(r_max_ram_wr_en),

		.rdaddress 						(r_max_ram_rd_addr),
		.q 								(w_max_ram_1x1_rd_data)
	);

	// MAX-POOL 3x3 Instantiation
	max_pool max_pool_3x3_inst
	(
		.clk_i 							(clk_i),
		.rst_n_i 						(rst_n_i),

		.data_1_i 						(max_3x3_rd_data_i),
		.data_2_i 						(w_max_ram_3x3_rd_data[47:00]),
		.data_max_o 					(w_max_ram_3x3_wr_data),
		.max_en_i 						(w_maxpool_en)
	);

	// MAX-POOL 1x1 Instantiation
	max_pool max_pool_1x1_inst
	(
		.clk_i 							(clk_i),
		.rst_n_i 						(rst_n_i),

		.data_1_i 						(max_1x1_rd_data_i),
		.data_2_i 						(w_max_ram_1x1_rd_data[47:00]),
		.data_max_o 					(w_max_ram_1x1_wr_data),
		.max_en_i 						(w_maxpool_en)
	);

	// Squeeze 3x3 FIFO
	squeeze_fifo squeeze_3x3_fifo_inst
	(
		.aclr 							(start_i),

		.wrclk 							(clk_i),
		.data 							(r_fifo_3x3_wr_data),
		.wrreq 							(r_fifo_wr_en),
		.wrusedw 						(w_wr_3x3_data_count),

		.rdclk 							(clk_i),
		.q 								(fifo_squeeze_3x3_rd_data_o),
		.rdreq 							(fifo_squeeze_3x3_rd_en_i),
		.rdempty 						(fifo_squeeze_3x3_empty_o)
	);

	// Squeeze 1x1 FIFO
	squeeze_fifo squeeze_1x1_fifo_inst
	(
		.aclr 							(start_i),

		.wrclk 							(clk_i),
		.data 							(r_fifo_1x1_wr_data),
		.wrreq 							(r_fifo_wr_en),
		.wrusedw 						(),

		.rdclk 							(clk_i),
		.q 								(fifo_squeeze_1x1_rd_data_o),
		.rdreq 							(fifo_squeeze_1x1_rd_en_i),
		.rdempty 						(fifo_squeeze_1x1_empty_o)
	);
	
endmodule

