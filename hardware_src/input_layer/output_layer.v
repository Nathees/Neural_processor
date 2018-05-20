module output_layer# (

            parameter                           C_S_AXI_ID_WIDTH              =     3,
            parameter                           C_S_AXI_ADDR_WIDTH            =     32,
            parameter                           C_S_AXI_DATA_WIDTH            =     64,
            parameter                           C_S_AXI_BURST_LEN             =     8,
            parameter                           STREAM_DATA_WIDTH             =     8
             
    ) (
	// parameters from axi_lite
	input 												Start,
	input 	[C_S_AXI_ADDR_WIDTH -1 : 0] 				axi_address,
	input 	[9:0] 										no_of_output_layers,
	input 	[9:0] 										output_layer_row_size,
	input 	[9:0] 										output_layer_col_size,
	input 												larger_block_en,
	input 	[9:0] 										allocated_space_per_row,
	input 	[7:0] 										burst_per_row,
	input 	[3:0] 										write_burst_len,


	// streaming data
	// ids will increment sequentially, but provieded as extra info
	// transsaction will occur when ready and valid are high
	// processing part should monitor valid before sending valid outputs
	input [STREAM_DATA_WIDTH-1:0] output_layer_1_data,
	input [9:0] out_fifo_1_dcount,
	output  out_fifo_1_rd_en, 


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


	input	wire [C_S_AXI_ID_WIDTH-1:0] 							M_axi_bid,
	input	wire [1:0] 												M_axi_bresp,
	input	wire [0:0] 												M_axi_bvalid,
	output	wire [0:0] 												M_axi_bready
	);



// axi settings
	// Write Address Control Signals
	assign M_axi_awid = 0;
	assign M_axi_awlen = write_burst_len;
	assign M_axi_awsize = 3;
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;
	assign M_axi_wstrb = 8'hff;



	


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


// a block ram will act as intermediate between 
// fifo output and ddr3 axi
// separate trackers for tracking inputlayer, coloumn and row
// for fifo side and axi ddr3 side

// block ram will be partitoned into four such that it can 
// store upto four rows at once


	reg [9:0] r_input_layer_id_fifo;
	reg [9:0] r_col_id_fifo;
	reg [9:0] r_8byte_col_size;
	reg [9:0] r_row_id_fifo;

	reg [9:0] r_row_id_axi;
	reg [9:0] r_input_layer_id_axi;

	reg r_axi_row_write_complete;

	reg r_fifo_col_almost_end;
	wire w_fifo_col_complete;
	reg r_fifo_col_complete;
	reg r_fifo_col_complete_p1;
	reg r_fifo_col_complete_p2;


	reg r_fifo_layer_complete;





//-------------------------------------------------------------------------------------------------
//-------------------- Condition to fetch from fifo------------------------------------------------
//-------------------------------------------------------------------------------------------------
	wire cmp_input_layer_id = (r_input_layer_id_fifo - r_input_layer_id_axi <= 1) && (r_row_id_fifo == r_row_id_axi);
	wire cmp_row_id = (r_input_layer_id_axi == no_of_output_layers -1 ) && (r_row_id_fifo - r_row_id_axi <= 1) && (r_input_layer_id_fifo < 1);
	wire w_fetch_from_fifo = ( cmp_input_layer_id | cmp_row_id? 1 : 0);

	wire data_in_blk_ram = ((r_input_layer_id_axi < r_input_layer_id_fifo) && (r_row_id_axi == r_row_id_fifo)) || (r_row_id_axi < r_row_id_fifo);
	reg r_data_in_blk_ram;
	always @(posedge clk) begin : proc_r_data_in_blk_ram
		if(~reset_n || Start) begin
			r_data_in_blk_ram <= 0;
		end else begin
			r_data_in_blk_ram <= data_in_blk_ram;
		end
	end



	reg r_pull_from_fifo;
	always @(posedge clk) begin : proc_r_pull_from_fifo
		if(~reset_n || Start) begin
			r_pull_from_fifo <= 0;
		end else begin
			r_pull_from_fifo <= w_fetch_from_fifo;
		end
	end


	always @(posedge clk) begin : proc_r_8byte_col_size
		if(~reset_n) begin
			r_8byte_col_size <= 0;
		end else if(Start) begin
			r_8byte_col_size <= (output_layer_col_size[2:0] == 0 ? output_layer_col_size[9:3] : output_layer_col_size[9:3] + 1);
		end
	end

	reg r_8byte_row_vaid;
	always @(posedge clk) begin : proc_r_8byte_row_vaid
		if(~reset_n) begin
			r_8byte_row_vaid <= 0;
		end else if(Start)begin
			r_8byte_row_vaid <= (output_layer_col_size[2:0] == 0 ? 1 : 0);
		end
	end



//-------------------------------------------------------------------------------------------------
//-------------------- r_col_id_fifo, r_input_layer_id_fifo & r_row_id_fifo -----------------------
//-------------------------------------------------------------------------------------------------

	always @(posedge clk) begin : proc_r_fifo_col_almost_end
		if(~reset_n || Start) begin
			r_fifo_col_almost_end <= 0;
		end else if(r_out_fifo_1_rd_en && r_col_id_fifo == output_layer_col_size-2) begin
			r_fifo_col_almost_end <= 1;
		end else if(r_out_fifo_1_rd_en)begin
			r_fifo_col_almost_end <= 0;
		end
	end

	assign w_fifo_col_complete = r_out_fifo_1_rd_en && r_fifo_col_almost_end;

	// registering w_fifo_col_complete
	always @(posedge clk) begin : proc_r_fifo_col_complete
		if(~reset_n || Start) begin
			r_fifo_col_complete <= 0;
			r_fifo_col_complete_p1 <= 0;
			r_fifo_col_complete_p2 <= 0;
		end else begin
			r_fifo_col_complete <= w_fifo_col_complete ;
			r_fifo_col_complete_p1 <= r_fifo_col_complete;
			r_fifo_col_complete_p2 <= r_fifo_col_complete_p1;
		end
	end

	always @(posedge clk) begin : proc_r_col_id_fifo
		if(~reset_n || Start) begin
			r_col_id_fifo <= 0;
		end else if(w_fifo_col_complete)begin
			r_col_id_fifo <= 0;
		end else if(r_out_fifo_1_rd_en) begin
			r_col_id_fifo <= r_col_id_fifo + 1;
		end
	end

	always @(posedge clk) begin : proc_r_input_layer_id_fifo
		if(~reset_n || Start) begin
			r_input_layer_id_fifo <= 0;
		end else if(r_out_fifo_1_rd_en && r_fifo_col_almost_end && r_input_layer_id_fifo >= no_of_output_layers-1) begin
			r_input_layer_id_fifo <= 0;
		end else if(r_out_fifo_1_rd_en && r_fifo_col_almost_end) begin
			r_input_layer_id_fifo <= r_input_layer_id_fifo + 1;
		end
	end

	always @(posedge clk) begin : proc_r_row_id_fifo
		if(~reset_n || Start) begin
			r_row_id_fifo <= 0;
		end else if(r_out_fifo_1_rd_en && r_fifo_col_almost_end && r_input_layer_id_fifo >= no_of_output_layers-1)begin
			r_row_id_fifo <= r_row_id_fifo + 1;
		end
	end



	// logic for detecting layer complete 
	always @(posedge clk) begin : proc_r_fifo_layer_complete
		if(~reset_n || Start) begin
			r_fifo_layer_complete <= 0;
		end else if(r_row_id_fifo >= output_layer_row_size)begin
			r_fifo_layer_complete <= 1;
		end else begin
			r_fifo_layer_complete <= 0;
		end
	end

	




// FSM for writing fifo contents to blk ram
	reg [3:0] r_FSM_row_former;
	reg [63:0] r_blk_row;
	reg [63:0] r_dina;
	reg r_wea;



//--------------------------------------------------------------------------------------------
// -------------   registering out_fifo_1_rd_en to syn with ----------------------------------
//--------------------------------------------------------------------------------------------
	reg r_out_fifo_1_rd_en;
	reg r_out_fifo_1_rd_en_p1;

	reg[1:0] fifo_rd_en_delay;
	always @(posedge clk) begin : proc_fifo_rd_en_delay
		if(~reset_n | Start | w_fifo_col_complete) begin
			fifo_rd_en_delay <= 0;
		end else if(fifo_rd_en_delay <= 2)begin
			fifo_rd_en_delay <= fifo_rd_en_delay + 1;
		end
	end

	always @(posedge clk) begin : proc_r_out_fifo_1_rd_en
		if(~reset_n || fifo_rd_en_delay <= 2 || w_fifo_col_complete || r_fifo_layer_complete || Start) begin
			r_out_fifo_1_rd_en <= 0;
		end else if(r_pull_from_fifo && out_fifo_1_dcount >= 2)begin
			r_out_fifo_1_rd_en <= 1;
		end else if(~r_out_fifo_1_rd_en && r_pull_from_fifo && out_fifo_1_dcount == 1) begin
			r_out_fifo_1_rd_en <= 1;
		end else begin
			r_out_fifo_1_rd_en <= 0;
		end
	end

	always @(posedge clk) begin : proc_r_out_fifo_1_rd_en_p1
		if(~reset_n || Start) begin
			r_out_fifo_1_rd_en_p1 <= 0;
		end else begin
			r_out_fifo_1_rd_en_p1 <= r_out_fifo_1_rd_en;
		end
	end

	assign out_fifo_1_rd_en = r_out_fifo_1_rd_en;

//--------------------------------------------------------------------------------------------
//-------------- Forming a  8 byte ROW -------------------------------------------------------
//--------------------------------------------------------------------------------------------
	always @(posedge clk) begin : proc_r_FSM_row_former
		if(~reset_n ||| Start ||| r_fifo_col_complete_p1) begin
			r_FSM_row_former <= 0;
		end else if(r_out_fifo_1_rd_en_p1 && r_FSM_row_former == 7)begin
			r_FSM_row_former <= 0;
		end else if(r_out_fifo_1_rd_en_p1) begin
			r_FSM_row_former <= r_FSM_row_former + 1;
		end
	end

	// latching fifo data to reg
	always @(posedge clk) begin : proc_r_blk_row
		if(~reset_n || Start || r_fifo_col_complete_p1) begin
			r_blk_row <= 0;
		end else if(r_out_fifo_1_rd_en_p1) begin
			 case(r_FSM_row_former)
			 	4'b0000 : r_blk_row[7:0] <= output_layer_1_data;
			 	4'b0001 : r_blk_row[15:8] <= output_layer_1_data;
			 	4'b0010 : r_blk_row[23:16] <= output_layer_1_data;
			 	4'b0011 : r_blk_row[31:24] <= output_layer_1_data;
			 	4'b0100 : r_blk_row[39:32] <= output_layer_1_data;
			 	4'b0101 : r_blk_row[47:40] <= output_layer_1_data;
			 	4'b0110 : r_blk_row[55:48] <= output_layer_1_data;
			 	4'b0111 : r_blk_row[63:56] <= output_layer_1_data;
			 endcase
		end
	end

	always @(posedge clk) begin : proc_r_dina
		if(~reset_n || Start) begin
			r_dina <= 0;
		end else if(r_FSM_row_former == 7 && r_out_fifo_1_rd_en_p1) begin
			r_dina <= {output_layer_1_data, r_blk_row[55:0]};
		end else if(r_fifo_col_complete_p1) begin
			r_dina <= r_blk_row;
		end
	end

	always @(posedge clk) begin : proc_r_wea
		if(~reset_n || Start) begin
			r_wea <= 0;
		end else begin
			r_wea <= (r_FSM_row_former == 7 && r_out_fifo_1_rd_en_p1) || (r_fifo_col_complete_p1 && ~r_8byte_row_vaid) ? 1 : 0;
		end
	end



//------------------------------------------------------------------------------------------
//-------------------- Block RAM control signals -------------------------------------------
//------------------------------------------------------------------------------------------
	// block ram address counter and offset select
	reg [1:0] r_blk_write_offset;
	reg [1:0] r_blk_read_offset;
	reg [5:0] r_addra;
	reg [5:0] r_addrb;

	// need to adjust this signal to sync with
	// data and addra
	//wire row_complete = out_fifo_1_rd_en && r_fifo_col_almost_end;
	// always @(posedge clk) begin : proc_r_blk_write_offset
	// 	if(~reset_n || Start) begin
	// 		r_blk_write_offset <= 0;
	// 	end else if(r_fifo_col_complete_p2)begin
	// 		r_blk_write_offset <= r_blk_write_offset + 1;
	// 	end
	// end

	// always @(posedge clk) begin : proc_r_addra
	// 	if(~reset_n || Start || r_fifo_col_complete_p2) begin
	// 		r_addra <= 0;
	// 	end else if(r_wea)begin
	// 		r_addra <= r_addra + 1;;
	// 	end
	// end

	// wire [7:0] w_blk_addra = {r_blk_write_offset, r_addra[5:0]};
	// wire [7:0] w_addrb;
	// creating a dual block ram instance
	// dual_buffer dual_buffer_inst_0
 //  (
	//     .clka(clk),
	//     .ena(1'b1), 
	//     .wea(r_wea), 
	//     .addra(w_blk_addra), 
	//     .dina(r_dina),
	//     .clkb(clk),
	//     .enb(1'b1), 
	//     .addrb(w_addrb), 
	//     .doutb(M_axi_wdata) 
 //  );

  wire [7:0] w_data_count;

  wire w_fifo_rd_en = M_axi_wvalid && M_axi_wready && ~r_hold_fifo_rd;
  // out_buffer out_buffer_inst
  // (
  //   .clk 				(clk), 
  //   .srst 				(~reset_n), 
  //   .din 				(r_dina),
  //   .wr_en 				(r_wea), 
  //   .rd_en 				(w_fifo_rd_en), 
  //   .dout 				(M_axi_wdata), 
  //   .full 				(), 
  //   .empty 				(), 
  //   .data_count 		(w_data_count)	 
  // );

 // altera
 //  	dual_buffer dual_buffer_inst_0
	// (
	// 	.clock(clk),
	// 	.data(r_dina),
	// 	.rdaddress(w_addrb),
	// 	.wraddress(w_blk_addra),
	// 	.wren(r_wea),
	// 	.q(M_axi_wdata)
	// );
 

 out_buffer out_buffer_inst
 	(
		.clock				(clk),
		.data				(r_dina),
		.rdreq				(w_fifo_rd_en),
		.sclr				(~reset_n | Start),
		.wrreq				(r_wea),
		.q					(M_axi_wdata),
		.usedw				(w_data_count)
	);




//-------------------------------------------------------------------------------------------
//------------------- udating axi related input layer , row & col ID ------------------------
//-------------------------------------------------------------------------------------------

 	
 	always @(posedge clk) begin : proc_r_axi_row_write_complete
 		if(~reset_n || Start) begin
 			r_axi_row_write_complete <= 0;
 		end else begin
 			r_axi_row_write_complete <= row_finished;
 		end
 	end

 	always @(posedge clk) begin : proc_r_input_layer_id_axi
 		if(~reset_n || Start) begin
 			r_input_layer_id_axi <= 0;
 		end else if(r_axi_row_write_complete && r_input_layer_id_axi >= no_of_output_layers - 1) begin
 			r_input_layer_id_axi <= 0;
 		end else if(r_axi_row_write_complete) begin
 			r_input_layer_id_axi <= r_input_layer_id_axi + 1;
 		end
 	end

 	always @(posedge clk) begin : proc_r_row_id_axi
 		if(~reset_n || Start) begin
 			r_row_id_axi <= 0;
 		end else if(r_axi_row_write_complete && r_input_layer_id_axi >= no_of_output_layers - 1) begin
 			r_row_id_axi <= r_row_id_axi + 1;
 		end
 	end

 	// always @(posedge clk) begin : proc_r_blk_read_offset
 	// 	if(~reset_n || Start) begin
 	// 		r_blk_read_offset <= 0;
 	// 	end else if(r_axi_row_write_complete) begin
 	// 		r_blk_read_offset <= r_blk_read_offset + 1;
 	// 	end
 	// end


 	// always @(posedge clk) begin : proc_r_addrb
 	// 	if(~reset_n || Start || r_axi_row_write_complete) begin
 	// 		r_addrb <= 0;
 	// 	end else if(r_axi_write_FSM == 4'b0010 && M_axi_wready) begin
 	// 		r_addrb <= r_addrb + 1;
 	// 	end
 	// end
 	// assign w_addrb = {r_blk_read_offset, r_addrb};

 	reg [9:0] r_fifo_8byte_rd_couter;
 	always @(posedge clk) begin : proc_r_fifo_8byte_rd_couter
 		if(~reset_n || Start || r_axi_row_write_complete) begin
 			r_fifo_8byte_rd_couter <= 0;
 		end else if(M_axi_wready && M_axi_wvalid && r_axi_write_FSM == 4'b0010) begin
 			r_fifo_8byte_rd_couter <= r_fifo_8byte_rd_couter + 1;
 		end
 	end

 	reg r_M_axi_wvalid;
 	reg r_hold_fifo_rd;
 	always @(posedge clk) begin : proc_r_M_axi_wvalid_1
 		if(~reset_n || Start || (r_axi_write_FSM == 4'b0010 && M_axi_wvalid && M_axi_wready && M_axi_wlast)) begin
 			r_M_axi_wvalid <= 0;
 		end else if(r_axi_write_FSM == 4'b0010 && (r_fifo_8byte_rd_couter >= r_8byte_col_size)) begin
 			r_M_axi_wvalid <= 1;
 		end else if(r_axi_write_FSM == 4'b0010 && w_data_count >= 2) begin
 			r_M_axi_wvalid <= 1;
 		end else if(r_axi_write_FSM == 4'b0010 && w_data_count  == 1 && ~w_fifo_rd_en) begin
 			r_M_axi_wvalid <= 1;
 		end  else begin
 			r_M_axi_wvalid <= 0;
 		end
 	end

 	always @(posedge clk) begin : proc_r_hold_fifo_rd
 		if(~reset_n || Start || r_axi_row_write_complete) begin
 			r_hold_fifo_rd <= 0;
 		end else if(r_fifo_8byte_rd_couter >= r_8byte_col_size || (r_fifo_8byte_rd_couter == r_8byte_col_size - 1 && M_axi_wready && M_axi_wvalid))begin
 			r_hold_fifo_rd <= 1;
 		end
 	end
 	assign M_axi_wvalid = r_M_axi_wvalid;

//********************************************************************************
//********** AXI Write **********************************************************
//********************************************************************************




	//-----------------------------------------------------------------------------
	//-----------------------Address Generation------------------------------------
	//-----------------------------------------------------------------------------

	reg [15:0] r_row_base_address_counter;
	reg [15:0] r_row_current_address_counter;
	reg [31:0] r_next_axi_address;
	//reg [7:0] r_burst_counter;

	always @(posedge clk) begin : proc_r_row_base_address_counter
		if(~reset_n || Start) begin
			r_row_base_address_counter <= 0;
		end else if ((r_input_layer_id_axi == no_of_output_layers -1) && row_finished) begin
			r_row_base_address_counter <= r_row_base_address_counter + allocated_space_per_row;
		end
	end

	always @(posedge clk) begin : proc_r_row_current_address_counter
		if(~reset_n || Start) begin
			r_row_current_address_counter <= 0;
		end else if(r_row_write_FSM == 4'b0000) begin
			r_row_current_address_counter <= r_row_base_address_counter;
		end else if(M_axi_wvalid & M_axi_wready) begin
			r_row_current_address_counter <= r_row_current_address_counter + 8;
		end
	end

	always @(posedge clk) begin : proc_r_next_axi_address_offset
		if(~reset_n) begin
			r_next_axi_address <= 0;
		end else if(larger_block_en) begin
			r_next_axi_address <= {r_input_layer_id_axi, 16'b0} + r_row_current_address_counter + axi_address;
		end else begin
			r_next_axi_address <= {r_input_layer_id_axi, 12'b0} + r_row_current_address_counter + axi_address;
		end
	end
	assign M_axi_awaddr = r_next_axi_address;

	wire burst_done = (r_axi_write_FSM == 4'b0011) && r_M_axi_bready && M_axi_bvalid;
	wire row_finished = ((r_burst_counter == burst_per_row -1) && burst_done)? 1 : 0;

	reg [7:0] r_burst_counter;
	always @(posedge clk) begin : proc_r_burst_counter
		if(~reset_n || Start || r_row_write_FSM == 4'b0000 || row_finished) begin
			r_burst_counter <= 0;
		end else if(burst_done)begin
			r_burst_counter <= r_burst_counter + 1;
		end
	end

	reg[3:0] r_row_write_FSM;
	reg[3:0] r_axi_write_FSM;

	always @(posedge clk) begin : proc_r_row_write_FSM
		if(~reset_n || Start) begin
			r_row_write_FSM <= 0;
		end else begin
			case(r_row_write_FSM)
				4'b0000 : if(r_data_in_blk_ram) r_row_write_FSM <= 4'b0001;
				4'b0001 : if(row_finished) r_row_write_FSM <= 4'b0010;
				4'b0010 : r_row_write_FSM <= 4'b0011;
				4'b0011 : r_row_write_FSM <= 4'b0100;
				default : r_row_write_FSM <= 4'b0000;
			endcase // r_row_write_FSM
		end
	end

	//r_data_in_blk_ram
    always@(posedge clk) begin
        if(~reset_n || Start || r_row_write_FSM != 4'b0001) begin
            r_axi_write_FSM <= 0;
        end else begin 
            case(r_axi_write_FSM)
            	4'b0000 : r_axi_write_FSM<= 4'b0001; 
                4'b0001 : if(M_axi_awvalid & M_axi_awready)    r_axi_write_FSM <= 4'b0010;
                4'b0010 : if(M_axi_wvalid & M_axi_wready & M_axi_wlast) r_axi_write_FSM<= 4'b0011;
                4'b0011 : if(r_M_axi_bready & M_axi_bvalid) r_axi_write_FSM<= 4'b0100;
                4'b0100 : r_axi_write_FSM<= 4'b0000;
                default : r_axi_write_FSM<= 4'b0000;
                
            endcase
        end
    end

	// Valid for write address
	reg r_M_axi_awvalid;
	always @(posedge clk) begin
		if( ~reset_n || Start) begin
			r_M_axi_awvalid <= 0;
		end else if((r_M_axi_awvalid && M_axi_awready) || r_axi_write_FSM  != 4'b0001) begin
		    r_M_axi_awvalid <= 0;
	    end else if(~r_M_axi_awvalid && r_axi_write_FSM == 4'b0001) begin
            r_M_axi_awvalid <= 1;
        end
	end
	assign M_axi_awvalid = r_M_axi_awvalid;

	// valid for response signal
	reg r_M_axi_bready;
	always @(posedge clk) begin
	   if(~reset_n || M_axi_wlast && M_axi_wvalid && M_axi_wready ||  Start)
	         r_M_axi_bready <= 0;    
	   else
		     r_M_axi_bready <= 1; 		  
	end
	assign M_axi_bready = r_M_axi_bready;


	reg [7:0] r_M_w_burst_count;
	always @(posedge clk) begin
        if(~reset_n || (M_axi_wlast && M_axi_wvalid && M_axi_wready) || Start) begin
            r_M_w_burst_count <= 0;
        end else if(M_axi_wvalid && M_axi_wready)begin
            r_M_w_burst_count <= r_M_w_burst_count + 1;
        end
    end

    reg r_M_axi_wlast;
    always @(posedge clk) begin
	    if(~reset_n || Start || (r_M_axi_wlast && M_axi_wvalid && M_axi_wready))
	        r_M_axi_wlast <= 0;
	    else if((r_M_w_burst_count == M_axi_awlen -1) && M_axi_wvalid && M_axi_wready || (r_M_w_burst_count == M_axi_awlen && r_axi_write_FSM == 4'b0010))
	        r_M_axi_wlast <= 1;
	    else
	        r_M_axi_wlast <= 0;
    end
    assign M_axi_wlast = r_M_axi_wlast;


    // debug purpose
	reg [31:0]	r_clock_count /*synthesis noprune */;
	always @(posedge clk) begin : proc_r_clock_count
		if(~reset_n | Start) begin
			r_clock_count <= 0;
		end else if(r_row_id_axi < output_layer_row_size)begin
			r_clock_count <= r_clock_count + 1;
		end
	end

	

endmodule // output_layer