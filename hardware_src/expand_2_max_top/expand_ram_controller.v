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

module expand_ram_controller(
	clk_i,
	rst_n_i,

	start_i,
	max_en_i,
	no_of_exp_kernals_i,
	layer_done_flag_o,
	layer_end_addr_i,
	new_layer_flag_i,
	new_line_flag_i,
	first_layer_flag_i,
	last_layer_flag_i,
	fire_end_flag_i,
	bash_ram_ready_o,

	expand_3x3_data_i,
	expand_1x1_data_i,
	expand_flag_i,

	expand_3x3_data_o,
	expand_1x1_data_o,
	expand_flag_o,

	max_3x3_rd_data_o,
	max_1x1_rd_data_o,
	max_rd_addr_i,
	max_ready_flag_o,

	fifo_exp_bash_clr_i,
	fifo_exp_bash_wr_data_i,
	fifo_exp_bash_wr_en_i,
	fifo_exp_bash_data_count_o
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

	// state_rds RAM- Read Decleration
	localparam 								RD_RAM_1 			=		1'b0;
	localparam 								RD_RAM_2  			= 		1'b1;

	localparam 								WR_RAM_1 			=		1'b0;
	localparam 								WR_RAM_2  			= 		1'b1;

	/*
		Configurations :- EXPAND 3X3 KERNAL CONTROLLER
		no_of_exp_kernals_i 		:- [2 * NO of expand kernals / 8 - 1]
	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	input 															start_i;
	input 															max_en_i;
	input 				[5:0] 										no_of_exp_kernals_i;
	output 	reg														layer_done_flag_o;
	input 	 			[10:0] 										layer_end_addr_i;
	input 	 														new_layer_flag_i;
	input 	 														new_line_flag_i;
	input 	  														first_layer_flag_i;
	input 	  														last_layer_flag_i;
	input 															fire_end_flag_i;
	output 															bash_ram_ready_o;

	// Expand Ouput COntrol Signals
	input 				[47:0] 										expand_3x3_data_i;
	input 				[47:0] 										expand_1x1_data_i;
	input 															expand_flag_i;

	// MAX Pool COntrol Signals
	output 				[47:0]										expand_3x3_data_o;
	output 				[47:0]										expand_1x1_data_o;
	output 	reg														expand_flag_o;

	output 				[47:0]										max_3x3_rd_data_o;
	output 				[47:0]										max_1x1_rd_data_o;
	input 				[10:0] 										max_rd_addr_i;
	output 	reg 													max_ready_flag_o;

	// Expand Bash FIFO COntrol Signals
	input 															fifo_exp_bash_clr_i;
	input 				[63:0] 										fifo_exp_bash_wr_data_i;
	input 															fifo_exp_bash_wr_en_i;
	output 				[6:0] 										fifo_exp_bash_data_count_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// FSM Control Signals
	reg 					 										state_rd;
	reg 					 										state_wr;

	reg 				[47:0] 										r_exp_3x3_1;
	reg 				[47:0] 										r_exp_3x3_2;
	reg 				[47:0] 										r_exp_1x1_1;
	reg 				[47:0] 										r_exp_1x1_2;

	// FLAG Control Signals
	reg 				[2:0] 										r_first_layer_flag;
	reg 				[10:0]										r_expand_flag;
	reg 				[10:0] 										r_new_line_flag;
	reg 				[11:0] 										r_new_layer_flag;
	reg 				[10:0] 										r_last_layer_flag;

	// Block RAM Control Signals
	reg 															r_rd_ram_sel;
	wire  				[47:0] 										w_ram_3x3_wr_data;
	wire  				[47:0] 										w_ram_1x1_wr_data;

	wire  				[63:0] 										w_ram_3x3_1_rd_data;
	wire  				[63:0] 										w_ram_3x3_2_rd_data;
	wire  				[63:0] 										w_ram_1x1_1_rd_data;
	wire  				[63:0] 										w_ram_1x1_2_rd_data;

	wire 															w_ram_1_rd_end_flag;
	wire 															w_ram_2_rd_end_flag;

	reg 				[10:0] 										r_ram_1_rd_addr;
	reg 				[10:0] 										r_ram_2_rd_addr;
	wire 				[10:0] 										w_ram_1_rd_addr;
	wire 				[10:0] 										w_ram_2_rd_addr;


	reg 				[10:0] 										r_ram_wr_addr;

	reg 															r_ram_1_wr_en;
	reg 															r_ram_2_wr_en;

	// Expand Add COntrol Signals
	wire 				[47:0] 										w_exp_3x3_out;
	wire 				[47:0] 										w_exp_1x1_out;
	wire 				[95:0] 										w_expand_out;

	// BASH Control Signals
	wire 															w_bash_req;
	wire 				[63:0] 										w_bash_data;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// Expand Data 1
	always @(posedge clk_i) begin : EXPAND_DATA_1
		if(~rst_n_i) begin
			r_exp_3x3_1	<= 0;
			r_exp_1x1_1	<= 0;
		end else begin
			r_exp_3x3_1 <= expand_3x3_data_i;
			r_exp_1x1_1 <= expand_1x1_data_i;
		end
	end

	// Expand Data 2
	always @(posedge clk_i) begin : EXPAND_DATA_2
		if(~rst_n_i) begin
			r_exp_3x3_2 <= 0;
			r_exp_1x1_2 <= 0;
		end else begin
			r_exp_3x3_2 <= (r_rd_ram_sel) ? w_ram_3x3_1_rd_data[47:00] : w_ram_3x3_2_rd_data[47:00];
			r_exp_1x1_2 <= (r_rd_ram_sel) ? w_ram_1x1_1_rd_data[47:00] : w_ram_1x1_2_rd_data[47:00];
		end
	end

	// FSM
	always @(posedge clk_i) begin : FSM_READ
		if(~rst_n_i || start_i) begin
			state_rd <= RD_RAM_1;
		end 
		else begin
			case(state_rd)
				RD_RAM_1 	: 	if(expand_flag_i && new_line_flag_i)
									state_rd <= RD_RAM_2;
				RD_RAM_2 	: 	if(expand_flag_i && new_line_flag_i)
									state_rd <= RD_RAM_1;
			endcase
		end
	end
	// Read RAM Select
	always @(posedge clk_i) begin : READ_RAM_SEL
		if(~rst_n_i) begin
			r_rd_ram_sel <= 0;
		end else begin
			r_rd_ram_sel <= (state_rd == RD_RAM_1);
		end
	end


	// BLOCK RAM Read Address
	always @(posedge clk_i) begin : RAM_1_RD_ADDR
		if(~rst_n_i || (expand_flag_i && new_line_flag_i) || start_i) begin
			r_ram_1_rd_addr <= 0;
		end 
		/*else if(state_rd == RD_RAM_2) begin
			r_ram_1_rd_addr <= max_rd_addr_i;
		end*/
		else if(expand_flag_i && new_layer_flag_i) begin
			r_ram_1_rd_addr <= 0;
		end
		else if(expand_flag_i) begin
			r_ram_1_rd_addr <= r_ram_1_rd_addr + 1;
		end
	end
	always @(posedge clk_i) begin : RAM_2_RD_ADDR
		if(~rst_n_i || (expand_flag_i && new_line_flag_i) || start_i) begin
			r_ram_2_rd_addr <= 0;
		end 
		/*else if(state_rd == RD_RAM_1) begin
			r_ram_2_rd_addr <= max_rd_addr_i;
		end*/
		else if(expand_flag_i && new_layer_flag_i) begin
			r_ram_2_rd_addr <= 0;
		end
		else if(expand_flag_i) begin
			r_ram_2_rd_addr <= r_ram_2_rd_addr + 1;
		end
	end

	// Layer Done Flag
	assign w_ram_1_rd_end_flag = (r_ram_1_rd_addr == layer_end_addr_i);
	assign w_ram_2_rd_end_flag = (r_ram_2_rd_addr == layer_end_addr_i);
	always @(posedge clk_i) begin : LAYER_DONE_FLAG
		if(~rst_n_i || start_i) begin
			layer_done_flag_o <= 0;
		end 
		else if(expand_flag_i) begin
			layer_done_flag_o <= (state_rd == RD_RAM_1) ? w_ram_1_rd_end_flag : w_ram_2_rd_end_flag; 
		end
		else begin
			layer_done_flag_o <= 0;
		end 
	end

	// FSM
	always @(posedge clk_i) begin : FSM_WRITE
		if(~rst_n_i || start_i) begin
			state_wr <= WR_RAM_1;
		end 
		else begin
			case(state_wr)
				WR_RAM_1 	: 	if(r_new_line_flag[10:10]) //[8:8]
									state_wr <= WR_RAM_2;
				WR_RAM_2 	: 	if(r_new_line_flag[10:10]) //[8:8]
									state_wr <= WR_RAM_1;
			endcase
		end
	end

	// BLOCK RAM Write Address
	always @(posedge clk_i) begin : RAM_WR_ADDR
		if(~rst_n_i || r_new_layer_flag[11:11] || start_i) begin //[9:9]
			r_ram_wr_addr <= 0;
		end 
		else if(r_ram_1_wr_en || r_ram_2_wr_en) begin
			r_ram_wr_addr <= r_ram_wr_addr + 1;
		end
	end

	// BLOCK RAM Write Enable
	always @(posedge clk_i) begin : RAM_2_WR_ADDR
		if(~rst_n_i || start_i) begin
			r_ram_1_wr_en <= 0;
			r_ram_2_wr_en <= 0;
		end 
		else begin
			r_ram_1_wr_en <= (state_wr == WR_RAM_1) ? r_expand_flag[10:10] : 0; //[8:8]
			r_ram_2_wr_en <= (state_wr == WR_RAM_2) ? r_expand_flag[10:10] : 0; //[8:8]
		end
	end


	// FLAG Control Signals
	always @(posedge clk_i) begin : FIRST_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			r_first_layer_flag <= 1;
		end else begin
			r_first_layer_flag[0:0] <= first_layer_flag_i;
			r_first_layer_flag[1:1] <= r_first_layer_flag[0:0];
			r_first_layer_flag[2:2] <= r_first_layer_flag[1:1];
		end
	end

	// Last Layer flag 
	always @(posedge clk_i) begin : LAST_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			r_last_layer_flag <= 0;
		end else begin
			r_last_layer_flag[00:00] <= last_layer_flag_i;
			r_last_layer_flag[01:01] <= r_last_layer_flag[00:00];
			r_last_layer_flag[02:02] <= r_last_layer_flag[01:01];
			r_last_layer_flag[03:03] <= r_last_layer_flag[02:02];
			r_last_layer_flag[04:04] <= r_last_layer_flag[03:03];
			r_last_layer_flag[05:05] <= r_last_layer_flag[04:04];
			r_last_layer_flag[06:06] <= r_last_layer_flag[05:05];
			r_last_layer_flag[07:07] <= r_last_layer_flag[06:06];
			r_last_layer_flag[08:08] <= r_last_layer_flag[07:07];
			r_last_layer_flag[09:09] <= r_last_layer_flag[08:08];
			r_last_layer_flag[10:10] <= r_last_layer_flag[09:09];
		end
	end

	// Expand Flag
	always @(posedge clk_i) begin : EXPAND_FLAG
		if(~rst_n_i || start_i) begin
			r_expand_flag <= 0;
		end else begin
			r_expand_flag[00:00] <= expand_flag_i;
			r_expand_flag[01:01] <= r_expand_flag[00:00];
			r_expand_flag[02:02] <= r_expand_flag[01:01];
			r_expand_flag[03:03] <= r_expand_flag[02:02];
			r_expand_flag[04:04] <= r_expand_flag[03:03];
			r_expand_flag[05:05] <= r_expand_flag[04:04];
			r_expand_flag[06:06] <= r_expand_flag[05:05];
			r_expand_flag[07:07] <= r_expand_flag[06:06];
			r_expand_flag[08:08] <= r_expand_flag[07:07];
			r_expand_flag[09:09] <= r_expand_flag[08:08];
			r_expand_flag[10:10] <= r_expand_flag[09:09];
		end
	end

	// New Layer Flag
	always @(posedge clk_i) begin : NEW_LAYER_FLAG
		if(~rst_n_i || start_i) begin
			r_new_layer_flag <= 0;
		end else begin
			r_new_layer_flag[00:00] <= (expand_flag_i && new_layer_flag_i);
			r_new_layer_flag[01:01] <= r_new_layer_flag[00:00];
			r_new_layer_flag[02:02] <= r_new_layer_flag[01:01];
			r_new_layer_flag[03:03] <= r_new_layer_flag[02:02];
			r_new_layer_flag[04:04] <= r_new_layer_flag[03:03];
			r_new_layer_flag[05:05] <= r_new_layer_flag[04:04];
			r_new_layer_flag[06:06] <= r_new_layer_flag[05:05];
			r_new_layer_flag[07:07] <= r_new_layer_flag[06:06];
			r_new_layer_flag[08:08] <= r_new_layer_flag[07:07];
			r_new_layer_flag[09:09] <= r_new_layer_flag[08:08];
			r_new_layer_flag[10:10] <= r_new_layer_flag[09:09];
			r_new_layer_flag[11:11] <= r_new_layer_flag[10:10];
		end
	end

	// New Line Flag
	always @(posedge clk_i) begin : NEW_LINE_FLAG
		if(~rst_n_i || start_i) begin
			r_new_line_flag <= 0;
		end else begin
			r_new_line_flag[00:00] <= (expand_flag_i && new_line_flag_i);
			r_new_line_flag[01:01] <= r_new_line_flag[00:00];
			r_new_line_flag[02:02] <= r_new_line_flag[01:01];
			r_new_line_flag[03:03] <= r_new_line_flag[02:02];
			r_new_line_flag[04:04] <= r_new_line_flag[03:03];
			r_new_line_flag[05:05] <= r_new_line_flag[04:04];
			r_new_line_flag[06:06] <= r_new_line_flag[05:05];
			r_new_line_flag[07:07] <= r_new_line_flag[06:06];
			r_new_line_flag[08:08] <= r_new_line_flag[07:07];
			r_new_line_flag[09:09] <= r_new_line_flag[08:08];
			r_new_line_flag[10:10] <= r_new_line_flag[09:09];
		end
	end

	// Bash Request
	assign w_bash_req = (r_expand_flag[4:4] && r_last_layer_flag[4:4]); //(r_expand_flag[3:3] && r_last_layer_flag[3:3]);

	// Expand Out
	assign w_expand_out[95:48] = w_exp_3x3_out;
	assign w_expand_out[47:00] = w_exp_1x1_out;

	// Expand Data out
	assign expand_3x3_data_o = w_ram_3x3_wr_data;
	assign expand_1x1_data_o = w_ram_1x1_wr_data;

	// Expand Flag 
	always @(posedge clk_i) begin : EXPAND_FLAG_OUT
		if(~rst_n_i || start_i) begin
			expand_flag_o <= 0;
		end else begin
			//expand_flag_o <= (r_expand_flag[8:8] && r_last_layer_flag[8:8] && ~max_en_i && ~fire_end_flag_i);
			expand_flag_o <= (r_expand_flag[10:10] && r_last_layer_flag[10:10] && ~max_en_i && ~fire_end_flag_i);
		end
	end

	// MAX Ready Flag
	always @(posedge clk_i) begin : MAX_READY_FLAG
		if(~rst_n_i || start_i) begin
			max_ready_flag_o <= 0;
		end 
		else begin
			max_ready_flag_o <= (max_en_i && r_new_line_flag[10:10]); // r_new_line_flag[8:8]
		end
	end

	// MAX Read data Out
	assign max_3x3_rd_data_o = (state_rd == RD_RAM_2) ? w_ram_3x3_1_rd_data[47:00] : w_ram_3x3_2_rd_data[47:00];
	assign max_1x1_rd_data_o = (state_rd == RD_RAM_2) ? w_ram_1x1_1_rd_data[47:00] : w_ram_1x1_2_rd_data[47:00];

	// EXP RAM Read Address
	assign w_ram_1_rd_addr = (state_rd == RD_RAM_2) ? max_rd_addr_i : r_ram_1_rd_addr;
	assign w_ram_2_rd_addr = (state_rd == RD_RAM_1) ? max_rd_addr_i : r_ram_2_rd_addr;
	
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// EXP 3X3 RAM-1 Instantiation
	expand_ram exp_3x3_ram_1_inst
	(
		.clock 								(clk_i),

		.data 								({16'd0,w_ram_3x3_wr_data}),
		.wraddress 							(r_ram_wr_addr),
		.wren 								(r_ram_1_wr_en),

		.rdaddress 							(w_ram_1_rd_addr),
		.q 									(w_ram_3x3_1_rd_data)
	);

	// EXP 3X3 RAM-2 Instantiation
	expand_ram exp_3x3_ram_2_inst
	(
		.clock 								(clk_i),

		.data 								({16'd0,w_ram_3x3_wr_data}),
		.wraddress 							(r_ram_wr_addr),
		.wren 								(r_ram_2_wr_en),

		.rdaddress 							(w_ram_2_rd_addr),
		.q 									(w_ram_3x3_2_rd_data)
	);

	// EXP 1x1 RAM-1 Instantiation
	expand_ram exp_1x1_ram_1_inst
	(
		.clock 								(clk_i),

		.data 								({16'd0,w_ram_1x1_wr_data}),
		.wraddress 							(r_ram_wr_addr),
		.wren 								(r_ram_1_wr_en),

		.rdaddress 							(w_ram_1_rd_addr), //r_ram_1_rd_addr),
		.q 									(w_ram_1x1_1_rd_data)
	);

	// EXP 1x1 RAM-2 Instantiation
	expand_ram exp_1x1_ram_2_inst
	(
		.clock 								(clk_i),

		.data 								({16'd0,w_ram_1x1_wr_data}),
		.wraddress 							(r_ram_wr_addr),
		.wren 								(r_ram_2_wr_en),

		.rdaddress 							(w_ram_2_rd_addr), //r_ram_2_rd_addr),
		.q 									(w_ram_1x1_2_rd_data)
	);

	// Expand 3x3 ADD
	expand_add expand_3x3_add_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.expand_1_i 						(r_exp_3x3_1),
		.expand_2_i 						(r_exp_3x3_2),
		.expand_sum_o 						(w_exp_3x3_out),
		.add_en_i 							(~r_first_layer_flag[1:1])
	);

	// Expand 1x1 ADD
	expand_add expand_1x1_add_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.expand_1_i 						(r_exp_1x1_1),
		.expand_2_i 						(r_exp_1x1_2),
		.expand_sum_o 						(w_exp_1x1_out),
		.add_en_i 							(~r_first_layer_flag[1:1])
	);

	// Expand Bash COntroller
	exp_bash_controller exp_bash_controller_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.start_i 							(start_i),
		.no_of_exp_kernals_i 				(no_of_exp_kernals_i),

		.fifo_exp_bash_clr_i 				(fifo_exp_bash_clr_i),
		.fifo_exp_bash_wr_data_i 			(fifo_exp_bash_wr_data_i),
		.fifo_exp_bash_wr_en_i 				(fifo_exp_bash_wr_en_i),
		.fifo_exp_bash_data_count_o 		(fifo_exp_bash_data_count_o),
	
		.bash_req_i 						(w_bash_req),
		.bash_ram_ready_o 					(bash_ram_ready_o),
		.bash_data_o 						(w_bash_data)
	);

	bash_add bash_add_inst
	(
		.clk_i 								(clk_i),
		.rst_n_i 							(rst_n_i),

		.bash_1_i 							(w_expand_out),
		.bash_2_i 							(w_bash_data),
		.bash_3x3_o 						(w_ram_3x3_wr_data),
		.bash_1x1_o 						(w_ram_1x1_wr_data),

		.add_en_i 							(r_last_layer_flag[6:6]), // [6:6]
		.skip_neg_en_i 						(r_last_layer_flag[6:6])  // [6:6]
	);

	//********************
	/*reg [3:0] count_x;
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			count_x <= 0;
		end else if(r_last_layer_flag[6:6]) begin
			count_x <= count_x + 1;
		end
	end
	always @(posedge clk_i) begin 
		if(r_last_layer_flag[6:6] && count_x == 15) begin
			$display("input : - %h\t %h",w_expand_out[47:00],w_bash_data);
		end
	end*/
	//********************

	//********************
	/*reg [3:0] count_y;
	reg valid;
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			count_y <= 0;
		end else if(valid) begin
			count_y <= count_y + 1;
		end
	end
	always @(posedge clk_i) begin 
		if(~rst_n_i) begin
			valid <= 0;
		end else begin
			valid <= r_last_layer_flag[10:10];
		end
	end
	always @(posedge clk_i) begin 
		if(valid && count_y == 15) begin
			$display("Output : - %h",w_ram_1x1_wr_data);
		end
	end*/
	//********************

endmodule

