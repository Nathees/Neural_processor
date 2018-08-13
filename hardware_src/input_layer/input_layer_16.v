// this module will read input layer data from ddr3 
// this will stream input layer data coressponding to 
// four, 3x3 sized kernels
// vaid will indicate  right data


// AXI lite interface will provide start adress of first layer
// and number of input layers
// it is assumed a fixed size of bytes are allocated for
// each  layer irrespective of its actual size
// 




module input_layer_16# (

            parameter                           C_S_AXI_ID_WIDTH              =     3,
            parameter                           C_S_AXI_ADDR_WIDTH            =     32,
            parameter                           C_S_AXI_DATA_WIDTH            =     128,
            parameter                           C_S_AXI_BURST_LEN             =     8,
            parameter                           STREAM_DATA_WIDTH             =     144
             
    ) (
	// parameters from axi_lite
	input 									Start,
	input 									cast_,
	input [C_S_AXI_ADDR_WIDTH -1 : 0] 		axi_address,
	input 									larger_block_en,
	input [9:0] 							allocated_space_per_row,
	input 									stride2en,
	input [7:0] 							burst_per_row,
	input [3:0] 							read_burst_len,
	input [9:0] 							no_of_input_layers,
	input [9:0] 							input_layer_row_size,
	input [9:0] 							input_layer_col_size,
	input [0:0] 							in_layer_ddr3_data_rdy,

	// streaming data
	// ids will increment sequentially, but provieded as extra info
	// transsaction will occur when ready and valid are high
	// processing part should monitor valid before sending valid outputs

	output [STREAM_DATA_WIDTH-1:0] input_layer_data_3x3,
	output[0:0] input_layer_data_valid,
	input [0:0] input_layer_data_rdy, 
	output[9:0] input_layer_1_id, 

	output wire 												   read_done,


	// AXI signals
	input  wire                                                    clk,				// logic will operate in same clock as axi clock
    input  wire                                                    reset_n,

	// AXI Write Address Control Signals
	output  wire 			[C_S_AXI_ID_WIDTH-1:0] 					M_axi_awid, 	
	output  wire 			[C_S_AXI_ADDR_WIDTH-1:0]				M_axi_awaddr,	
	output  wire 			[7:0] 									M_axi_awlen,	
	output  wire 			[2:0] 									M_axi_awsize, 	
	output  wire 			[1:0]									M_axi_awburst,   
	output  wire 			[0:0]									M_axi_awlock,	
	output  wire 			[3:0]									M_axi_awcache, 	
	output  wire 			[2:0]									M_axi_awprot, 	
    output  wire 			[3:0]									M_axi_awqos, 	
	output  wire 													M_axi_awvalid,	
	input   wire 													M_axi_awready, 	

	// AXI Write Data Control Signals
	output  wire 			[C_S_AXI_DATA_WIDTH-1:0]				M_axi_wdata,		
	output  wire 			[C_S_AXI_DATA_WIDTH/8-1:0]				M_axi_wstrb,		
	output  wire  													M_axi_wlast,		
	output  wire 													M_axi_wvalid,		
	input   wire 													M_axi_wready,		

	// AXI Response Control Signals
	input  wire 			[C_S_AXI_ID_WIDTH-1:0]					M_axi_bid, 			
	input  wire 			[1:0]									M_axi_bresp,		
	input  wire 													M_axi_bvalid, 		
	output wire 												    M_axi_bready,		

	// AXI Read Address Control Signals
	output wire 			[C_S_AXI_ID_WIDTH-1:0]					M_axi_arid, 		
	output wire 			[C_S_AXI_ADDR_WIDTH-1:0]				M_axi_araddr, 		
	output wire 			[7:0] 									M_axi_arlen, 		
	output wire 			[2:0]									M_axi_arsize, 		
	output wire 			[1:0]									M_axi_arburst, 		
	output wire 			[0:0]									M_axi_arlock, 		
	output wire 			[3:0]									M_axi_arcache, 		
	output wire 			[2:0]									M_axi_arprot, 		
	output wire 			[3:0]									M_axi_arqos,		
	output wire 													M_axi_arvalid,		
	input  wire 													M_axi_arready,		

	// AXI Read Data Control Signals
	input  wire 			[C_S_AXI_ID_WIDTH-1:0] 					M_axi_rid, 			
	input  wire 			[C_S_AXI_DATA_WIDTH-1:0]				M_axi_rdata,		
	input  wire 			[1:0]									M_axi_rresp,		
    input  wire 													M_axi_rlast,		
	input  wire 													M_axi_rvalid,		
	output wire 												    M_axi_rready		
	);


// axi settings
	// Write Address Control Signals
	assign M_axi_awid = 0;
	assign M_axi_awlen = 8'h4;
	assign M_axi_awsize = 3;
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;
	assign M_axi_bready = 0;

	// Read Address Control Signals
	assign M_axi_arid = 1;
	assign M_axi_arlen = read_burst_len;
	assign M_axi_arsize = 3;
	assign M_axi_arburst = 1;
	assign M_axi_arlock = 0;
	assign M_axi_arcache = 4'b0011;
	assign M_axi_arprot = 0;
	assign M_axi_arqos = 0;


	// tying write port to ground
	assign M_axi_awaddr = 0;
	assign M_axi_awvalid = 0;

	assign M_axi_wdata  = 0;
	assign M_axi_wstrb = 0;
	assign M_axi_wlast = 0;
	assign M_axi_wvalid  = 0;

    assign M_axi_araddr = r_next_axi_address;



//---------------------------------------------------------------------------------
//---------------------------Implementation----------------------------------------
//---------------------------------------------------------------------------------



// state machine
// one input layer will be processed at a time
// this module will provide 3x3 inputs each clock
// loop structure
// foreach inputlayer
//		foreach row
//			foreach 3x3
// dual port ram will be used 
// one module will read fro ddr3 and write to block ram
// 


	reg [9:0] r_inputlayer_id;
	reg [9:0] r_row_position_id;
	reg [9:0] r_col_postion_id;
	reg r_col_almost_end;

	always @(posedge clk) begin : proc_r_col_almost_end
		if(~reset_n | Start) begin
			r_col_almost_end <= 0;
		end else if(stride2en && (r_col_postion_id == input_layer_col_size - 2) && valid_transation) begin
			 r_col_almost_end <= 1;
		end else if((r_col_postion_id == input_layer_col_size - 2) && valid_transation) begin
			 r_col_almost_end <= 1;
		end else if(valid_transation) begin
			r_col_almost_end <= 0;
		end
	end

	wire valid_transation = input_layer_1_valid & r_input_fifo_wr_en;
	wire one_row_complete = r_col_almost_end && valid_transation;
	wire move_to_next_rows = (r_inputlayer_id >= no_of_input_layers - 1) && one_row_complete;
	wire layer_complete = (r_row_position_id >= input_layer_row_size ? 1 : 0);


//---------------------------------------------------------------------------------------------
	// state machine for iterating along
	// input layers
//---------------------------------------------------------------------------------------------
	// provide 3x3 window on each clockcycle moving 
	// along a row
	always @(posedge clk) begin : proc_r_col_postion_id
		if(~reset_n | Start |layer_complete) begin
			r_col_postion_id <= 0;
		end else if(valid_transation && r_col_postion_id >= input_layer_col_size - 1)begin
			r_col_postion_id <= 0;
		end else if(valid_transation && stride2en) begin
			r_col_postion_id <= r_col_postion_id + 1;
		end else if(valid_transation) begin
			r_col_postion_id <= r_col_postion_id + 1;
		end
	end

	// if a row completed move to same row 
	// of next layer
	always @(posedge clk) begin : proc_r_inputlayer_id
		if(~reset_n | Start | layer_complete) begin
			r_inputlayer_id <= 0;
		end else if(one_row_complete && move_to_next_rows)begin
			r_inputlayer_id <= 0;
		end else if(one_row_complete) begin
			r_inputlayer_id <= r_inputlayer_id + 1;
		end
	end

	// after completeing all same row id in
	// all layers move to next row
	always @(posedge clk) begin : proc_r_row_position_id
		if(~reset_n | Start) begin
			r_row_position_id <= 0;
		// end else if(move_to_next_rows && (r_row_position_id < input_layer_row_size) && stride2en)begin
		// 	r_row_position_id <= r_row_position_id + 2;
		end else if(move_to_next_rows && (r_row_position_id < input_layer_row_size))begin
			r_row_position_id <= r_row_position_id + 1;
		end
	end

	
	reg r_feed_done;
	reg r_feed_done_p1;
	always @(posedge clk) begin : proc_r_feed_done
		if(~reset_n | Start) begin
			r_feed_done <= 0;
		end else if((r_inputlayer_id == no_of_input_layers - 1) && (r_row_position_id == input_layer_row_size - 1) && (r_col_postion_id == input_layer_col_size - 1) && valid_transation) begin
			r_feed_done <= 1;
		end
	end

	always @(posedge clk) begin : proc_r_feed_done_p1
		if(~reset_n) begin
			r_feed_done_p1 <= 0;
		end else begin
			r_feed_done_p1 <= r_feed_done;
		end
	end

	assign read_done = ~r_feed_done_p1 & r_feed_done;

//-----------------------------------------------------------------------------------------------
//-------- AXI Address calculation related to input layer----------------------------------------
//-----------------------------------------------------------------------------------------------

	// each AXI burst should not cross 4k boundry
	// max size for input layer is 55x55 bytes, which is  less than 4k
	// all input layers should be 4k block aligned
	// lets keep all rows aligned to 4bytes, as ddr3 width is 32 bit
	// for simplifying further lets keep all rows aligned to 64 bytes
	// initial plan is to keep 4 rows of input layers
	// one input layer will require 4 * 64 = 256 bytes
	// two blockrams will be used as  dual buffer


	

	//--------------------------------------------------------------------------------------------
	//------------------next_required row and input_layer id--------------------------------------
	//--------------------------------------------------------------------------------------------
		reg [9:0] r_next_inputlayer_id;
		reg [9:0] r_next_row_id;
		reg [0:0] r_next_layer_row_fetched;
		reg [0:0] r_current_layer_row_done;


		always @(posedge clk) begin : proc_
			if(~reset_n | Start) begin
				r_next_inputlayer_id <= 0;
			end else if((r_next_inputlayer_id >= no_of_input_layers -1) && row_fetch_done) begin
				r_next_inputlayer_id <= 0;
			end else if(row_fetch_done) begin
				r_next_inputlayer_id <= r_next_inputlayer_id + 1;
			end
		end

		always @(posedge clk) begin : proc_r_next_row_id
			if(~reset_n | Start) begin
				r_next_row_id <= 0;
			end else if((r_next_inputlayer_id >= no_of_input_layers -1) && row_fetch_done) begin
				r_next_row_id <= r_next_row_id + 1;
			end
		end

		wire cmp_input_layer_id = (r_next_inputlayer_id - r_inputlayer_id <= 1) && (r_next_row_id == r_row_position_id);
		wire cmp_row_id = (r_inputlayer_id == no_of_input_layers -1 ) && (r_next_row_id - r_row_position_id <= 1) && (r_next_inputlayer_id < 1);
		wire w_fetch_rows = ( cmp_input_layer_id | cmp_row_id? 1 : 0);

		// registering fetch_rows
		reg r_fetch_rows;
		always @(posedge clk) begin : proc_r_fetch_rows
			if(~reset_n) begin
				r_fetch_rows <= 0;
			end else begin
				r_fetch_rows <= w_fetch_rows;
			end
		end

		//wire[15:0] previous_row_id = (r_next_row_id == 0) ? 0 : r_next_row_id - 1;
		//wire[31:0] next_AXI_burst_address = {r_next_inputlayer_id, 12'b0} + {r_next_row_id, 6'b0} + axi_address - 64;


		// fetching rows one by one insted of fetching 3 rows in a burst

		reg [7:0] r_eight_byte_algined_row_size;
		reg [7:0] r_burst_per_row;
		reg [7:0] r_burst_counter;
		reg [9:0] r_allocated_space_per_row;


		reg [15:0] r_row_base_address_counter;
		reg [15:0] r_row_current_address_counter;
		reg [3:0]  r_fetch_rows_FSM;


		wire burst_done = M_axi_rready & M_axi_rvalid & M_axi_rlast;

		always @(posedge clk) begin : proc_r_eight_byte_algined_row_size
			if(~reset_n) begin
				//r_eight_byte_algined_row_size <= 0;
				r_burst_per_row <= 0;
				r_allocated_space_per_row <= 0;
			end else if(Start) begin
				//r_eight_byte_algined_row_size <= (input_layer_row_size[2:0] == 0 ? input_layer_row_size : {input_layer_row_size[15:3] + 1, 2'b0});
				r_burst_per_row <= burst_per_row;
				r_allocated_space_per_row <= allocated_space_per_row;
			end
		end

		always @(posedge clk) begin : proc_r_row_base_address_counter
			if(~reset_n || Start) begin
				r_row_base_address_counter <= 0;
			end else if ((r_next_inputlayer_id >= no_of_input_layers -1) && row_fetch_done) begin
				r_row_base_address_counter <= r_row_base_address_counter + allocated_space_per_row;
			end
		end

		always @(posedge clk) begin : proc_r_row_current_address_counter
			if(~reset_n || Start) begin
				r_row_current_address_counter <= 0;
			end else if(r_fetch_rows_FSM == 4'b0000 && r_fetch_rows) begin
				r_row_current_address_counter <= r_row_base_address_counter;
			end else if(M_axi_rvalid & M_axi_rready) begin
				r_row_current_address_counter <= r_row_current_address_counter + 16;
			end
		end

		wire row_finished = ((r_burst_counter == r_burst_per_row -1) && burst_done)? 1 : 0;
		always @(posedge clk) begin : proc_r_burst_counter
			if(~reset_n || Start || (r_fetch_rows_FSM == 4'b0000 &&r_fetch_rows) || row_finished) begin
				r_burst_counter <= 0;
			end else if(burst_done)begin
				r_burst_counter <= r_burst_counter + 1;
			end
		end

		always @(posedge clk) begin : proc_r_fetch_rows_FSM
			if(~reset_n | Start) begin
				r_fetch_rows_FSM <= 0;
			end else begin
				 case(r_fetch_rows_FSM)
				 	4'b0000: if(r_fetch_rows) r_fetch_rows_FSM <= 4'b0001;
				 	4'b0001: if(row_finished) r_fetch_rows_FSM <= 4'b0010;
				 	4'b0010: if(row_finished) r_fetch_rows_FSM <= 4'b0011;
				 	4'b0011: if(row_finished) r_fetch_rows_FSM <= 4'b0100;
				 	4'b0100: r_fetch_rows_FSM <= 4'b0000;
				 	default: r_fetch_rows_FSM <= 4'b0000;
				 endcase
			end
		end

		reg [31:0] r_next_axi_address;
		reg [31:0] r_next_axi_address_offset;

		always @(posedge clk) begin : proc_r_next_axi_address_offset
			if(~reset_n) begin
				r_next_axi_address <= 0;
			end else if(larger_block_en) begin
				r_next_axi_address <= {r_next_inputlayer_id, 16'b0} + r_row_current_address_counter + axi_address;
			end else begin
				r_next_axi_address <= {r_next_inputlayer_id, 12'b0} + r_row_current_address_counter + axi_address;
			end
		end


	//--------------------------------------------------------------------------------------------
	//----------- logic for writing required data in block ram-----------------------------------
	//--------------------------------------------------------------------------------------------

	reg [1:0] r_blk_write_offset_select;
	reg r_row_fetch_done;

	always@(posedge clk) begin
		if(~reset_n | Start | r_feed_done) begin
			r_blk_write_offset_select <= 0;
		end else if(row_fetch_done) begin
			r_blk_write_offset_select <= r_blk_write_offset_select + 1;
		end
	end

	always @(posedge clk) begin : proc_r_row_fetch_done
		if(~reset_n) begin
			r_row_fetch_done <= 0;
		end else begin
			r_row_fetch_done <= row_fetch_done;
		end
	end

	//wire[7:0]  next_blk_ram_write_offset = (r_blk_write_offset_select ? 8'd32 : 8'd0);
	
	wire blk_ram_write_enable = M_axi_rvalid & M_axi_rready;
	wire row_fetch_done = (r_fetch_rows_FSM == 4'b0100) ? 1 : 0; //M_axi_rready & M_axi_rvalid & M_axi_rlast;

	reg [5:0] r_blk_ram_wr_addr0;
	reg [5:0] r_blk_ram_wr_addr1;
	reg [7:0] r_blk_ram_wr_addr2;

	always @(posedge clk) begin : proc_blk_ram_wr_addr
		if(~reset_n | r_row_fetch_done | Start) begin
			r_blk_ram_wr_addr0 <= 0;
			r_blk_ram_wr_addr1 <= 0;
			r_blk_ram_wr_addr2 <= 0;
		end else begin
			r_blk_ram_wr_addr0 <= (wea_0 ? r_blk_ram_wr_addr0 + 1 : r_blk_ram_wr_addr0);
			r_blk_ram_wr_addr1 <= (wea_1 ? r_blk_ram_wr_addr1 + 1 : r_blk_ram_wr_addr1);
			r_blk_ram_wr_addr2 <= (wea_2 ? r_blk_ram_wr_addr2 + 1 : r_blk_ram_wr_addr2);
		end
	end
	wire [7:0] w_blk_ram_wr_addr0 = {r_blk_write_offset_select, r_blk_ram_wr_addr0[5:0]};
	wire [7:0] w_blk_ram_wr_addr1 = {r_blk_write_offset_select, r_blk_ram_wr_addr1[5:0]};
	wire [7:0] w_blk_ram_wr_addr2 = {r_blk_write_offset_select, r_blk_ram_wr_addr2[5:0]};

//	ram64x256 ram64x256_inst_0(
//		.clock(clk),
//		.data(M_axi_rdata),
//		.rdaddress(),
//		.wraddress(blk_ram_wr_addr),
//		.wren(blk_ram_write_enable),
//		.q);


	wire [C_S_AXI_DATA_WIDTH-1:0] dual_buffer_inst_doutb0;
	wire [C_S_AXI_DATA_WIDTH-1:0] dual_buffer_inst_doutb1;
	wire [C_S_AXI_DATA_WIDTH-1:0] dual_buffer_inst_doutb2;

	reg [7:0] addrb0;
	reg [7:0] addrb1;
	reg [7:0] addrb2;

	wire [7:0] w_addrb0;
	wire [7:0] w_addrb1;
	wire [7:0] w_addrb2;


	// wea enable  logic
	reg wea_0;
	reg wea_1;
	reg wea_2;

	reg[C_S_AXI_DATA_WIDTH-1:0] r_M_axi_rdata_0;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_M_axi_rdata;


	

	always @(posedge clk) begin : proc_r_M_axi_rdata
		if(~reset_n) begin
			r_M_axi_rdata <= 0;
		end else begin
			r_M_axi_rdata <= M_axi_rdata;
		end
	end

	always @(posedge clk) begin : proc_wea_012
		if(~reset_n) begin
			wea_0 <= 0;
			wea_1 <= 0;
			wea_2 <= 0;
		end else begin
			wea_0 <= (r_fetch_rows_FSM == 4'b0001)? blk_ram_write_enable : 0;
			wea_1 <= (r_fetch_rows_FSM == 4'b0010)? blk_ram_write_enable : 0;
			wea_2 <= (r_fetch_rows_FSM == 4'b0011)? blk_ram_write_enable : 0;
		end
	end


//	dual_buffer dual_buffer_inst_0
//	(
//		.clock(clk),
//		.data(r_M_axi_rdata),
//		.rdaddress(w_addrb0),
//		.wraddress(w_blk_ram_wr_addr0),
//		.wren(wea_0),
//		.q(dual_buffer_inst_doutb0)
//	);

//	dual_buffer dual_buffer_inst_1
//	(
//		.clock(clk),
//		.data(r_M_axi_rdata),
//		.rdaddress(w_addrb1),
//		.wraddress(w_blk_ram_wr_addr1),
//		.wren(wea_1),
//		.q(dual_buffer_inst_doutb1)
//	);

//	dual_buffer dual_buffer_inst_2
//	(
//		.clock(clk),
//		.data(r_M_axi_rdata),
//		.rdaddress(w_addrb2),
//		.wraddress(w_blk_ram_wr_addr2),
//		.wren(wea_2),
//		.q(dual_buffer_inst_doutb2)
//	);
	
	 dual_buffer dual_buffer_inst_0
   (
	     .clka(clk),
	     .ena(1'b1), 
	     .wea(wea_0), 
	     .addra(w_blk_ram_wr_addr0), 
	     .dina(r_M_axi_rdata),
	     .clkb(clk),
	     .enb(1'b1), 
	     .addrb(w_addrb0), 
	     .doutb(dual_buffer_inst_doutb0) 
   );

   dual_buffer dual_buffer_inst_1
   (
	     .clka(clk),
	     .ena(1'b1), 
	     .wea(wea_1), 
	     .addra(w_blk_ram_wr_addr1), 
	     .dina(r_M_axi_rdata),
	     .clkb(clk),
	     .enb(1'b1), 
	     .addrb(w_addrb1), 
	     .doutb(dual_buffer_inst_doutb1) 
   );

   dual_buffer dual_buffer_inst_2
   (
	     .clka(clk),
	     .ena(1'b1), 
	     .wea(wea_2), 
	     .addra(w_blk_ram_wr_addr2), 
	     .dina(r_M_axi_rdata),
	     .clkb(clk),
	     .enb(1'b1), 
	     .addrb(w_addrb2), 
	     .doutb(dual_buffer_inst_doutb2) 
   );
	//--------------------------------------------------------------------------------------------
	//----------- logic for reading and providing required data-----------------------------------
	//--------------------------------------------------------------------------------------------


	reg[3:0] axi_read_FSM;
	reg r_Start; // registering start signal
	always @(posedge clk) begin : proc_r_Start
		if(~reset_n) begin
			r_Start <= 0;
		end else if(Start)begin
			r_Start <= 1'b1;
		end else if(r_feed_done) begin
			r_Start <= 1'b0;
		end
	end

	always@(posedge clk) begin
		if(~reset_n || Start || r_fetch_rows_FSM == 0 || r_fetch_rows_FSM >= 4'b0100) begin
			axi_read_FSM <= 0;
		end else begin
			case(axi_read_FSM) 
				4'b0000 : if(in_layer_ddr3_data_rdy & r_Start) axi_read_FSM <= 4'b0001;
				4'b0001 : if(M_axi_arvalid && M_axi_arready) axi_read_FSM <= 4'b0010;
				4'b0010 : if(M_axi_rready & M_axi_rvalid & M_axi_rlast) axi_read_FSM <= 4'b0000;
			endcase
		end
	end

	reg r_M_axi_rready;
	always @(posedge clk) begin
		if( ~reset_n | (M_axi_rready & M_axi_rvalid & M_axi_rlast) | Start)
       		r_M_axi_rready <= 0;
       	else if(M_axi_rvalid)begin
       		r_M_axi_rready <= 1;
       	end
    end
    assign M_axi_rready = r_M_axi_rready;

    reg r_M_axi_arvalid;
    always @(posedge clk) begin
        if(~reset_n || (M_axi_arvalid && M_axi_arready) || Start) begin
            r_M_axi_arvalid <= 0;
        end else if(axi_read_FSM == 4'b0001 & ~r_M_axi_arvalid) begin
            r_M_axi_arvalid <= 1;
        end
    end
    assign M_axi_arvalid = r_M_axi_arvalid;

	


	//-----------------------------------------------------------------------------------------------------
	//--------------- Reading from block ram and feeding to logic -----------------------------------------
	//-----------------------------------------------------------------------------------------------------

	wire [3:0] fifo_count_0;
	wire [3:0] fifo_count_1;
	wire [3:0] fifo_count_2;

	wire [STREAM_DATA_WIDTH/3 -1:0] data_o_0;
	wire [STREAM_DATA_WIDTH/3 -1:0] data_o_1;
	wire [STREAM_DATA_WIDTH/3 -1:0] data_o_2;

	reg r_push0_0;
	reg r_push1_0;
	reg r_push2_0;


	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_0_data_in;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_1_data_in;
	reg [C_S_AXI_DATA_WIDTH-1:0] r_fifo_2_data_in;

	wire pop_fifo = valid_transation;
	wire data_in_blk_ram = ((r_inputlayer_id < r_next_inputlayer_id) && (r_row_position_id == r_next_row_id)) || (r_row_position_id < r_next_row_id);

	reg r_fetch_data_fifo_0;
	reg r_fetch_data_fifo_1;
	reg r_fetch_data_fifo_2;

	// making upper zero padding and lower zero padding
	always @(posedge clk) begin : proc_r_fifo_0_data_in
		if(~reset_n | Start) begin
			r_fifo_0_data_in <= 0;
		end else if(r_row_position_id == 0 && r_fetch_data_fifo_0 && ~stride2en) begin
			r_fifo_0_data_in <= 0;
		end else if(r_fetch_data_fifo_0) begin
			r_fifo_0_data_in <= dual_buffer_inst_doutb0;
		end
	end

	always @(posedge clk) begin : proc_r_fifo_1_data_in
		if(~reset_n | Start) begin
			r_fifo_1_data_in <= 0;
		end else if(r_fetch_data_fifo_1) begin
			r_fifo_1_data_in <= dual_buffer_inst_doutb1;
		end
	end

	always @(posedge clk) begin : proc_r_fifo_2_data_in
		if(~reset_n | Start) begin
			r_fifo_2_data_in <= 0;
		end else if(r_row_position_id == input_layer_row_size-1 && r_fetch_data_fifo_2 && ~stride2en) begin
			r_fifo_2_data_in <= 0;
		end else if(r_fetch_data_fifo_2) begin
			r_fifo_2_data_in <= dual_buffer_inst_doutb2;
		end
	end


	// register fifo instances
	// 8 byte push and 3 byte read and one byte shift per pop
	reg_fifo_16 reg_fifo_inst0(
		.clk(clk),
		.reset_n(reset_n),
		.Start(Start),
		.one_row_complete(one_row_complete),
		.stride2en(stride2en),
		.data_in(r_fifo_0_data_in),
		.push(r_push0_0),
		.pop(pop_fifo),
		.data_o(data_o_0),
		.count(fifo_count_0)
	);

	reg_fifo_16 reg_fifo_inst1(
		.clk(clk),
		.reset_n(reset_n),
		.Start(Start),
		.one_row_complete(one_row_complete),
		.stride2en(stride2en),
		.data_in(r_fifo_1_data_in),
		.push(r_push1_0),
		.pop(pop_fifo),
		.data_o(data_o_1),
		.count(fifo_count_1)
	);

	reg_fifo_16 reg_fifo_inst2(
		.clk(clk),
		.reset_n(reset_n),
		.Start(Start),
		.one_row_complete(one_row_complete),
		.stride2en(stride2en),
		.data_in(r_fifo_2_data_in),
		.push(r_push2_0),
		.pop(pop_fifo),
		.data_o(data_o_2),
		.count(fifo_count_2)
	);

	// start ptoviding data with valid siginal if a row is fetched
	wire data_is_available = (fifo_count_0 >= 3) && (fifo_count_1 >= 3) && (fifo_count_2 >= 3) && (data_in_blk_ram);

	reg [1:0] r_row_select;
	reg [7:0] rdaddress;

	reg [7:0] r_read_ptr0;
	reg [7:0] r_read_ptr1;
	reg [7:0] r_read_ptr2;


	wire w_fetch_data_fifo_0 = (fifo_count_0 <= 6) && data_in_blk_ram && ~(r_push0_0 | r_fetch_data_fifo_0) && ~layer_complete ? 1 : 0;
	wire w_fetch_data_fifo_1 = (fifo_count_1 <= 6) && data_in_blk_ram && ~(r_push1_0 | r_fetch_data_fifo_1) && ~layer_complete ? 1 : 0;
	wire w_fetch_data_fifo_2 = (fifo_count_2 <= 6) && data_in_blk_ram && ~(r_push2_0 | r_fetch_data_fifo_2) && ~layer_complete ? 1 : 0;

	// state machine for fetch_data_fifo
	reg [1:0] r_fetch_data_FSM;
	always @(posedge clk) begin : proc_r_fetch_data_FSM
		if(~reset_n | Start | one_row_complete) begin
			r_fetch_data_FSM <= 0;
			r_fetch_data_fifo_0 <= 0;
			r_fetch_data_fifo_1 <= 0;
			r_fetch_data_fifo_2 <= 0;
		end else begin
			 case(r_fetch_data_FSM)
			 	2'b00: begin r_fetch_data_FSM <= 2'b01; r_fetch_data_fifo_0 <= 0; r_fetch_data_fifo_1 <= 0; r_fetch_data_fifo_2 <= 0; end
			 	2'b01: begin r_fetch_data_FSM <= 2'b10; r_fetch_data_fifo_0 <= 0; r_fetch_data_fifo_1 <= 0; r_fetch_data_fifo_2 <= 0; end
			 	2'b10: begin r_fetch_data_FSM <= 2'b11; r_fetch_data_fifo_0 <= 0; r_fetch_data_fifo_1 <= 0; r_fetch_data_fifo_2 <= 0; end
			 	2'b11: begin 
			 				//r_fetch_data_FSM <= 2'b01;
			 				r_fetch_data_fifo_0 <= w_fetch_data_fifo_0;
							r_fetch_data_fifo_1 <= w_fetch_data_fifo_1;
							r_fetch_data_fifo_2 <= w_fetch_data_fifo_2;
			 			end
			 endcase // r_fetch_data_FSM
		end
	end


	reg [1:0] r_blk_read_offset_select;
	always @(posedge clk) begin : proc_r_blk_read_offset_select
		if(~reset_n | Start) begin
			r_blk_read_offset_select <= 0;
		end else if(one_row_complete)begin
			r_blk_read_offset_select <= r_blk_read_offset_select + 1;
		end
	end

	always@(posedge clk) begin
		if(~reset_n | Start | r_feed_done) begin
			addrb0 <= 8'h0;
		end else if(one_row_complete) begin
			addrb0 <= 8'h0;
		end else if(r_fetch_data_fifo_0) begin
			addrb0 <= addrb0 + 1;
		end
	end
	assign w_addrb0 = {r_blk_read_offset_select, addrb0[5:0]};

	always@(posedge clk) begin
		if(~reset_n | Start | r_feed_done) begin
			addrb1 <= 0;
		end else if(one_row_complete) begin
			addrb1 <= 0;
		end else if(r_fetch_data_fifo_1) begin
			addrb1 <= addrb1 + 1;
		end
	end
	assign w_addrb1 = {r_blk_read_offset_select, addrb1[5:0]};

	always@(posedge clk) begin
		if(~reset_n | Start | r_feed_done) begin
			addrb2 <= 0;
		end else if(one_row_complete) begin
			addrb2 <= 0;
		end else if(r_fetch_data_fifo_2) begin
			addrb2 <= addrb2 + 1;
		end
	end
	assign w_addrb2 = {r_blk_read_offset_select, addrb2[5:0]};

	


	always@(posedge clk) begin
		if(~reset_n | Start | one_row_complete | r_feed_done) begin
			r_push0_0 <= 0;
			r_push1_0 <= 0;
			r_push2_0 <= 0;
		end else begin
			r_push0_0 <= r_fetch_data_fifo_0;
			r_push1_0 <= r_fetch_data_fifo_1;
			r_push2_0 <= r_fetch_data_fifo_2;
		end
	end

	reg end_valid;
	always@(posedge clk) begin
		if(~reset_n | Start) begin
			end_valid <= 0;
		end else if((r_col_postion_id == input_layer_col_size - 2) && valid_transation) begin
			end_valid <= 1;
		end else if(valid_transation) begin
			end_valid <= 0;
		end
	end


	wire 								input_layer_1_valid;
	wire [STREAM_DATA_WIDTH-1:0] 		input_layer_1_data;

	assign input_layer_1_valid = data_is_available | end_valid;
	assign input_layer_1_data = (end_valid & ~stride2en) ?{8'b0,data_o_0[15:0], 8'b0,data_o_1[15:0], 8'b0, data_o_2[15:0]} : {data_o_0, data_o_1, data_o_2};

	reg 			r_input_fifo_wr_en;
	reg 			r_input_fifo_wr_en_p1;
	reg 			r_input_fifo_wr_en_p2;


	wire 	[7:0]   					w_input_fifo_count;
 	wire    [STREAM_DATA_WIDTH-1:0]  	w_casted_vals;
 	wire 								w_input_fifo_empty;

	always @(posedge clk) begin : proc_r_input_fifo_wr_en
		if(~reset_n || Start) begin
			r_input_fifo_wr_en <= 0;
		end else if(w_input_fifo_count < 200 && input_layer_1_valid && ~r_input_fifo_wr_en)begin
			r_input_fifo_wr_en <= 1;
		end else begin
			r_input_fifo_wr_en <= 0;
		end
	end

	always @(posedge clk) begin : proc_r_input_fifo_wr_en_p1_2
		if(~reset_n || Start) begin
			r_input_fifo_wr_en_p1 <= 0;
			r_input_fifo_wr_en_p2 <= 0;
		end else begin
			r_input_fifo_wr_en_p1 <= r_input_fifo_wr_en;
			r_input_fifo_wr_en_p2 <= r_input_fifo_wr_en_p1;
		end
	end


	int2float8 int2float8_inst_0(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[7:0]),
		.out_fl8  	(w_casted_vals[7:0])
	);

	int2float8 int2float8_inst_1(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[15:8]),
		.out_fl8  	(w_casted_vals[15:8])
	);

	int2float8 int2float8_inst_2(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[23:16]),
		.out_fl8  	(w_casted_vals[23:16])
	);

	int2float8 int2float8_inst_3(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[31:24]),
		.out_fl8  	(w_casted_vals[31:24])
	);

	int2float8 int2float8_inst_4(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[39:32]),
		.out_fl8  	(w_casted_vals[39:32])
	);

	int2float8 int2float8_inst_5(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[47:40]),
		.out_fl8  	(w_casted_vals[47:40])
	);

	int2float8 int2float8_inst_6(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[55:48]),
		.out_fl8  	(w_casted_vals[55:48])
	);

	int2float8 int2float8_inst_7(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[63:56]),
		.out_fl8  	(w_casted_vals[63:56])
	);

	int2float8 int2float8_inst_8(
		.clk  		(clk),
		.reset_n 	(reset_n),
		.cast_ 		(cast_),
		.int8_in 	(input_layer_1_data[71:64]),
		.out_fl8  	(w_casted_vals[71:64])
	);

	// input_fifo input_fifo_inst(
	// 	.clock(clk),
	// 	.data(w_casted_vals),
	// 	.rdreq(input_layer_data_rdy),
	// 	.sclr(~reset_n || Start),
	// 	.wrreq(r_input_fifo_wr_en_p2),
	// 	.empty(w_input_fifo_empty),
	// 	.q(input_layer_data_3x3),
	// 	.usedw(w_input_fifo_count)
	// );

	fifo_generator_0 fifo_generator_0_inst(
    	.clk(clk),
    	.srst(~reset_n || Start),
    	.din(w_casted_vals),
    	.wr_en(r_input_fifo_wr_en_p2),
    	.rd_en(input_layer_data_rdy),
    	.dout(input_layer_data_3x3),
    	.full(),
    	.empty(w_input_fifo_empty),
    	.data_count(w_input_fifo_count)
  );

	assign input_layer_data_valid = ~w_input_fifo_empty;

endmodule


