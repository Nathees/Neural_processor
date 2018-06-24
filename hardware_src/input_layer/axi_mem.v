
`timescale 1 ns / 1 ps

	module axi_mem #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of ID for for write address, write data, read address and read data
		parameter integer C_S_AXI_ID_WIDTH	= 1,
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 10,
		// Width of optional user defined signal in write address channel
		parameter integer C_S_AXI_AWUSER_WIDTH	= 0,
		// Width of optional user defined signal in read address channel
		parameter integer C_S_AXI_ARUSER_WIDTH	= 0,
		// Width of optional user defined signal in write data channel
		parameter integer C_S_AXI_WUSER_WIDTH	= 0,
		// Width of optional user defined signal in read data channel
		parameter integer C_S_AXI_RUSER_WIDTH	= 0,
		// Width of optional user defined signal in write response channel
		parameter integer C_S_AXI_BUSER_WIDTH	= 0
	)
	(
		// Users to add ports here
		// general layer parameters and start signal
		output wire Start,

		output wire max_pool_en,

		output wire expand_en,

		output wire in_layer_ddr3_data_rdy,

		output wire [15:0] No_of_input_layers,

		output wire [15:0] No_of_rows,

		output wire [15:0] No_of_cols,

		// processing module specific parameters
		output  wire 			[15:0] 									No_of_expand_layers,
		output  wire 			[15:0] 									No_of_squeeze_layers,

		// input layer specific parameter
		output  wire 			[31:0]									input_layer_axi_start_addr,
		output  wire 													larger_block_en,
		output  wire 			[15:0]									allocated_space_per_row,
		output  wire 													stride2en,
		output  wire 			[7:0]									burst_per_row,
		output  wire 			[3:0]									read_burst_len,

		// parameters for kernel loader

		output 					[4:0]									skip_en,

		output  wire 			[31:0]									kernel_0_start_addr,
		output  wire 			[31:0]									kernel_0_end_addr,
		output															kernel_0_wrap_en,

		output  wire 			[31:0]									kernel_1_start_addr,
		output  wire 			[31:0]									kernel_1_end_addr,
		output															kernel_1_wrap_en,

		output  wire 			[31:0]									kernel_2_start_addr,
		output  wire 			[31:0]									kernel_2_end_addr,
		output															kernel_2_wrap_en,

		output  wire 			[31:0]									kernel_3_start_addr,
		output  wire 			[31:0]									kernel_3_end_addr,
		output															kernel_3_wrap_en,

		output  wire 			[31:0]									kernel_4_start_addr,
		output  wire 			[31:0]									kernel_4_end_addr,
		output															kernel_4_wrap_en,


		// parameters for output layer

		output  wire 			[15:0] 									No_of_output_layers,
		output  wire 			[15:0] 									No_of_output_rows,
		output  wire 			[15:0] 									No_of_output_cols,
		output  wire 			[31:0] 									output_layer_axi_address,

		output  wire 			 										out_larger_block_en,  				
		output  wire 			[15:0] 									out_allocated_space_per_row,  		
		output  wire 			[7:0] 									out_burst_per_row,  				
		output  wire 			[3:0] 									out_read_burst_len,  				


		// Debug interface
		input   wire            [31:0] 									stream_in,
		output   wire                                            		stream_in_rd_en,
		input 	wire            [7:0]    								stream_in_count,

		// Parameters for FIRE Layer
		output 	reg 													squ_repeat_en_o,
		output 	reg 													avg_en_o,
		output 	reg 			[6:0]  									one_exp_ker_addr_limit_o, 
		output 	reg 			[5:0]  									exp_ker_depth_o, 	  	
		output 	reg 			[6:0] 									layer_dimension_o, 		
		output 	reg 			[11:0] 									tot_exp1_ker_addr_limit_o, 
		output 	reg 			[10:0] 									one_exp_layer_addr_limit_o, 
		output 	reg 			[5:0]  									no_of_exp_kernals_o, 	
		output 	reg 			[7:0]  									exp_123_addr_space_o, 	
		output 	reg 			[7:0]  									exp_12_addr_space_o, 	
		output 	reg 			[7:0]  									exp_1_addr_space_o, 		
		output 	reg 			[10:0] 									exp_tot_addr_space_o, 	
		output 	reg 			[9:0]  									max_tot_addr_space_o, 	
		output 	reg 			[11:0] 									tot_squ_ker_addr_limit_o, 
		output 	reg 			[5:0]  									one_squ_ker_addr_limit_o, 
		output 	reg 			[15:0] 									tot_repeat_squ_kernals_o,
		output 	reg 			[5:0]  									squ_kernals_63_o, 		
		output 	reg 			[8:0]  									tot_squ_addr_limit_o, 	
		output 	reg 			[9:0]  									no_of_squ_kernals_o, 	
		output 	reg 			[8:0]  									squ_3x3_ker_depth_o, 	
		output 	reg 			[6:0]  									squ_layer_dimension_o,
		

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write Address ID
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
		// Write address
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		input wire [7 : 0] S_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		input wire [2 : 0] S_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		input wire [1 : 0] S_AXI_AWBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		input wire  S_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		input wire [3 : 0] S_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each
    // write transaction.
		input wire [3 : 0] S_AXI_AWQOS,
		// Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
		input wire [3 : 0] S_AXI_AWREGION,
		// Optional User-defined signal in the write address channel.
	//	input wire [C_S_AXI_AWUSER_WIDTH-1 : 0] S_AXI_AWUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid write address and
    // control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
		output wire  S_AXI_AWREADY,
		// Write Data
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write last. This signal indicates the last transfer
    // in a write burst.
		input wire  S_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
	//	input wire [C_S_AXI_WUSER_WIDTH-1 : 0] S_AXI_WUSER,
		// Write valid. This signal indicates that valid write
    // data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    // can accept the write data.
		output wire  S_AXI_WREADY,
		// Response ID tag. This signal is the ID tag of the
    // write response.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
		// Write response. This signal indicates the status
    // of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Optional User-defined signal in the write response channel.
	//	output wire [C_S_AXI_BUSER_WIDTH-1 : 0] S_AXI_BUSER,
		// Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    // can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address ID. This signal is the identification
    // tag for the read address group of signals.
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
		// Read address. This signal indicates the initial
    // address of a read burst transaction.
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		input wire [7 : 0] S_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		input wire [2 : 0] S_AXI_ARSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		input wire [1 : 0] S_AXI_ARBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		input wire  S_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		input wire [3 : 0] S_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each
    // read transaction.
		input wire [3 : 0] S_AXI_ARQOS,
		// Region identifier. Permits a single physical interface
    // on a slave to be used for multiple logical interfaces.
		input wire [3 : 0] S_AXI_ARREGION,
		// Optional User-defined signal in the read address channel.
	//	input wire [C_S_AXI_ARUSER_WIDTH-1 : 0] S_AXI_ARUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid read address and
    // control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
		output wire  S_AXI_ARREADY,
		// Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
		// Read Data
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of
    // the read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read last. This signal indicates the last transfer
    // in a read burst.
		output wire  S_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
	//	output wire [C_S_AXI_RUSER_WIDTH-1 : 0] S_AXI_RUSER,
		// Read valid. This signal indicates that the channel
    // is signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    // accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4FULL signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg [C_S_AXI_BUSER_WIDTH-1 : 0] 	axi_buser;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rlast;
	reg [C_S_AXI_RUSER_WIDTH-1 : 0] 	axi_ruser;
	reg  	axi_rvalid;
	// aw_wrap_en determines wrap boundary and enables wrapping
	wire aw_wrap_en;
	// ar_wrap_en determines wrap boundary and enables wrapping
	wire ar_wrap_en;
	// aw_wrap_size is the size of the write transfer, the
	// write address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  aw_wrap_size ; 
	// ar_wrap_size is the size of the read transfer, the
	// read address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  ar_wrap_size ; 
	// The axi_awv_awr_flag flag marks the presence of write address valid
	reg axi_awv_awr_flag;
	//The axi_arv_arr_flag flag marks the presence of read address valid
	reg axi_arv_arr_flag; 
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	reg [7:0] axi_awlen_cntr;
	//The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
	reg [7:0] axi_arlen_cntr;
	reg [1:0] axi_arburst;
	reg [1:0] axi_awburst;
	reg [7:0] axi_arlen;
	reg [7:0] axi_awlen;
	//local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	//ADDR_LSB is used for addressing 32/64 bit registers/memories
	//ADDR_LSB = 2 for 32 bits (n downto 2) 
	//ADDR_LSB = 3 for 42 bits (n downto 3)

	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;
	localparam integer OPT_MEM_ADDR_BITS = 7;
	localparam integer USER_NUM_MEM = 1;
	//----------------------------------------------
	//-- Signals for user logic memory space example
	//------------------------------------------------
	wire [OPT_MEM_ADDR_BITS:0] mem_address;
	wire [USER_NUM_MEM-1:0] mem_select;
	reg [C_S_AXI_DATA_WIDTH-1:0] mem_data_out[0 : USER_NUM_MEM-1];

	genvar i;
	genvar j;
	genvar mem_byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BUSER	= axi_buser;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RLAST	= axi_rlast;
	assign S_AXI_RUSER	= axi_ruser;
	assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_BID = S_AXI_AWID;
	assign S_AXI_RID = S_AXI_ARID;
	assign  aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign  ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;
	assign S_AXI_BUSER = 0;

	// Implement axi_awready generation

	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      axi_awv_awr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          // slave is ready to accept an address and
	          // associated control signals
	          axi_awready <= 1'b1;
	          axi_awv_awr_flag  <= 1'b1; 
	          // used for generation of bresp() and bvalid
	        end
	      else if (S_AXI_WLAST && axi_wready)          
	      // preparing to accept next address after current write burst tx completion
	        begin
	          axi_awv_awr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_awaddr latching

	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	      axi_awlen_cntr <= 0;
	      axi_awburst <= 0;
	      axi_awlen <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	        begin
	          // address latching 
	          axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];  
	           axi_awburst <= S_AXI_AWBURST; 
	           axi_awlen <= S_AXI_AWLEN;     
	          // start address of transfer
	          axi_awlen_cntr <= 0;
	        end   
	      else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)        
	        begin

	          axi_awlen_cntr <= axi_awlen_cntr + 1;

	          case (axi_awburst)
	            2'b00: // fixed burst
	            // The write address for all the beats in the transaction are fixed
	              begin
	                axi_awaddr <= axi_awaddr;          
	                //for awsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The write address for all the beats in the transaction are increments by awsize
	              begin
	                axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //awaddr aligned to 4 byte boundary
	                axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The write address wraps when the address reaches wrap boundary 
	              if (aw_wrap_en)
	                begin
	                  axi_awaddr <= (axi_awaddr - aw_wrap_size); 
	                end
	              else 
	                begin
	                  axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                  axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //for awsize = 4 bytes (010)
	              end
	          endcase              
	        end
	    end 
	end       
	// Implement axi_wready generation

	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if ( ~axi_wready && S_AXI_WVALID && axi_awv_awr_flag)
	        begin
	          // slave can accept the write data
	          axi_wready <= 1'b1;
	        end
	      //else if (~axi_awv_awr_flag)
	      else if (S_AXI_WLAST && axi_wready)
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       
	// Implement write response logic generation

	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid <= 0;
	      axi_bresp <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST )
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	          // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	          //check if bready is asserted while bvalid is high) 
	          //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	 end   
	// Implement axi_arready generation

	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_arv_arr_flag <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          axi_arready <= 1'b1;
	          axi_arv_arr_flag <= 1'b1;
	        end
	      else if (axi_rvalid && S_AXI_RREADY && axi_arlen_cntr == axi_arlen)
	      // preparing to accept next address after current read completion
	        begin
	          axi_arv_arr_flag  <= 1'b0;
	        end
	      else        
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       
	// Implement axi_araddr latching

	//This process is used to latch the address when both 
	//S_AXI_ARVALID and S_AXI_RVALID are valid. 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_araddr <= 0;
	      axi_arlen_cntr <= 0;
	      axi_arburst <= 0;
	      axi_arlen <= 0;
	      axi_rlast <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
	        begin
	          // address latching 
	          axi_araddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0]; 
	          axi_arburst <= S_AXI_ARBURST; 
	          axi_arlen <= S_AXI_ARLEN;     
	          // start address of transfer
	          axi_arlen_cntr <= 0;
	          axi_rlast <= 1'b0;
	        end   
	      else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)        
	        begin
	         
	          axi_arlen_cntr <= axi_arlen_cntr + 1;
	          axi_rlast <= 1'b0;
	        
	          case (axi_arburst)
	            2'b00: // fixed burst
	             // The read address for all the beats in the transaction are fixed
	              begin
	                axi_araddr       <= axi_araddr;        
	                //for arsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The read address for all the beats in the transaction are increments by awsize
	              begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The read address wraps when the address reaches wrap boundary 
	              if (ar_wrap_en) 
	                begin
	                  axi_araddr <= (axi_araddr - ar_wrap_size); 
	                end
	              else 
	                begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
	                //for arsize = 4 bytes (010)
	              end
	          endcase              
	        end
	      else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag )   
	        begin
	          axi_rlast <= 1'b1;
	        end          
	      else if (S_AXI_RREADY)   
	        begin
	          axi_rlast <= 1'b0;
	        end          
	    end 
	end       
	// Implement axi_arvalid generation

	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arv_arr_flag && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; 
	          // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end            
	    end
	end    
	// ------------------------------------------
	// -- Example code to access user logic memory region
	// ------------------------------------------

	generate
	  if (USER_NUM_MEM >= 1)
	    begin
	      assign mem_select  = 1;
	      assign mem_address = (axi_arv_arr_flag? axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:(axi_awv_awr_flag? axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:0));
	    end
	endgenerate
	     
	// implement Block RAM(s)
	// generate 
	//   for(i=0; i<= USER_NUM_MEM-1; i=i+1)
	//     begin:BRAM_GEN
	//       wire mem_rden;
	//       wire mem_wren;
	
	//       assign mem_wren = axi_wready && S_AXI_WVALID ;
	
	//       assign mem_rden = axi_arv_arr_flag ; //& ~axi_rvalid
	     
	//       for(mem_byte_index=0; mem_byte_index<= (C_S_AXI_DATA_WIDTH/8-1); mem_byte_index=mem_byte_index+1)
	//       begin:BYTE_BRAM_GEN
	//         wire [8-1:0] data_in ;
	//         wire [8-1:0] data_out;
	//         reg  [8-1:0] byte_ram [0 : 255];
	//         integer  j;
	     
	//         //assigning 8 bit data
	//         assign data_in  = S_AXI_WDATA[(mem_byte_index*8+7) -: 8];
	//         assign data_out = byte_ram[mem_address];
	     
	//         always @( posedge S_AXI_ACLK )
	//         begin
	//           if (mem_wren && S_AXI_WSTRB[mem_byte_index])
	//             begin
	//               byte_ram[mem_address] <= data_in;
	//             end   
	//         end    
	      
	//         always @( posedge S_AXI_ACLK )
	//         begin
	//           if (mem_rden)
	//             begin
	//               mem_data_out[i][(mem_byte_index*8+7) -: 8] <= data_out;
	//             end   
	//         end    
	               
	//     end
	//   end       
	// endgenerate
	//Output register or memory read data

	always @(posedge S_AXI_ACLK)
	begin
	      // Read address mux
	      axi_rdata <= stream_in; //mem_data_out[0];
  
	end    

	// Add user logic here

	//------------------------------------------------------------------------------------
	//-------------------- Logic for getting parameters-----------------------------------
	//------------------------------------------------------------------------------------

	// following parameter will be fetched from address
	// 	  ADDR                   PARAMETER

			// common paprameters and input layer
	// 0x00000000 ------- 		 (byte0[0] == Start processing), (byte0[1] = max_pool_en), ((byte0[2] = expand_en), ((byte0[3] = in_layer_ddr3_data_rdy), (byte1 = layer_ID) , (byte2, byte3 = No_of_input_layers)
	// 0x00000004 -------        (byte1, byte0 = No_of_rows), (byte3, byte2 = no_of_cols)
	// 0x00000008 -------        (byte0, byte1 == No_of_expand_layers), (byte2, byte3 = No_of_squeeze_layers)
	// 0x0000000c -------        start of input layer axi address
	// 0x00000010 -------        (byte01, byte0 = allocated_space_per_row), (byte2 = burst_per_row),  (byte3[7:4] = read_burst_len, byte3[25:24] = stride2en, larger_block_en)
	 

			//kernel loader parameter
	// 0x00000020 -------        kernel0 settings
	// 0x00000024 -------        kernel0 - AXI address start
	// 0x00000028 -------        kernel0 - AXI end address 

	// 0x00000030 -------        kernel1 settings 
	// 0x00000034 -------        kernel1 - AXI address start
	// 0x00000038 -------        kernel1 - AXI end address

	// 0x00000040 -------        kernel2 settings 
	// 0x00000044 -------        kernel2 - AXI address start
	// 0x00000048 -------        kernel2 - AXI end address

	// 0x00000050 -------        kernel3 settings 
	// 0x00000054 -------        kernel3 - AXI address start
	// 0x00000058 -------        kernel3 - AXI end address

	// 0x00000060 -------        kernel4 settings 
	// 0x00000064 -------        kernel4 - AXI address start
	// 0x00000068 -------        kernel4 - AXI end address


			// output layer parameters
	// 0x00000080 -------        (byte0, byte1 = No of output layers ) 
	// 0x00000084 -------        (byte0, byte1 = No_of_rows, byte2, byte3 = no_of_cols)
	// 0x00000088 -------        start of output layer axi address
	// 0x0000008c -------        (byte01, byte0 = out_allocated_space_per_row), (byte2 = out_burst_per_row),  (byte3[31:28] = write_burst_len, byte3[24:24] = larger_block_en)

	/*
		input 															start_i;
		input 															exp_1x1_en_i;
		input 															max_en_i;
		input 															squ_repeat_en_i;
		input 															avg_en_i;
		Configurations :- EXPAND KERNAL CONTROLLER
		one_exp_ker_addr_limit_i 	:- [6:0]  	[NO of expand kernals / 4]
		exp_ker_depth_i 	  		:- [5:0] 	[depth - 1]
		layer_dimension_i 			:- [6:0]	[dimnision -1]
		tot_exp1_ker_addr_limit_i 	:- [11:0] 	[(NO of expand kernals * depth) / 4 ] - 1
		one_exp_layer_addr_limit_i 	:- [10:0] 	[(dimension * expand kernals / 4)] - 1
		no_of_exp_kernals_i 		:- [5:0] 	[2 * NO of expand kernals / 8 - 1]
		exp_123_addr_space_i 		:- [7:0] 	[expand kernal / 4 * 3] - 1 	
		exp_12_addr_space_i 		:- [7:0] 	[expand kernal / 4 * 2]
		exp_1_addr_space_i 			:- [7:0] 	[expand kernal / 4 * 1] - 1
		exp_tot_addr_space_i 		:- [10:0] 	[expand layer dim * expand kernal / 4] - 2
		max_tot_addr_space_i 		:- [9:0] 	[max layer dim * expand kernal / 4] - 2
		tot_squ_ker_addr_limit_i 	:- [11:0] 	[(NO of squeeze kernals * depth / 8 ] - 1
		one_squ_ker_addr_limit_i 	:- [5:0] 	[(depth / 2) / 8]
		tot_repeat_squ_kernals_i	:- [15:0] 	[No of squeeze kernal * layer height]
		squ_kernals_63_i 			:- [5:0] 	[No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
		tot_squ_addr_limit_i 		:- [8:0] 	[(dimension * depth / 2) / 8] - 1
		no_of_squ_kernals_i 		:- [9:0] 	[No of squeeze kernal - 1]
		squ_3x3_ker_depth_i 		:- [8:0] 	[squeeze 3x3 depth]
		squ_layer_dimension_i 		:- [6:0] 	[Squeeze layer dimension - 1] // After max pool

		0x00000100 		-	{byte 0 :- one_exp_ker_addr_limit_i; byte 1:- exp_ker_depth_i; byte 2:- layer_dimension_i}
		0x00000104 		-	{byte 0, byte 1 :- tot_exp1_ker_addr_limit_i; byte 2, byte 3 :- one_exp_layer_addr_limit_i}
		0x00000108 		-	{byte 0 :- no_of_exp_kernals_i; byte 1:- exp_123_addr_space_i; byte 2:- exp_12_addr_space_i; byte 3:- exp_1_addr_space_i}
		0x0000010C 		-	{byte 0,1 :- exp_tot_addr_space_i; byte 2,3:- max_tot_addr_space_i}
		0x00000110 		-	{byte 0,1 :- tot_squ_ker_addr_limit_i; byte 2:- one_squ_ker_addr_limit_i}
		0x00000114 		-	{byte 0,1 :- tot_repeat_squ_kernals_i; byte 2:- squ_kernals_63_i;}
		0x00000118 		-	{byte 0,1 :- tot_squ_addr_limit_i; byte 2,3:- no_of_squ_kernals_i;}
		0x0000011C 		-	{byte 0,1 :- squ_3x3_ker_depth_i; byte 2:- squ_layer_dimension_i;}
	*/

	// Common parameters
		reg r_Start;
		reg [7:0] r_layer_ID;
		reg r_max_pool_en;
		reg r_expand_en;
		reg r_in_layer_ddr3_data_rdy;
		reg [15:0] r_No_of_input_layers;
		reg [15:0] r_No_of_input_layer_rows;
		reg [15:0] r_no_of_input_layer_cols;


		reg [15:0] r_No_of_expand_layers;
		reg [15:0] r_No_of_squeeze_layers;

	// input layer specific parameters
		reg [31:0] r_input_layer_axi_address;
		reg r_larger_block_en;
		reg r_stride2en;
		reg [15:0] r_allocated_space_per_row;
		reg [7:0] r_burst_per_row;
		reg [3:0] r_read_burst_len;

	// parameters for kerel loader
		reg [31:0] r_kernel0_settings;
		reg [31:0] r_kernel0_axi_start_addr;
		reg [31:0] r_kernel0_axi_end_addr;

		reg [31:0] r_kernel1_settings;
		reg [31:0] r_kernel1_axi_start_addr;
		reg [31:0] r_kernel1_axi_end_addr;

		reg [31:0] r_kernel2_settings;
		reg [31:0] r_kernel2_axi_start_addr;
		reg [31:0] r_kernel2_axi_end_addr;

		reg [31:0] r_kernel3_settings;
		reg [31:0] r_kernel3_axi_start_addr;
		reg [31:0] r_kernel3_axi_end_addr;

		reg [31:0] r_kernel4_settings;
		reg [31:0] r_kernel4_axi_start_addr;
		reg [31:0] r_kernel4_axi_end_addr;

	// parameters for output layers
		reg [15:0] r_No_of_output_layers;
		reg [15:0] r_No_of_output_rows;
		reg [15:0] r_No_of_output_cols;
		reg [31:0] r_output_layer_axi_address;

		reg r_out_larger_block_en;
		reg [15:0] r_out_allocated_space_per_row;
		reg [7:0] r_out_burst_per_row;
		reg [3:0] r_out_read_burst_len;



		// start signal
		assign mem_wren = axi_wready && S_AXI_WVALID ;
		always @(posedge S_AXI_ACLK) begin : proc_addr0
			if(~S_AXI_ARESETN) begin
				r_Start 					<= 0;
				r_layer_ID 					<= 0;
				r_max_pool_en 				<= 0;
				r_expand_en 				<= 0;
				r_No_of_input_layers 		<= 0;
				r_in_layer_ddr3_data_rdy 	<= 0;
				squ_repeat_en_o 			<= 0;
				avg_en_o 					<= 0;
			end else if(mem_wren && mem_address == 0)begin
				r_Start 					<= S_AXI_WDATA[0:0];
				r_layer_ID 					<= S_AXI_WDATA[15:8];
				r_max_pool_en 				<= S_AXI_WDATA[1:1];
				r_expand_en 				<= S_AXI_WDATA[2:2];
				r_No_of_input_layers 		<= S_AXI_WDATA[31:16];
				r_in_layer_ddr3_data_rdy 	<= S_AXI_WDATA[3:3];
				squ_repeat_en_o 			<= S_AXI_WDATA[4:4];
				avg_en_o 					<= S_AXI_WDATA[5:5];
			end else begin
				r_Start 					<= 0;
				r_max_pool_en 				<= 0;
				r_expand_en 				<= 0;
				squ_repeat_en_o 			<= 0;
				avg_en_o 					<= 0;
			end
		end

		always @(posedge S_AXI_ACLK) begin : proc_row_cols
			if(~S_AXI_ARESETN) begin
				r_No_of_input_layer_rows <= 0;
				r_no_of_input_layer_cols <= 0;
			end else if(mem_wren && mem_address == 1) begin
				r_No_of_input_layer_rows <= S_AXI_WDATA[15:0];
				r_no_of_input_layer_cols <= S_AXI_WDATA[31:16];
			end
		end

		always @(posedge S_AXI_ACLK) begin : proc_squezze_exp
			if(~S_AXI_ARESETN) begin
				r_No_of_expand_layers <= 0;
				r_No_of_squeeze_layers <= 0;
			end else if(mem_wren && mem_address == 2) begin
				r_No_of_expand_layers <= S_AXI_WDATA[15:0];
				r_No_of_squeeze_layers <= S_AXI_WDATA[31:16];
			end
		end


		// input layer parameters
		always @(posedge S_AXI_ACLK) begin : proc_r_input_layer_axi_address
			if(~S_AXI_ARESETN) begin
				r_input_layer_axi_address <= 0;
			end else if(mem_wren && mem_address == 3) begin
				r_input_layer_axi_address <= S_AXI_WDATA;
			end
		end


		always @(posedge S_AXI_ACLK) begin : proc_mem_address_4
			if(~S_AXI_ARESETN) begin
				r_larger_block_en <= 0;
				r_stride2en <= 0;
				r_allocated_space_per_row <= 0;
				r_burst_per_row <= 0;
				r_read_burst_len <= 0;
			end else if(mem_wren && mem_address == 4)begin
				r_larger_block_en <= S_AXI_WDATA[24:24];
				r_stride2en <= S_AXI_WDATA[25:25];
				r_allocated_space_per_row <= S_AXI_WDATA[15:0];
				r_burst_per_row <= S_AXI_WDATA[23:16];
				r_read_burst_len <= S_AXI_WDATA[31:28];
			end
		end



		// Kernel loader parameters
		// kerel 0
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel0_settings
			if(~S_AXI_ARESETN) begin
				r_kernel0_settings <= 0;
			end else if(mem_wren && mem_address == 8) begin
				r_kernel0_settings <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel0_axi_start_addr
			if(~S_AXI_ARESETN) begin
				r_kernel0_axi_start_addr <= 0;
			end else if(mem_wren && mem_address == 9) begin
				r_kernel0_axi_start_addr <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel0_axi_end_addr
			if(~S_AXI_ARESETN) begin
				r_kernel0_axi_end_addr <= 0;
			end else if(mem_wren && mem_address == 10) begin
				r_kernel0_axi_end_addr <= S_AXI_WDATA;
			end
		end
		//-------------------------------------------------------------

		// kernel 1
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel1_settings
			if(~S_AXI_ARESETN) begin
				r_kernel1_settings <= 0;
			end else if(mem_wren && mem_address == 12) begin
				r_kernel1_settings <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel1_axi_start_addr
			if(~S_AXI_ARESETN) begin
				r_kernel1_axi_start_addr <= 0;
			end else if(mem_wren && mem_address == 13) begin
				r_kernel1_axi_start_addr <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel1_axi_end_addr
			if(~S_AXI_ARESETN) begin
				r_kernel1_axi_end_addr <= 0;
			end else if(mem_wren && mem_address == 14) begin
				r_kernel1_axi_end_addr <= S_AXI_WDATA;
			end
		end
		//--------------------------------------------------------------

		// kernel 2
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel2_settings
			if(~S_AXI_ARESETN) begin
				r_kernel2_settings <= 0;
			end else if(mem_wren && mem_address == 16) begin
				r_kernel2_settings <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel2_axi_start_addr
			if(~S_AXI_ARESETN) begin
				r_kernel2_axi_start_addr <= 0;
			end else if(mem_wren && mem_address == 17) begin
				r_kernel2_axi_start_addr <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel2_axi_end_addr
			if(~S_AXI_ARESETN) begin
				r_kernel2_axi_end_addr <= 0;
			end else if(mem_wren && mem_address == 18) begin
				r_kernel2_axi_end_addr <= S_AXI_WDATA;
			end
		end
		//-------------------------------------------------------------

		// kernel 3
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel3_settings
			if(~S_AXI_ARESETN) begin
				r_kernel3_settings <= 0;
			end else if(mem_wren && mem_address == 20) begin
				r_kernel3_settings <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel3_axi_start_addr
			if(~S_AXI_ARESETN) begin
				r_kernel3_axi_start_addr <= 0;
			end else if(mem_wren && mem_address == 21) begin
				r_kernel3_axi_start_addr <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel3_axi_end_addr
			if(~S_AXI_ARESETN) begin
				r_kernel3_axi_end_addr <= 0;
			end else if(mem_wren && mem_address == 22) begin
				r_kernel3_axi_end_addr <= S_AXI_WDATA;
			end
		end
		//-------------------------------------------------------------

		// kernel 4
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel4_settings
			if(~S_AXI_ARESETN) begin
				r_kernel4_settings <= 0;
			end else if(mem_wren && mem_address == 24) begin
				r_kernel4_settings <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel4_axi_start_addr
			if(~S_AXI_ARESETN) begin
				r_kernel4_axi_start_addr <= 0;
			end else if(mem_wren && mem_address == 25) begin
				r_kernel4_axi_start_addr <= S_AXI_WDATA;
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_kernel4_axi_end_addr
			if(~S_AXI_ARESETN) begin
				r_kernel4_axi_end_addr <= 0;
			end else if(mem_wren && mem_address == 26) begin
				r_kernel4_axi_end_addr <= S_AXI_WDATA;
			end
		end
		//-------------------------------------------------------------

		// output layer parameters
		always @(posedge S_AXI_ACLK) begin : proc_r_No_of_output_layers
			if(~S_AXI_ARESETN) begin
				r_No_of_output_layers <= 0;
			end else if(mem_wren && mem_address == 32) begin
				r_No_of_output_layers <= S_AXI_WDATA[15:0];
			end
		end
		always @(posedge S_AXI_ACLK) begin : proc_r_No_of_output_rows
			if(~S_AXI_ARESETN) begin
				r_No_of_output_rows <= 0;
				r_No_of_output_cols <= 0;
			end else if(mem_wren && mem_address == 33) begin
				r_No_of_output_rows <= S_AXI_WDATA[15:0];
				r_No_of_output_cols <= S_AXI_WDATA[31:16];
			end
		end

		always @(posedge S_AXI_ACLK) begin : proc_r_output_layer_axi_address
			if(~S_AXI_ARESETN) begin
				r_output_layer_axi_address <= 0;
			end else if(mem_wren && mem_address == 34) begin
				r_output_layer_axi_address <= S_AXI_WDATA;
			end
		end

		always @(posedge S_AXI_ACLK) begin : proc_mem_address35
			if(~S_AXI_ARESETN) begin
				r_out_larger_block_en <= 0;
				r_out_allocated_space_per_row <= 0;
				r_out_burst_per_row <= 0;
				r_out_read_burst_len <= 0;
			end else if(mem_wren && mem_address == 35) begin
				r_out_larger_block_en <= S_AXI_WDATA[24:24];
				r_out_allocated_space_per_row <= S_AXI_WDATA[15:0];
				r_out_burst_per_row <= S_AXI_WDATA[23:16];
				r_out_read_burst_len <= S_AXI_WDATA[31:28];
			end
		end


	// FIRE Layer COnfiguration
	always @(posedge S_AXI_ACLK) begin : proc_mem_address36
		if(~S_AXI_ARESETN) begin
			one_exp_ker_addr_limit_o	<= 0;
			exp_ker_depth_o				<= 0;
			layer_dimension_o			<= 0;
		end else if(mem_wren && mem_address == 36) begin
			one_exp_ker_addr_limit_o	<= S_AXI_WDATA[06:00];
			exp_ker_depth_o				<= S_AXI_WDATA[13:08];
			layer_dimension_o			<= S_AXI_WDATA[22:16];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address37
		if(~S_AXI_ARESETN) begin
			tot_exp1_ker_addr_limit_o 	<= 0;
			one_exp_layer_addr_limit_o 	<= 0;
		end else if(mem_wren && mem_address == 37) begin
			tot_exp1_ker_addr_limit_o	<= S_AXI_WDATA[11:00];
			one_exp_layer_addr_limit_o	<= S_AXI_WDATA[26:16];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address38
		if(~S_AXI_ARESETN) begin
			no_of_exp_kernals_o 		<= 0;
			exp_123_addr_space_o 		<= 0;
			exp_12_addr_space_o 		<= 0;
			exp_1_addr_space_o 			<= 0;
		end else if(mem_wren && mem_address == 38) begin
			no_of_exp_kernals_o 		<= S_AXI_WDATA[05:00];
			exp_123_addr_space_o 		<= S_AXI_WDATA[15:08];
			exp_12_addr_space_o 		<= S_AXI_WDATA[23:16];
			exp_1_addr_space_o 			<= S_AXI_WDATA[31:24];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address39
		if(~S_AXI_ARESETN) begin
			exp_tot_addr_space_o 		<= 0;
			max_tot_addr_space_o 		<= 0;
		end else if(mem_wren && mem_address == 39) begin
			exp_tot_addr_space_o 		<= S_AXI_WDATA[10:0];
			max_tot_addr_space_o 		<= S_AXI_WDATA[25:16];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address40
		if(~S_AXI_ARESETN) begin
			tot_squ_ker_addr_limit_o 	<= 0;
			one_squ_ker_addr_limit_o 	<= 0;
		end else if(mem_wren && mem_address == 40) begin
			tot_squ_ker_addr_limit_o 	<=  S_AXI_WDATA[11:0];
			one_squ_ker_addr_limit_o 	<=  S_AXI_WDATA[21:16];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address41
		if(~S_AXI_ARESETN) begin
			tot_repeat_squ_kernals_o 	<= 0;
			squ_kernals_63_o 			<= 0;
		end else if(mem_wren && mem_address == 41) begin
			tot_repeat_squ_kernals_o 	<= S_AXI_WDATA[15:0];
			squ_kernals_63_o 			<= S_AXI_WDATA[21:16];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address42
		if(~S_AXI_ARESETN) begin
			tot_squ_addr_limit_o 		<= 0;
			no_of_squ_kernals_o 		<= 0;
		end else if(mem_wren && mem_address == 42) begin
			tot_squ_addr_limit_o 		<= S_AXI_WDATA[8:0];
			no_of_squ_kernals_o 		<= S_AXI_WDATA[25:16];
		end
	end
	always @(posedge S_AXI_ACLK) begin : proc_mem_address43
		if(~S_AXI_ARESETN) begin
			squ_3x3_ker_depth_o 		<= 0;
			squ_layer_dimension_o 		<= 0;
		end else if(mem_wren && mem_address == 43) begin
			squ_3x3_ker_depth_o 		<= S_AXI_WDATA[8:0];
			squ_layer_dimension_o 		<= S_AXI_WDATA[22:16];
		end
	end

		// IO interface
		// common parameters
		assign Start = r_Start;
		assign max_pool_en = r_max_pool_en;
		assign expand_en = r_expand_en;
		assign layer_ID = r_layer_ID;
		assign No_of_input_layers = r_No_of_input_layers;
		assign No_of_rows = r_No_of_input_layer_rows;
		assign No_of_cols = r_no_of_input_layer_cols;
		assign in_layer_ddr3_data_rdy = r_in_layer_ddr3_data_rdy;

		// specific parameter - input layer
		assign input_layer_axi_start_addr = r_input_layer_axi_address;
		assign larger_block_en = r_larger_block_en;
		assign allocated_space_per_row = r_allocated_space_per_row;
		assign stride2en = r_stride2en;
		assign burst_per_row = r_burst_per_row;
		assign read_burst_len = r_read_burst_len;

		// specific parameter - processing block
		assign No_of_expand_layers = r_No_of_expand_layers;
		assign No_of_squeeze_layers = r_No_of_squeeze_layers;

		// specific parameter - kernel loader
		assign skip_en = {r_kernel4_settings[1], r_kernel3_settings[1], r_kernel2_settings[1], r_kernel1_settings[1], r_kernel0_settings[1]};

		assign kernel_0_start_addr = r_kernel0_axi_start_addr ;
		assign kernel_0_end_addr =  r_kernel0_axi_end_addr;
		assign kernel_0_wrap_en =  r_kernel0_settings[0];

		assign kernel_1_start_addr =  r_kernel1_axi_start_addr;
		assign kernel_1_end_addr =  r_kernel1_axi_end_addr;
		assign kernel_1_wrap_en =  r_kernel1_settings[0];

		assign kernel_2_start_addr =  r_kernel2_axi_start_addr;
		assign kernel_2_end_addr =  r_kernel2_axi_end_addr;
		assign kernel_2_wrap_en =  r_kernel2_settings[0];

		assign kernel_3_start_addr =  r_kernel3_axi_start_addr;
		assign kernel_3_end_addr =  r_kernel3_axi_end_addr;
		assign kernel_3_wrap_en =  r_kernel3_settings[0];

		assign kernel_4_start_addr =  r_kernel4_axi_start_addr;
		assign kernel_4_end_addr =  r_kernel4_axi_end_addr;
		assign kernel_4_wrap_en =  r_kernel4_settings[0];

		// specific parameter - output layer
		assign No_of_output_layers = r_No_of_output_layers;
		assign No_of_output_rows = r_No_of_output_rows;
		assign No_of_output_cols = r_No_of_output_cols;
		assign output_layer_axi_address = r_output_layer_axi_address;

		assign out_larger_block_en = r_out_larger_block_en;
		assign out_allocated_space_per_row = r_out_allocated_space_per_row;
		assign out_burst_per_row = r_out_burst_per_row;
		assign out_read_burst_len = r_out_read_burst_len;



		// debug interface specifc parameter
		// AXI read interface will be used to
		// read from a streaming interface


		reg [31:0] r_debug_read_data;
		always @(posedge S_AXI_ACLK) begin : proc_
			if(~S_AXI_ARESETN) begin
				r_debug_read_data <= 0;
			end else if(mem_address == 0)begin
				r_debug_read_data <= stream_in_count;
			end else if(mem_address == 1) begin
				r_debug_read_data <= stream_in;
			end
		end

		assign stream_in_rd_en = axi_rvalid && S_AXI_RREADY;

	// User logic ends

	endmodule
