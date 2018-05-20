module kernel_loader #(

        parameter                           C_S_AXI_ID_WIDTH              =     3,
        parameter                           C_S_AXI_ADDR_WIDTH            =     32,
        parameter                           C_S_AXI_DATA_WIDTH            =     64,
        parameter                           C_S_AXI_BURST_LEN             =     8
         
    )(

	// input from parameter fetcher
	// skip unnecessary fifos
	input															Start,
	input 					[4:0] 									skip_en,

	input  wire 			[31:0]									kernel_0_start_addr,
	input  wire 			[31:0]									kernel_0_end_addr,
	input															kernel_0_wrap_en,
	output 					[C_S_AXI_DATA_WIDTH-1:0]  				kernel_0_fifo_wr_data,
	output 															kernel_0_fifo_wr_en,
	input 					[7:0] 									kernel_0_fifo_count,


	input  wire 			[31:0]									kernel_1_start_addr,
	input  wire 			[31:0]									kernel_1_end_addr,
	input															kernel_1_wrap_en,
	output 					[C_S_AXI_DATA_WIDTH-1:0]  				kernel_1_fifo_wr_data,
	output 															kernel_1_fifo_wr_en,
	input 					[7:0] 									kernel_1_fifo_count,

	input  wire 			[31:0]									kernel_2_start_addr,
	input  wire 			[31:0]									kernel_2_end_addr,
	input															kernel_2_wrap_en,
	output 					[C_S_AXI_DATA_WIDTH-1:0]  				kernel_2_fifo_wr_data,
	output 															kernel_2_fifo_wr_en,
	input 					[7:0] 									kernel_2_fifo_count,

    input  wire             [31:0]                                  kernel_3_start_addr,
    input  wire             [31:0]                                  kernel_3_end_addr,
    input                                                           kernel_3_wrap_en,
    output                  [C_S_AXI_DATA_WIDTH-1:0]                kernel_3_fifo_wr_data,
    output                                                          kernel_3_fifo_wr_en,
    input                   [7:0]                                   kernel_3_fifo_count,

    input  wire             [31:0]                                  kernel_4_start_addr,
    input  wire             [31:0]                                  kernel_4_end_addr,
    input                                                           kernel_4_wrap_en,
    output                  [C_S_AXI_DATA_WIDTH-1:0]                kernel_4_fifo_wr_data,
    output                                                          kernel_4_fifo_wr_en,
    input                   [7:0]                                   kernel_4_fifo_count,


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


//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

    // state machine will push data to output fifo according to 
    // random robin method
    // state will change according to rvalid & rready & rlast
    // fifo will be skiped according to input



    // AXI Settings
    // Write Address Control Signals
	assign M_axi_awid = 0;
	assign M_axi_awaddr = 32'h0;
	assign M_axi_awlen = C_S_AXI_BURST_LEN-1;
	assign M_axi_awsize = 3; //$clog2(C_S_AXI_DATA_WIDTH/8);
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;

	// Write Data Control Signals	
	assign M_axi_wdata  = 64'h0;
	assign M_axi_wstrb  = {(C_S_AXI_DATA_WIDTH/8){1'b0}}; 

	// Read Address COntrol Signals
	assign M_axi_arid = 3'b001;
	assign M_axi_araddr = r_read_axi_addr;
	assign M_axi_arlen = C_S_AXI_BURST_LEN - 1;
	assign M_axi_arsize = 3; //$clog2(C_S_AXI_DATA_WIDTH/8);
	assign M_axi_arburst = 1;
	assign M_axi_arlock = 0;
	assign M_axi_arcache = 4'b0011;
	assign M_axi_arprot = 0;
	assign M_axi_arqos = 0;



    reg [2:0] r_fifo_select;
    reg [2:0] r_fifo_select_p1;

    // kernel address trackers
    reg [31:0] r_kernel_0_addr;
    reg [31:0] r_kernel_1_addr;
    reg [31:0] r_kernel_2_addr;
    reg [31:0] r_kernel_3_addr;
    reg [31:0] r_kernel_4_addr;

    reg [7:0] r_fifo_0_burst_len;
    reg [7:0] r_fifo_1_burst_len;
    reg [7:0] r_fifo_2_burst_len;

    reg [7:0] r_M_axi_arlen;

	// address tracker
	// tracks address within a burst
    reg [31:0] r_addr_tracker;
    reg r_Start;

    // registering input fifo data and write
    // enable
    reg [63:0] r_fifo_wdata;
    reg r_fifo_0_wr_en;
    reg r_fifo_1_wr_en;
    reg r_fifo_2_wr_en;
    reg r_fifo_3_wr_en;
    reg r_fifo_4_wr_en;

    reg r_fifo_0_almost_full;
    reg r_fifo_1_almost_full;
    reg r_fifo_2_almost_full;
    reg r_fifo_3_almost_full;
    reg r_fifo_4_almost_full;


    always @(posedge clk) begin : proc_r_Start
        if(~reset_n) begin
            r_Start <= 0;
        end else if(Start) begin
            r_Start <= 1;
        end
    end

    always @(posedge clk) begin : proc_r_fifo_0_almost_full
    	if(~reset_n) begin
    		r_fifo_0_almost_full <= 0;
    	end else if(kernel_0_fifo_count > 200) begin
    		r_fifo_0_almost_full <= 1;
    	end else begin
    		r_fifo_0_almost_full <= 0;
    	end
    end

    always @(posedge clk) begin : proc_r_fifo_1_almost_full
    	if(~reset_n) begin
    		r_fifo_1_almost_full <= 0;
    	end else if(kernel_1_fifo_count > 100) begin
    		r_fifo_1_almost_full <= 1;
    	end else begin
    		r_fifo_1_almost_full <= 0;
    	end
    end

    always @(posedge clk) begin : proc_r_fifo_2_almost_full
    	if(~reset_n) begin
    		r_fifo_2_almost_full <= 0;
    	end else if(kernel_2_fifo_count > 100) begin
    		r_fifo_2_almost_full <= 1;
    	end else begin
    		r_fifo_2_almost_full <= 0;
    	end
    end

    always @(posedge clk) begin : proc_r_fifo_3_almost_full
        if(~reset_n) begin
            r_fifo_3_almost_full <= 0;
        end else if(kernel_3_fifo_count > 100) begin
            r_fifo_3_almost_full <= 1;
        end else begin
            r_fifo_3_almost_full <= 0;
        end
    end

    always @(posedge clk) begin : proc_r_fifo_4_almost_full
        if(~reset_n) begin
            r_fifo_4_almost_full <= 0;
        end else if(kernel_4_fifo_count > 100) begin
            r_fifo_4_almost_full <= 1;
        end else begin
            r_fifo_4_almost_full <= 0;
        end
    end

    reg [31:0] r_read_axi_addr;
    assign read_burst_done = M_axi_rready & M_axi_rvalid & M_axi_rlast;

    wire w_fifo_0_push_done = ((r_kernel_0_addr >= kernel_0_end_addr) ? 1 : 0);
    wire w_fifo_1_push_done = ((r_kernel_1_addr >= kernel_1_end_addr) ? 1 : 0);
    wire w_fifo_2_push_done = ((r_kernel_2_addr >= kernel_2_end_addr) ? 1 : 0);
    wire w_fifo_3_push_done = ((r_kernel_3_addr >= kernel_3_end_addr) ? 1 : 0);
    wire w_fifo_4_push_done = ((r_kernel_4_addr >= kernel_4_end_addr) ? 1 : 0);


    reg fifo_0_push_done;
    reg fifo_1_push_done;
    reg fifo_2_push_done;
    reg fifo_3_push_done;
    reg fifo_4_push_done;

    reg fifo_0_just_last_byte;
    reg fifo_1_just_last_byte;
    reg fifo_2_just_last_byte;
    reg fifo_3_just_last_byte;
    reg fifo_4_just_last_byte;

    always @(posedge clk) begin : proc_just_last_byte
        if(~reset_n | Start) begin
            fifo_0_just_last_byte <= 0;
            fifo_1_just_last_byte <= 0;
            fifo_2_just_last_byte <= 0;
            fifo_3_just_last_byte <= 0;
            fifo_4_just_last_byte <= 0;
        end else begin
            fifo_0_just_last_byte <= ((r_kernel_0_addr == kernel_0_end_addr -8 && M_axi_rready && M_axi_rvalid) ? 1 : 0);
            fifo_1_just_last_byte <= ((r_kernel_1_addr == kernel_1_end_addr -8 && M_axi_rready && M_axi_rvalid) ? 1 : 0);
            fifo_2_just_last_byte <= ((r_kernel_2_addr == kernel_2_end_addr -8 && M_axi_rready && M_axi_rvalid) ? 1 : 0);
            fifo_3_just_last_byte <= ((r_kernel_3_addr == kernel_3_end_addr -8 && M_axi_rready && M_axi_rvalid) ? 1 : 0);
            fifo_4_just_last_byte <= ((r_kernel_4_addr == kernel_4_end_addr -8 && M_axi_rready && M_axi_rvalid) ? 1 : 0);
        end
    end

    always @(posedge clk) begin : proc_fifo_push_done
        if(~reset_n | Start) begin
            fifo_0_push_done <= 0;
            fifo_1_push_done <= 0;
            fifo_2_push_done <= 0;
            fifo_3_push_done <= 0;
            fifo_4_push_done <= 0;
        end else begin
            fifo_0_push_done <= w_fifo_0_push_done ;
            fifo_1_push_done <= w_fifo_1_push_done ;
            fifo_2_push_done <= w_fifo_2_push_done ;
            fifo_3_push_done <= w_fifo_3_push_done ;
            fifo_4_push_done <= w_fifo_4_push_done ;
        end
    end

    always @(posedge clk) begin : proc_r_fifo_select
    	if(~reset_n | Start | ~r_Start) begin
    		r_fifo_select <= 0;
    	end else begin
    		case(r_fifo_select)
    		 	3'b000 :begin 
                            if(skip_en[0] || (r_fifo_0_almost_full || fifo_0_push_done) && axi_read_FSM != 4'b0001 && axi_read_FSM != 4'b0010) 
                                r_fifo_select <= 3'b001; 
                            else if(read_burst_done) 
                                r_fifo_select <= 3'b001; 
                        end
    		 	3'b001 :begin 
                            if(skip_en[1] || (r_fifo_1_almost_full || fifo_1_push_done) && axi_read_FSM != 4'b0001 && axi_read_FSM != 4'b0010) 
                                r_fifo_select <= 3'b010; 
                            else if(read_burst_done) 
                                r_fifo_select <= 3'b010; 
                        end
    			3'b010 :begin 
                            if(skip_en[2] || (r_fifo_2_almost_full || fifo_2_push_done) && axi_read_FSM != 4'b0001 && axi_read_FSM != 4'b0010) 
                                r_fifo_select <= 3'b011; 
                            else if(read_burst_done) 
                                r_fifo_select <= 3'b011; 
                        end
                3'b011 :begin 
                            if(skip_en[3] || (r_fifo_3_almost_full || fifo_3_push_done) && axi_read_FSM != 4'b0001 && axi_read_FSM != 4'b0010) 
                                r_fifo_select <= 3'b100; 
                            else if(read_burst_done) 
                                r_fifo_select <= 3'b100; 
                        end
                3'b100 :begin 
                            if(skip_en[4] || (r_fifo_4_almost_full || fifo_4_push_done) && axi_read_FSM != 4'b0001 && axi_read_FSM != 4'b0010) 
                                r_fifo_select <= 3'b000; 
                            else if(read_burst_done) 
                                r_fifo_select <= 3'b000; 
                        end
    			default : r_fifo_select <= 3'b000;
    		endcase
    	end
    end

    always @(posedge clk) begin : proc_r_fifo_select_p1
        if(~reset_n) begin
            r_fifo_select_p1 <= 0;
        end else begin
            r_fifo_select_p1 <= r_fifo_select;
        end
    end


    // kernel 0 address logic
    // it will wrap if it is enabled
    assign addres_set_done = M_axi_arvalid & M_axi_arready;
    always @(posedge clk) begin : proc_r_kernel_0_addr
    	if(~reset_n) begin
    		r_kernel_0_addr <= 0;
    	end else if(Start || (kernel_0_wrap_en && (kernel_0_end_addr <= r_kernel_0_addr) && axi_read_FSM == 4'b0100)) begin
    		r_kernel_0_addr <= kernel_0_start_addr;
    	end else if(r_fifo_select == 3'b000 && valid_rd_data ) begin
    		r_kernel_0_addr <= r_kernel_0_addr +  8;
    	end
    end

    // kernel 1 address logic
    // it will wrap if it is enabled
    always @(posedge clk) begin : proc_r_kernel_1_addr
    	if(~reset_n) begin
    		r_kernel_1_addr <= 0;
    	end else if(Start || (kernel_1_wrap_en && (kernel_1_end_addr <= r_kernel_1_addr) && axi_read_FSM == 4'b0100)) begin
    		r_kernel_1_addr <= kernel_1_start_addr;
    	end else if(r_fifo_select == 3'b001 && valid_rd_data) begin
    		r_kernel_1_addr <= r_kernel_1_addr +  8;
    	end
    end

    // kernel 2 address logic
    // it will wrap if it is enabled
    always @(posedge clk) begin : proc_r_kernel_2_addr
    	if(~reset_n) begin
    		r_kernel_2_addr <= 0;
    	end else if(Start || (kernel_2_wrap_en && (kernel_2_end_addr <= r_kernel_2_addr) && axi_read_FSM == 4'b0100)) begin
    		r_kernel_2_addr <= kernel_2_start_addr;
    	end else if(r_fifo_select == 3'b010 && valid_rd_data) begin
    		r_kernel_2_addr <= r_kernel_2_addr +  8;
    	end
    end

    // kernel 3 address logic
    // it will wrap if it is enabled
    always @(posedge clk) begin : proc_r_kernel_3_addr
        if(~reset_n) begin
            r_kernel_3_addr <= 0;
        end else if(Start || (kernel_3_wrap_en && (kernel_3_end_addr <= r_kernel_3_addr) && axi_read_FSM == 4'b0100)) begin
            r_kernel_3_addr <= kernel_3_start_addr;
        end else if(r_fifo_select == 3'b011 && valid_rd_data) begin
            r_kernel_3_addr <= r_kernel_3_addr +  8;
        end
    end

    // kernel 2 address logic
    // it will wrap if it is enabled
    always @(posedge clk) begin : proc_r_kernel_4_addr
        if(~reset_n) begin
            r_kernel_4_addr <= 0;
        end else if(Start || (kernel_4_wrap_en && (kernel_4_end_addr <= r_kernel_4_addr) && axi_read_FSM == 4'b0100)) begin
            r_kernel_4_addr <= kernel_4_start_addr;
        end else if(r_fifo_select == 3'b100 && valid_rd_data) begin
            r_kernel_4_addr <= r_kernel_4_addr +  8;
        end
    end


    // assigning address 
    always @(posedge clk) begin : proc_r_read_axi_addr
    	if(~reset_n | Start | ~r_Start) begin
    		r_read_axi_addr <= 0;
    	end else begin
    		case(r_fifo_select)
    			3'b000: if(axi_read_FSM == 4'b0000) r_read_axi_addr <= r_kernel_0_addr;
    			3'b001: if(axi_read_FSM == 4'b0000) r_read_axi_addr <= r_kernel_1_addr;
    			3'b010: if(axi_read_FSM == 4'b0000) r_read_axi_addr <= r_kernel_2_addr;
                3'b011: if(axi_read_FSM == 4'b0000) r_read_axi_addr <= r_kernel_3_addr;
                3'b100: if(axi_read_FSM == 4'b0000) r_read_axi_addr <= r_kernel_4_addr;
    			default : r_read_axi_addr <= 0;
    		endcase
    	end
    end

    always @(posedge clk) begin : proc_r_addr_tracker
    	if(~reset_n | Start) begin
    		r_addr_tracker <= 0;
    	end else if(addres_set_done) begin
    		r_addr_tracker <= M_axi_araddr;
    	end else if(M_axi_rvalid & M_axi_rready) begin
    		r_addr_tracker <= r_addr_tracker + 1;
    	end
    end


    // latching fifo write data to match with write enable
    always @(posedge clk) begin : proc_r_fifo_wdata
    	if(~reset_n | Start) begin
    		r_fifo_wdata <= 0;
    	end else begin
    		r_fifo_wdata <= M_axi_rdata;
    	end
    end


    // logic for fifo write enable
    assign valid_rd_data = M_axi_rvalid & M_axi_rready;
    always @(posedge clk) begin : proc_r_fifo_0_wr_en
    	if(~reset_n | Start) begin
    		r_fifo_0_wr_en <= 0;
    	end else if(r_fifo_select == 3'b000 && ~fifo_0_push_done ) begin
    		r_fifo_0_wr_en <= valid_rd_data && ~fifo_0_just_last_byte;
    	end else begin
    		r_fifo_0_wr_en <= 0;
    	end
    end

    always @(posedge clk) begin : proc_r_fifo_1_wr_en
    	if(~reset_n | Start) begin
    		r_fifo_1_wr_en <= 0;
    	end else if(r_fifo_select == 3'b001 && ~fifo_1_push_done ) begin
    		r_fifo_1_wr_en <= valid_rd_data && ~fifo_1_just_last_byte;
    	end else begin
    		r_fifo_1_wr_en <= 0;
    	end
    end

    always @(posedge clk) begin : proc_r_fifo_2_wr_en
    	if(~reset_n | Start) begin
    		r_fifo_2_wr_en <= 0;
    	end else if(r_fifo_select == 3'b010 && ~fifo_2_push_done ) begin
    		r_fifo_2_wr_en <= valid_rd_data &&  ~fifo_2_just_last_byte;
    	end else begin
    		r_fifo_2_wr_en <= 0;
    	end
    end


    always @(posedge clk) begin : proc_r_fifo_3_wr_en
        if(~reset_n | Start) begin
            r_fifo_3_wr_en <= 0;
        end else if(r_fifo_select == 3'b011 && ~fifo_3_push_done ) begin
            r_fifo_3_wr_en <= valid_rd_data &&  ~fifo_3_just_last_byte;
        end else begin
            r_fifo_3_wr_en <= 0;
        end
    end

    always @(posedge clk) begin : proc_r_fifo_4_wr_en
        if(~reset_n | Start) begin
            r_fifo_4_wr_en <= 0;
        end else if(r_fifo_select == 3'b100 && ~fifo_4_push_done ) begin
            r_fifo_4_wr_en <= valid_rd_data && ~fifo_4_just_last_byte;
        end else begin
            r_fifo_4_wr_en <= 0;
        end
    end


    // logic for M_axi_arlen calculation
    // will reduce burst size if it reaches end 
    // always @(posedge clk) begin : proc_r_fifo_*_burst_len
    // 	if(~reset_n) begin
    // 		r_fifo_0_burst_len <= 0;
    // 		r_fifo_1_burst_len <= 0;
    // 		r_fifo_2_burst_len <= 0;
    // 	end else begin
    // 		r_fifo_0_burst_len <= (((kernel_0_end_addr - r_kernel_0_addr) >= C_S_AXI_BURST_LEN) ? C_S_AXI_BURST_LEN - 1 : (kernel_0_end_addr - r_kernel_0_addr));
    // 		r_fifo_1_burst_len <= (((kernel_1_end_addr - r_kernel_1_addr) >= C_S_AXI_BURST_LEN) ? C_S_AXI_BURST_LEN - 1 : (kernel_1_end_addr - r_kernel_1_addr));
    // 		r_fifo_2_burst_len <= (((kernel_2_end_addr - r_kernel_2_addr) >= C_S_AXI_BURST_LEN) ? C_S_AXI_BURST_LEN - 1 : (kernel_2_end_addr - r_kernel_2_addr));
    // 	end
    // end

    // always @(posedge clk) begin : proc_r_M_axi_arlen
    // 	if(~reset_n) begin
    // 		r_M_axi_arlen <= 0;
    // 	end else begin
    // 		case(r_fifo_select)
    // 		 	2'b00 : r_M_axi_arlen <= r_fifo_0_burst_len;
    // 		 	2'b01 : r_M_axi_arlen <= r_fifo_1_burst_len;
    // 		 	2'b10 : r_M_axi_arlen <= r_fifo_2_burst_len;
    // 		 	default : r_M_axi_arlen <= r_fifo_0_burst_len;
    // 		endcase // r_fifo_select
    // 	end
    // end



	//fifo interface
	assign kernel_0_fifo_wr_data = r_fifo_wdata;
	assign kernel_0_fifo_wr_en = r_fifo_0_wr_en;

	assign kernel_1_fifo_wr_data = r_fifo_wdata;
	assign kernel_1_fifo_wr_en = r_fifo_1_wr_en;

	assign kernel_2_fifo_wr_data = r_fifo_wdata;
	assign kernel_2_fifo_wr_en = r_fifo_2_wr_en;

    assign kernel_3_fifo_wr_data = r_fifo_wdata;
    assign kernel_3_fifo_wr_en = r_fifo_3_wr_en;

    assign kernel_4_fifo_wr_data = r_fifo_wdata;
    assign kernel_4_fifo_wr_en = r_fifo_4_wr_en;



 	//********************************************************************************
	//********** AXI Read **********************************************************
	//********************************************************************************


	reg[3:0] axi_read_FSM;

	always@(posedge clk) begin
		if(~reset_n | Start | ~r_Start) begin
			axi_read_FSM <= 0;
		end else begin
			case(axi_read_FSM) 
                4'b0000 : if(r_fifo_select == r_fifo_select_p1) axi_read_FSM <= 4'b0001;
				4'b0001 : if(M_axi_arvalid && M_axi_arready) axi_read_FSM <= 4'b0010;
				4'b0010 : if(M_axi_rready & M_axi_rvalid & M_axi_rlast) axi_read_FSM <= 4'b0011;
				// delaying state machine to synchronise with  fifo select
				4'b0011 : axi_read_FSM <= 4'b0100;
				4'b0100 : axi_read_FSM <= 4'b0000;
				default : axi_read_FSM <= 4'b0000;
			endcase
		end
	end

	reg r_M_axi_rready;
	always @(posedge clk) begin
		if( ~reset_n || M_axi_rready & M_axi_rvalid & M_axi_rlast)
       		r_M_axi_rready <= 0;
       	else if(M_axi_rvalid)begin
       		r_M_axi_rready <= 1;
       	end
    end
    assign M_axi_rready = r_M_axi_rready;

    reg r_M_axi_arvalid;
    always @(posedge clk) begin
        if(~reset_n || (M_axi_arvalid && M_axi_arready)) begin
            r_M_axi_arvalid <= 0;
        end else if(axi_read_FSM == 4'b0001 & ~r_M_axi_arvalid) begin
            r_M_axi_arvalid <= 1;
        end
    end
    assign M_axi_arvalid = r_M_axi_arvalid;



endmodule // kernel_loader