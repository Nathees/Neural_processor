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

module top(
	clk_i,
	rst_n_i,

	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,

	led_o
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

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// DDR3 COntrol Signals
	output wire 		[14:0] 										memory_mem_a;
	output wire 		[2:0]  										memory_mem_ba;
	output wire 		       										memory_mem_ck;
	output wire 		       										memory_mem_ck_n;
	output wire 		       										memory_mem_cke;
	output wire 		       										memory_mem_cs_n; 
	output wire 		       										memory_mem_ras_n;
	output wire 		       										memory_mem_cas_n;
	output wire 		       										memory_mem_we_n;
	output wire 		       										memory_mem_reset_n;
	inout  wire 		[31:0] 										memory_mem_dq;
	inout  wire 		[3:0]  										memory_mem_dqs;
	inout  wire 		[3:0]  										memory_mem_dqs_n;
	output wire 		       										memory_mem_odt;
	output wire 		[3:0]  										memory_mem_dm;
	input  wire 		       										memory_oct_rzqin;

	output  						[7:0] 							led_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------


	// Interrupts
	wire 				[31:0] 										hps_0_f2h_irq0_irq;

	// FPGA to HOST SDRAM0
	wire 				[31:0] 										sdram0_data_araddr;
	wire 				[3:0]  										sdram0_data_arlen;
	wire 				[7:0]  										sdram0_data_arid;
	wire 				[2:0]  										sdram0_data_arsize;
	wire 				[1:0]  										sdram0_data_arburst;
	wire 				[1:0]  										sdram0_data_arlock;
	wire 				[2:0]  										sdram0_data_arprot;
	wire 				       										sdram0_data_arvalid;
	wire 				[3:0]  										sdram0_data_arcache;

	wire 				[31:0] 										sdram0_data_awaddr;
	wire 				[3:0]  										sdram0_data_awlen;
	wire 				[7:0]  										sdram0_data_awid;
	wire 				[2:0]  										sdram0_data_awsize;
	wire 				[1:0]  										sdram0_data_awburst;
	wire 				[1:0]  										sdram0_data_awlock;
	wire 				[2:0]  										sdram0_data_awprot;
	wire 				       										sdram0_data_awvalid;
	wire 				[3:0]  										sdram0_data_awcache;
 
	wire 				[1:0]  										sdram0_data_bresp;
	wire 				[7:0]  										sdram0_data_bid;
	wire 				       										sdram0_data_bvalid;
	wire 				       										sdram0_data_bready;

	wire 				       										sdram0_data_arready;
	wire 				       										sdram0_data_awready;

	wire 				       										sdram0_data_rready;
	wire 				[63:0] 										sdram0_data_rdata;
	wire 				[1:0]  										sdram0_data_rresp;
	wire 				       										sdram0_data_rlast;
	wire 				[7:0]  										sdram0_data_rid;
	wire 				       										sdram0_data_rvalid;

	wire 				       										sdram0_data_wlast;
	wire 				       										sdram0_data_wvalid;
	wire 				[63:0] 										sdram0_data_wdata;
	wire 				[7:0]  										sdram0_data_wstrb;
	wire 				       										sdram0_data_wready;
	wire 				[7:0]  										sdram0_data_wid;


	// FPGA to HOST SDRAM1
	wire 				[31:0] 										sdram1_data_araddr;
	wire 				[3:0]  										sdram1_data_arlen;
	wire 				[7:0]  										sdram1_data_arid;
	wire 				[2:0]  										sdram1_data_arsize;
	wire 				[1:0]  										sdram1_data_arburst;
	wire 				[1:0]  										sdram1_data_arlock;
	wire 				[2:0]  										sdram1_data_arprot;
	wire 				       										sdram1_data_arvalid;
	wire 				[3:0]  										sdram1_data_arcache;

	wire 				[31:0] 										sdram1_data_awaddr;
	wire 				[3:0]  										sdram1_data_awlen;
	wire 				[7:0]  										sdram1_data_awid;
	wire 				[2:0]  										sdram1_data_awsize;
	wire 				[1:0]  										sdram1_data_awburst;
	wire 				[1:0]  										sdram1_data_awlock;
	wire 				[2:0]  										sdram1_data_awprot;
	wire 				       										sdram1_data_awvalid;
	wire 				[3:0]  										sdram1_data_awcache;
 
	wire 				[1:0]  										sdram1_data_bresp;
	wire 				[7:0]  										sdram1_data_bid;
	wire 				       										sdram1_data_bvalid;
	wire 				       										sdram1_data_bready;

	wire 				       										sdram1_data_arready;
	wire 				       										sdram1_data_awready;

	wire 				       										sdram1_data_rready;
	wire 				[63:0] 										sdram1_data_rdata;
	wire 				[1:0]  										sdram1_data_rresp;
	wire 				       										sdram1_data_rlast;
	wire 				[7:0]  										sdram1_data_rid;
	wire 				       										sdram1_data_rvalid;

	wire 				       										sdram1_data_wlast;
	wire 				       										sdram1_data_wvalid;
	wire 				[63:0] 										sdram1_data_wdata;
	wire 				[7:0]  										sdram1_data_wstrb;
	wire 				       										sdram1_data_wready;
	wire 				[7:0]  										sdram1_data_wid;

	// HPS to FPGA LWAXI
	wire        													hps_0_h2f_axi_master_rready;        
	wire 				[11:0] 										hps_0_h2f_lw_axi_master_awid;       
	wire 				[20:0] 										hps_0_h2f_lw_axi_master_awaddr;     
	wire 				[3:0]  										hps_0_h2f_lw_axi_master_awlen;      
	wire 				[2:0]  										hps_0_h2f_lw_axi_master_awsize;     
	wire 				[1:0]  										hps_0_h2f_lw_axi_master_awburst;    
	wire 				[1:0]  										hps_0_h2f_lw_axi_master_awlock;    
	wire 				[3:0]  										hps_0_h2f_lw_axi_master_awcache;    
	wire 				[2:0]  										hps_0_h2f_lw_axi_master_awprot;     
	wire        													hps_0_h2f_lw_axi_master_awvalid;    
	wire        													hps_0_h2f_lw_axi_master_awready;    

	wire 				[11:0] 										hps_0_h2f_lw_axi_master_wid;       
	wire 				[31:0] 										hps_0_h2f_lw_axi_master_wdata;     
	wire 				[3:0]  										hps_0_h2f_lw_axi_master_wstrb;     
	wire        													hps_0_h2f_lw_axi_master_wlast;     
	wire        													hps_0_h2f_lw_axi_master_wvalid;    
	wire        													hps_0_h2f_lw_axi_master_wready;    

	wire 				[11:0] 										hps_0_h2f_lw_axi_master_bid;       
	wire 				[1:0]  										hps_0_h2f_lw_axi_master_bresp;     
	wire        													hps_0_h2f_lw_axi_master_bvalid;    
	wire        													hps_0_h2f_lw_axi_master_bready;    

	wire 				[11:0] 										hps_0_h2f_lw_axi_master_arid;      
	wire 				[20:0] 										hps_0_h2f_lw_axi_master_araddr;    
	wire 				[3:0]  										hps_0_h2f_lw_axi_master_arlen;     
	wire 				[2:0]  										hps_0_h2f_lw_axi_master_arsize;    
	wire 				[1:0]  										hps_0_h2f_lw_axi_master_arburst;   
	wire 				[1:0]  										hps_0_h2f_lw_axi_master_arlock;    
	wire 				[3:0]  										hps_0_h2f_lw_axi_master_arcache;   
	wire 				[2:0]  										hps_0_h2f_lw_axi_master_arprot;    
	wire        													hps_0_h2f_lw_axi_master_arvalid;   
	wire        													hps_0_h2f_lw_axi_master_arready;   

	wire 				[11:0] 										hps_0_h2f_lw_axi_master_rid;       
	wire 				[31:0] 										hps_0_h2f_lw_axi_master_rdata;     
	wire 				[1:0]  										hps_0_h2f_lw_axi_master_rresp;     
	wire        													hps_0_h2f_lw_axi_master_rlast;     
	wire        													hps_0_h2f_lw_axi_master_rvalid;    
	wire        													hps_0_h2f_lw_axi_master_rready; 

	// DDR3 AXI Controller
	wire 				[7:0]  										axi_ddr3_awid;
	wire 				[31:0] 										axi_ddr3_awaddr;
	wire 				[7:0]  										axi_ddr3_awlen;
	wire 				[2:0]  										axi_ddr3_awsize;
	wire 				[1:0]  										axi_ddr3_awburst;
	wire 				[0:0]  										axi_ddr3_awlock;
	wire 				[3:0]  										axi_ddr3_awcache;
	wire 				[2:0]  										axi_ddr3_awprot;
	wire 				[3:0]  										axi_ddr3_awqos;
	wire 				       										axi_ddr3_awvalid;
	wire 				       										axi_ddr3_awready;
	
	wire 				[7:0]  										axi_ddr3_wid;
	wire 				[63:0] 										axi_ddr3_wdata;
	wire 				[7:0]  										axi_ddr3_wstrb;
	wire 				       										axi_ddr3_wlast;
	wire 				       										axi_ddr3_wvalid;
	wire 				       										axi_ddr3_wready;
	
	wire 				[7:0]  										axi_ddr3_bid;
	wire 				[1:0]  										axi_ddr3_bresp;
	wire 				       										axi_ddr3_bvalid;
	wire 				       										axi_ddr3_bready;
	
	wire 				[7:0]  										axi_ddr3_arid;
	wire 				[31:0] 										axi_ddr3_araddr;
	wire 				[7:0]  										axi_ddr3_arlen;
	wire 				[2:0]  										axi_ddr3_arsize;
	wire 				[1:0]  										axi_ddr3_arburst;
	wire 				[0:0]  										axi_ddr3_arlock;
	wire 				[3:0]  										axi_ddr3_arcache;
	wire 				[2:0]  										axi_ddr3_arprot;
	wire 				[3:0]  										axi_ddr3_arqos;
	wire 				       										axi_ddr3_arvalid;
	wire 				       										axi_ddr3_arready;
	
	wire 				[7:0]  										axi_ddr3_rid;
	wire 				[63:0] 										axi_ddr3_rdata;
	wire 				[1:0]  										axi_ddr3_rresp;
	wire 				       										axi_ddr3_rlast;
	wire 				       										axi_ddr3_rvalid;
	wire 				       										axi_ddr3_rready;


// layer configurations
	// common parameters
	wire 															w_Start;

	wire 															max_pool_en;
	wire 															expand_en;
	wire 				[15:0] 										w_No_of_input_layers;
	wire 				[15:0] 										w_No_of_rows;
	wire 				[15:0] 										w_No_of_cols;

	// processing module specific parameters
	wire 				[15:0] 										No_of_expand_layers;
	wire 				[15:0] 										No_of_squeeze_layers;

	// input layer specific parameter
	wire 				[31:0]										w_input_layer_axi_start_addr;
	wire 															w_in_layer_ddr3_data_rdy;


	wire 															w_larger_block_en;
	wire 				[9:0] 										w_allocated_space_per_row;
	wire 															w_stride2en;
	wire 				[7:0] 										w_burst_per_row;
	wire 				[3:0] 										w_read_burst_len;

	// parameters for kernel loader

	wire 				[4:0]										w_skip_en;

	wire 				[31:0]										w_kernel_0_start_addr;
	wire 				[31:0]										w_kernel_0_end_addr;
	wire															w_kernel_0_wrap_en;
	wire 				[63:0]  									w_kernel_0_fifo_wr_data;
	wire 															w_kernel_0_fifo_wr_en;
	wire 				[7:0] 										w_kernel_0_fifo_count;

	wire 				[31:0]										w_kernel_1_start_addr;
	wire 				[31:0]										w_kernel_1_end_addr;
	wire 															w_kernel_1_wrap_en;
	wire 				[63:0]  									w_kernel_1_fifo_wr_data;
	wire 															w_kernel_1_fifo_wr_en;
	wire 				[7:0] 										w_kernel_1_fifo_count;

	wire 				[31:0]										w_kernel_2_start_addr;
	wire 				[31:0]										w_kernel_2_end_addr;
	wire															w_kernel_2_wrap_en;
	wire 				[63:0]  									w_kernel_2_fifo_wr_data;
	wire 															w_kernel_2_fifo_wr_en;
	wire 				[6:0] 										w_kernel_2_fifo_count;

	wire 				[31:0]										w_kernel_3_start_addr;
	wire 				[31:0]										w_kernel_3_end_addr;
	wire 															w_kernel_3_wrap_en;
	wire 				[63:0]  									w_kernel_3_fifo_wr_data;
	wire 															w_kernel_3_fifo_wr_en;
	wire 				[7:0] 										w_kernel_3_fifo_count;

	wire 				[31:0]										w_kernel_4_start_addr;
	wire 				[31:0]										w_kernel_4_end_addr;
	wire															w_kernel_4_wrap_en;
	wire 				[63:0]  									w_kernel_4_fifo_wr_data;
	wire 															w_kernel_4_fifo_wr_en;
	wire 				[6:0] 										w_kernel_4_fifo_count;

	// parameters for output layer

	wire 				[31:0] 										w_output_layer_axi_address;

	wire 				[15:0] 										w_No_of_output_layers;
	wire 				[15:0] 										w_No_of_output_rows;
	wire 				[15:0] 										w_No_of_output_cols;

	wire 															w_out_larger_block_en; 		
	wire 				[15:0] 										w_out_allocated_space_per_row;
	wire 				[7:0] 										w_out_burst_per_row; 			
	wire 				[3:0] 										w_out_read_burst_len;	

	// Parameter for Squeeze net
	wire 	 														w_squ_repeat_en;
	wire 	 														w_avg_en;
	wire 	 			[6:0]  										w_one_exp_ker_addr_limit; 
	wire 	 			[5:0]  										w_exp_ker_depth; 	  	
	wire 	 			[6:0] 										w_layer_dimension; 		
	wire 	 			[11:0] 										w_tot_exp1_ker_addr_limit; 
	wire 	 			[10:0] 										w_one_exp_layer_addr_limit; 
	wire 	 			[5:0]  										w_no_of_exp_kernals; 	
	wire 	 			[7:0]  										w_exp_123_addr_space; 	
	wire 	 			[7:0]  										w_exp_12_addr_space; 	
	wire 	 			[7:0]  										w_exp_1_addr_space; 		
	wire 	 			[10:0] 										w_exp_tot_addr_space; 	
	wire 	 			[9:0]  										w_max_tot_addr_space; 	
	wire 	 			[11:0] 										w_tot_squ_ker_addr_limit; 
	wire 	 			[5:0]  										w_one_squ_ker_addr_limit; 
	wire 	 			[15:0] 										w_tot_repeat_squ_kernals;
	wire 	 			[5:0]  										w_squ_kernals_63; 		
	wire 	 			[8:0]  										w_tot_squ_addr_limit; 	
	wire 	 			[9:0]  										w_no_of_squ_kernals; 	
	wire 	 			[8:0]  										w_squ_3x3_ker_depth; 	
	wire 	 			[6:0]  										w_squ_layer_dimension;		


	// Debug interface
	wire            	[31:0] 										stream;
	wire            	[71:0] 										input_layer_data;
	wire 															sream_in_valid;
	wire                                            				stream_in_rd_en;
	wire            	[7:0]    									stream_in_count;

	wire 				[9:0]  										w_out_fifo_1_dcount;
	wire 				[7:0] 										w_output_layer_1_data;
	wire 															w_out_fifo_1_rd_en;


	reg 															wrreq;
    wire 															w_in_layer_req;

//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------
	reg 						[26:0] 								r_count;

	wire 															hps_rst_n;
	wire 															hps_clk;

	always @(posedge hps_clk) begin 
		if(~hps_rst_n) begin
			r_count <= 0;
		end else begin
			r_count <= r_count + 1;
		end
	end

	assign led_o = r_count[26:19];

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	soc_system soc_system_inst 
	(

		// DDR3 SDRAM
		.memory_mem_a 												(memory_mem_a),
		.memory_mem_ba 												(memory_mem_ba),
		.memory_mem_ck 												(memory_mem_ck),
		.memory_mem_ck_n 											(memory_mem_ck_n),
		.memory_mem_cke 											(memory_mem_cke),
		.memory_mem_cs_n 											(memory_mem_cs_n),
		.memory_mem_ras_n 											(memory_mem_ras_n),
		.memory_mem_cas_n 											(memory_mem_cas_n),
		.memory_mem_we_n 											(memory_mem_we_n),
		.memory_mem_reset_n 										(memory_mem_reset_n),
		.memory_mem_dq 												(memory_mem_dq),
		.memory_mem_dqs 											(memory_mem_dqs),
		.memory_mem_dqs_n 											(memory_mem_dqs_n),
		.memory_mem_odt 											(memory_mem_odt),
		.memory_mem_dm 												(memory_mem_dm),
		.memory_oct_rzqin 											(memory_oct_rzqin),

		.hps_0_f2h_axi_clock_clk 									(hps_clk),
		.hps_0_f2h_sdram0_clock_clk 								(hps_clk),
		.hps_0_h2f_axi_clock_clk 									(hps_clk),

		// Interrupts
		.hps_0_f2h_irq0_irq											(hps_0_f2h_irq0_irq),

		// SDRAM0 AXI
		.hps_0_f2h_sdram0_data_araddr 								(axi_ddr3_araddr),
		.hps_0_f2h_sdram0_data_arlen 								(axi_ddr3_arlen[3:0]), //[3:0]   [7:0]
		.hps_0_f2h_sdram0_data_arid 								(axi_ddr3_arid),
		.hps_0_f2h_sdram0_data_arsize 								(axi_ddr3_arsize),
		.hps_0_f2h_sdram0_data_arburst 								(axi_ddr3_arburst), 
		.hps_0_f2h_sdram0_data_arlock 								(0), // [1:0]  [0:0]
		.hps_0_f2h_sdram0_data_arprot 								(axi_ddr3_arprot),
		.hps_0_f2h_sdram0_data_arvalid 								(axi_ddr3_arvalid),
		.hps_0_f2h_sdram0_data_arcache 								(axi_ddr3_arcache),
		.hps_0_f2h_sdram0_data_awaddr 								(axi_ddr3_awaddr),
		.hps_0_f2h_sdram0_data_awlen 								(axi_ddr3_awlen[3:0]), //[3:0]   [7:0]
		.hps_0_f2h_sdram0_data_awid 								(axi_ddr3_awid),
		.hps_0_f2h_sdram0_data_awsize 								(axi_ddr3_awsize),
		.hps_0_f2h_sdram0_data_awburst 								(axi_ddr3_awburst),
		.hps_0_f2h_sdram0_data_awlock 								(0), // [1:0]  [0:0]
		.hps_0_f2h_sdram0_data_awprot 								(axi_ddr3_awprot),
		.hps_0_f2h_sdram0_data_awvalid 								(axi_ddr3_awvalid),
		.hps_0_f2h_sdram0_data_awcache 								(axi_ddr3_awcache),
		.hps_0_f2h_sdram0_data_bresp 								(axi_ddr3_bresp),
		.hps_0_f2h_sdram0_data_bid 									(axi_ddr3_bid),
		.hps_0_f2h_sdram0_data_bvalid 								(axi_ddr3_bvalid),
		.hps_0_f2h_sdram0_data_bready 								(axi_ddr3_bready),
		.hps_0_f2h_sdram0_data_arready 								(axi_ddr3_arready),
		.hps_0_f2h_sdram0_data_awready 								(axi_ddr3_awready),
		.hps_0_f2h_sdram0_data_rready 								(axi_ddr3_rready),
		.hps_0_f2h_sdram0_data_rdata 								(axi_ddr3_rdata),
		.hps_0_f2h_sdram0_data_rresp 								(axi_ddr3_rresp),
		.hps_0_f2h_sdram0_data_rlast 								(axi_ddr3_rlast),
		.hps_0_f2h_sdram0_data_rid 									(axi_ddr3_rid),
		.hps_0_f2h_sdram0_data_rvalid 								(axi_ddr3_rvalid),
		.hps_0_f2h_sdram0_data_wlast 								(axi_ddr3_wlast),
		.hps_0_f2h_sdram0_data_wvalid 								(axi_ddr3_wvalid),
		.hps_0_f2h_sdram0_data_wdata 								(axi_ddr3_wdata),
		.hps_0_f2h_sdram0_data_wstrb 								(axi_ddr3_wstrb),
		.hps_0_f2h_sdram0_data_wready 								(axi_ddr3_wready),
		.hps_0_f2h_sdram0_data_wid 									(axi_ddr3_wid),

		// SDRAM 1
		.hps_0_f2h_sdram1_clock_clk     							(hps_clk),      
		.hps_0_f2h_sdram1_data_araddr 								(sdram1_data_araddr),    
		.hps_0_f2h_sdram1_data_arlen 								(sdram1_data_arlen),     
		.hps_0_f2h_sdram1_data_arid  								(sdram1_data_arid),      
		.hps_0_f2h_sdram1_data_arsize 								(sdram1_data_arsize),    
		.hps_0_f2h_sdram1_data_arburst 								(sdram1_data_arburst),   
		.hps_0_f2h_sdram1_data_arlock 								(sdram1_data_arlock),    
		.hps_0_f2h_sdram1_data_arprot 								(sdram1_data_arprot),    
		.hps_0_f2h_sdram1_data_arvalid 								(sdram1_data_arvalid),   
		.hps_0_f2h_sdram1_data_arcache 								(sdram1_data_arcache),   
		.hps_0_f2h_sdram1_data_awaddr 								(sdram1_data_awaddr),    
		.hps_0_f2h_sdram1_data_awlen 								(sdram1_data_awlen),     
		.hps_0_f2h_sdram1_data_awid  								(sdram1_data_awid),      
		.hps_0_f2h_sdram1_data_awsize 								(sdram1_data_awsize),    
		.hps_0_f2h_sdram1_data_awburst 								(sdram1_data_awburst),   
		.hps_0_f2h_sdram1_data_awlock 								(sdram1_data_awlock),    
		.hps_0_f2h_sdram1_data_awprot 								(sdram1_data_awprot),    
		.hps_0_f2h_sdram1_data_awvalid 								(sdram1_data_awvalid),   
		.hps_0_f2h_sdram1_data_awcache 								(sdram1_data_awcache),   
		.hps_0_f2h_sdram1_data_bresp 								(sdram1_data_bresp),     
		.hps_0_f2h_sdram1_data_bid  								(sdram1_data_bid),       
		.hps_0_f2h_sdram1_data_bvalid 								(sdram1_data_bvalid),    
		.hps_0_f2h_sdram1_data_bready 								(sdram1_data_bready),    
		.hps_0_f2h_sdram1_data_arready 								(sdram1_data_arready),   
		.hps_0_f2h_sdram1_data_awready 								(sdram1_data_awready),   
		.hps_0_f2h_sdram1_data_rready 								(sdram1_data_rready),    
		.hps_0_f2h_sdram1_data_rdata 								(sdram1_data_rdata),     
		.hps_0_f2h_sdram1_data_rresp 								(sdram1_data_rresp),     
		.hps_0_f2h_sdram1_data_rlast 								(sdram1_data_rlast),     
		.hps_0_f2h_sdram1_data_rid  								(sdram1_data_rid),       
		.hps_0_f2h_sdram1_data_rvalid 								(sdram1_data_rvalid),    
		.hps_0_f2h_sdram1_data_wlast 								(sdram1_data_wlast),     
		.hps_0_f2h_sdram1_data_wvalid 								(sdram1_data_wvalid),    
		.hps_0_f2h_sdram1_data_wdata 								(sdram1_data_wdata),     
		.hps_0_f2h_sdram1_data_wstrb 								(sdram1_data_wstrb),     
		.hps_0_f2h_sdram1_data_wready 								(sdram1_data_wready),    
		.hps_0_f2h_sdram1_data_wid  								(sdram1_data_wid),       

		// HPS to FPGA Low weight
		.hps_0_h2f_lw_axi_clock_clk 								(hps_clk),
		.hps_0_h2f_lw_axi_master_awid 								(hps_0_h2f_lw_axi_master_awid),
		.hps_0_h2f_lw_axi_master_awaddr 							(hps_0_h2f_lw_axi_master_awaddr),
		.hps_0_h2f_lw_axi_master_awlen 								(hps_0_h2f_lw_axi_master_awlen),
		.hps_0_h2f_lw_axi_master_awsize 							(hps_0_h2f_lw_axi_master_awsize),  
		.hps_0_h2f_lw_axi_master_awburst 							(hps_0_h2f_lw_axi_master_awburst), 
		.hps_0_h2f_lw_axi_master_awlock 							(hps_0_h2f_lw_axi_master_awlock),  
		.hps_0_h2f_lw_axi_master_awcache 							(hps_0_h2f_lw_axi_master_awcache), 
		.hps_0_h2f_lw_axi_master_awprot 							(hps_0_h2f_lw_axi_master_awprot),  
		.hps_0_h2f_lw_axi_master_awvalid 							(hps_0_h2f_lw_axi_master_awvalid), 
		.hps_0_h2f_lw_axi_master_awready 							(hps_0_h2f_lw_axi_master_awready), 
		.hps_0_h2f_lw_axi_master_wid 								(hps_0_h2f_lw_axi_master_wid),     
		.hps_0_h2f_lw_axi_master_wdata 								(hps_0_h2f_lw_axi_master_wdata),   
		.hps_0_h2f_lw_axi_master_wstrb 								(hps_0_h2f_lw_axi_master_wstrb),   
		.hps_0_h2f_lw_axi_master_wlast 								(hps_0_h2f_lw_axi_master_wlast),   
		.hps_0_h2f_lw_axi_master_wvalid 							(hps_0_h2f_lw_axi_master_wvalid),  
		.hps_0_h2f_lw_axi_master_wready 							(hps_0_h2f_lw_axi_master_wready),  
		.hps_0_h2f_lw_axi_master_bid 								(hps_0_h2f_lw_axi_master_bid),
		.hps_0_h2f_lw_axi_master_bresp 								(hps_0_h2f_lw_axi_master_bresp),
		.hps_0_h2f_lw_axi_master_bvalid 							(hps_0_h2f_lw_axi_master_bvalid),
		.hps_0_h2f_lw_axi_master_bready 							(hps_0_h2f_lw_axi_master_bready),
		.hps_0_h2f_lw_axi_master_arid 								(hps_0_h2f_lw_axi_master_arid),
		.hps_0_h2f_lw_axi_master_araddr 							(hps_0_h2f_lw_axi_master_araddr),
		.hps_0_h2f_lw_axi_master_arlen 								(hps_0_h2f_lw_axi_master_arlen),
		.hps_0_h2f_lw_axi_master_arsize 							(hps_0_h2f_lw_axi_master_arsize),
		.hps_0_h2f_lw_axi_master_arburst 							(hps_0_h2f_lw_axi_master_arburst), 
		.hps_0_h2f_lw_axi_master_arlock 							(hps_0_h2f_lw_axi_master_arlock),  
		.hps_0_h2f_lw_axi_master_arcache 							(hps_0_h2f_lw_axi_master_arcache), 
		.hps_0_h2f_lw_axi_master_arprot 							(hps_0_h2f_lw_axi_master_arprot),  
		.hps_0_h2f_lw_axi_master_arvalid 							(hps_0_h2f_lw_axi_master_arvalid), 
		.hps_0_h2f_lw_axi_master_arready 							(hps_0_h2f_lw_axi_master_arready), 
		.hps_0_h2f_lw_axi_master_rid 								(hps_0_h2f_lw_axi_master_rid),     
		.hps_0_h2f_lw_axi_master_rdata 								(hps_0_h2f_lw_axi_master_rdata),   
		.hps_0_h2f_lw_axi_master_rresp 								(hps_0_h2f_lw_axi_master_rresp),   
		.hps_0_h2f_lw_axi_master_rlast 								(hps_0_h2f_lw_axi_master_rlast),   
		.hps_0_h2f_lw_axi_master_rvalid 							(hps_0_h2f_lw_axi_master_rvalid),
		.hps_0_h2f_lw_axi_master_rready 							(hps_0_h2f_lw_axi_master_rready),

		.hps_0_h2f_user0_clock_clk 									(hps_clk),
		.hps_0_h2f_reset_reset_n 									(hps_rst_n)            //            hps_0_h2f_reset.reset_n
		//.hps_0_h2f_user1_clock_clk 								(hps_clk)
	);

	// Input Layer Controller
	input_layer #(
        .C_S_AXI_ID_WIDTH 											(3),
        .C_S_AXI_ADDR_WIDTH 										(32),
        .C_S_AXI_DATA_WIDTH 										(64),
        .C_S_AXI_BURST_LEN 											(8),
        .STREAM_DATA_WIDTH 											(72)    
    ) input_layer_inst 
    (
		// parameters from axi_lite
		.Start 														(w_Start),
		.axi_address 												(w_input_layer_axi_start_addr),

		.no_of_input_layers  										(w_No_of_input_layers),
		.input_layer_row_size 										(w_No_of_rows),
		.input_layer_col_size 										(w_No_of_cols),
		.in_layer_ddr3_data_rdy 									(w_in_layer_ddr3_data_rdy),

		.larger_block_en											(w_larger_block_en),
		.allocated_space_per_row									(w_allocated_space_per_row),
		.stride2en													(w_stride2en),
		.burst_per_row												(w_burst_per_row),
		.read_burst_len												(w_read_burst_len),

		.input_layer_1_data 										(input_layer_data),
		.input_layer_1_valid 										(sream_in_valid),
		.input_layer_1_rdy 											(w_in_layer_req), 
		.input_layer_1_id 											(), 

		// AXI signals
		.clk  														(hps_clk),				
    	.reset_n  													(hps_rst_n),
    	.read_done													(hps_0_f2h_irq0_irq[0]),
	
		//.M_axi_awid 												(axi_ddr3_awid), 	
		//.M_axi_awaddr 											(axi_ddr3_awaddr),	
		//.M_axi_awlen 												(axi_ddr3_awlen),	
		//.M_axi_awsize 											(axi_ddr3_awsize), 	
		//.M_axi_awburst 											(axi_ddr3_awburst),   
		//.M_axi_awlock 											(axi_ddr3_awlock),	
		//.M_axi_awcache 											(axi_ddr3_awcache), 	
		//.M_axi_awprot 											(axi_ddr3_awprot), 	
   		//.M_axi_awqos 												(axi_ddr3_awqos), 	
		//.M_axi_awvalid 											(axi_ddr3_awvalid),	
		//.M_axi_awready 											(axi_ddr3_awready), 	

		// AXI Write Data Control Signals
		//.M_axi_wdata 												(axi_ddr3_wdata),		
		//.M_axi_wstrb 												(axi_ddr3_wstrb),		
		//.M_axi_wlast 												(axi_ddr3_wlast),		
		//.M_axi_wvalid 											(axi_ddr3_wvalid),		
		//.M_axi_wready 											(axi_ddr3_wready),		

		// AXI Response Control Signals
		//.M_axi_bid 												(axi_ddr3_bid), 			
		//.M_axi_bresp 												(axi_ddr3_bresp),		
		//.M_axi_bvalid 											(axi_ddr3_bvalid), 		
		//.M_axi_bready 											(axi_ddr3_bready),		

		// AXI Read Address Control Signals
		.M_axi_arid 												(axi_ddr3_arid), 		
		.M_axi_araddr 												(axi_ddr3_araddr), 		
		.M_axi_arlen 												(axi_ddr3_arlen), 		
		.M_axi_arsize 												(axi_ddr3_arsize), 		
		.M_axi_arburst 												(axi_ddr3_arburst), 		
		.M_axi_arlock 												(axi_ddr3_arlock), 		
		.M_axi_arcache 												(axi_ddr3_arcache), 		
		.M_axi_arprot 												(axi_ddr3_arprot), 		
		.M_axi_arqos 												(axi_ddr3_arqos),		
		.M_axi_arvalid 												(axi_ddr3_arvalid),		
		.M_axi_arready 												(axi_ddr3_arready),		

		// AXI Read Data Control Signals
		.M_axi_rid 													(axi_ddr3_rid), 			
		.M_axi_rdata 												(axi_ddr3_rdata),		
		.M_axi_rresp 												(axi_ddr3_rresp),		
    	.M_axi_rlast 												(axi_ddr3_rlast),		
		.M_axi_rvalid 												(axi_ddr3_rvalid),		
		.M_axi_rready 												(axi_ddr3_rready)
	);


	kernel_loader #(
        .C_S_AXI_ID_WIDTH  											(3),
        .C_S_AXI_ADDR_WIDTH											(32),
        .C_S_AXI_DATA_WIDTH											(64),
        .C_S_AXI_BURST_LEN 											(8)
    ) kernel_loader_inst
    (
		// input from parameter fetcher
		// skip unnecessary fifos
		.Start 													(w_Start),
		.skip_en 												(w_skip_en),

		.kernel_0_start_addr									(w_kernel_0_start_addr),
		.kernel_0_end_addr										(w_kernel_0_end_addr),
		.kernel_0_wrap_en										(w_kernel_0_wrap_en),
		.kernel_0_fifo_wr_data									(w_kernel_0_fifo_wr_data),
		.kernel_0_fifo_wr_en									(w_kernel_0_fifo_wr_en),
		.kernel_0_fifo_count									(w_kernel_0_fifo_count),


		.kernel_1_start_addr									(w_kernel_1_start_addr),
		.kernel_1_end_addr										(w_kernel_1_end_addr),
		.kernel_1_wrap_en										(w_kernel_1_wrap_en),
		.kernel_1_fifo_wr_data									(w_kernel_1_fifo_wr_data),
		.kernel_1_fifo_wr_en									(w_kernel_1_fifo_wr_en),
		.kernel_1_fifo_count									(w_kernel_1_fifo_count),

		.kernel_2_start_addr									(w_kernel_2_start_addr),
		.kernel_2_end_addr										(w_kernel_2_end_addr),
		.kernel_2_wrap_en										(w_kernel_2_wrap_en),
		.kernel_2_fifo_wr_data									(w_kernel_2_fifo_wr_data),
		.kernel_2_fifo_wr_en									(w_kernel_2_fifo_wr_en),
		.kernel_2_fifo_count									(w_kernel_2_fifo_count),

    	.kernel_3_start_addr									(w_kernel_3_start_addr),
    	.kernel_3_end_addr										(w_kernel_3_end_addr),
    	.kernel_3_wrap_en										(w_kernel_3_wrap_en),
    	.kernel_3_fifo_wr_data									(w_kernel_3_fifo_wr_data),
    	.kernel_3_fifo_wr_en									(w_kernel_3_fifo_wr_en),
    	.kernel_3_fifo_count									(w_kernel_3_fifo_count),

    	.kernel_4_start_addr									(w_kernel_4_start_addr),
    	.kernel_4_end_addr										(w_kernel_4_end_addr),
    	.kernel_4_wrap_en										(w_kernel_4_wrap_en),
    	.kernel_4_fifo_wr_data									(w_kernel_4_fifo_wr_data),
    	.kernel_4_fifo_wr_en									(w_kernel_4_fifo_wr_en),
    	.kernel_4_fifo_count									(w_kernel_4_fifo_count),


		.clk 													(hps_clk),				
		.reset_n 												(hps_rst_n),
		.M_axi_awid 											(sdram1_data_awid), 	
		.M_axi_awaddr 											(sdram1_data_awaddr),	
		.M_axi_awlen 											(sdram1_data_awlen),	
		.M_axi_awsize 											(sdram1_data_awsize), 	
		.M_axi_awburst 											(sdram1_data_awburst), 
		.M_axi_awlock 											(sdram1_data_awlock),	
		.M_axi_awcache 											(sdram1_data_awcache), 
		.M_axi_awprot 											(sdram1_data_awprot), 	
		.M_axi_awqos 											(sdram1_data_awqos), 	
		.M_axi_awvalid 											(sdram1_data_awvalid),	
		.M_axi_awready 											(sdram1_data_awready), 

		.M_axi_wdata 											(sdram1_data_wdata),		
		.M_axi_wstrb 											(sdram1_data_wstrb),		
		.M_axi_wlast 											(sdram1_data_wlast),		
		.M_axi_wvalid 											(sdram1_data_wvalid),	
		.M_axi_wready 											(sdram1_data_wready),	

		.M_axi_bid 												(sdram1_data_bid), 			
		.M_axi_bresp 											(sdram1_data_bresp),		
		.M_axi_bvalid 											(sdram1_data_bvalid), 	
		.M_axi_bready 											(sdram1_data_bready),	

		.M_axi_arid 											(sdram1_data_arid), 		
		.M_axi_araddr 											(sdram1_data_araddr), 	
		.M_axi_arlen 											(sdram1_data_arlen), 		
		.M_axi_arsize 											(sdram1_data_arsize), 	
		.M_axi_arburst 											(sdram1_data_arburst), 
		.M_axi_arlock 											(sdram1_data_arlock), 	
		.M_axi_arcache 											(sdram1_data_arcache), 
		.M_axi_arprot 											(sdram1_data_arprot), 	
		.M_axi_arqos 											(sdram1_data_arqos),		
		.M_axi_arvalid 											(sdram1_data_arvalid),	
		.M_axi_arready 											(sdram1_data_arready),	

		.M_axi_rid 												(sdram1_data_rid), 			
		.M_axi_rdata 											(sdram1_data_rdata),		
		.M_axi_rresp 											(sdram1_data_rresp),		
		.M_axi_rlast 											(sdram1_data_rlast),		
		.M_axi_rvalid 											(sdram1_data_rvalid),	
		.M_axi_rready 											(sdram1_data_rready)
	);	


    // // small logic for fifo
    
    // always @(posedge hps_clk) begin : proc_wrreq
    // 	if(~hps_rst_n) begin
    // 		wrreq <= 0;
    // 	end else if(w_out_fifo_1_dcount < 150) begin
    // 		wrreq <= sream_in_valid;
    // 	end else begin
    // 		wrreq <= 0;
    // 	end
    // end
    // assign w_in_layer_req = (wrreq && sream_in_valid ? 1 : 0);

	// in_out_fifo in_out_fifo_inst(
	// .clock													(hps_clk),
	// .sclr													(w_Start),
	// .data													(input_layer_data[39:32]),
	// .rdreq													(w_out_fifo_1_rd_en),
	// .wrreq													(w_in_layer_req),
	// .q														(w_output_layer_1_data),
	// .usedw													(w_out_fifo_1_dcount)
	// );


	// six4to32 six4to32_inst
	// (
	// .aclr(w_Start),
	// .data(w_kernel_0_fifo_wr_data),
	// .rdclk(hps_clk),
	// .rdreq(stream_in_rd_en),
	// .wrclk(hps_clk),
	// .wrreq(w_kernel_0_fifo_wr_en),
	// .q(stream),
	// .wrfull(),
	// .wrusedw(w_kernel_0_fifo_count)
	// );


	output_layer #(
        .C_S_AXI_ID_WIDTH             							(3),
        .C_S_AXI_ADDR_WIDTH           							(32),
        .C_S_AXI_DATA_WIDTH           							(64),
        .C_S_AXI_BURST_LEN            							(8),
        .STREAM_DATA_WIDTH            							(8)      
    ) output_layer_inst
    (
		.Start 												(w_Start),
		.axi_address 										(w_output_layer_axi_address),

		.no_of_output_layers 								(w_No_of_output_layers),
		.output_layer_row_size 								(w_No_of_output_rows),
		.output_layer_col_size 								(w_No_of_output_cols),

		.larger_block_en 									(w_out_larger_block_en),
		.allocated_space_per_row 							(w_out_allocated_space_per_row),
		.burst_per_row 										(w_out_burst_per_row),
		.write_burst_len 									(w_out_read_burst_len),


		.output_layer_1_data								(w_output_layer_1_data),
		.out_fifo_1_dcount									(w_out_fifo_1_dcount),
		.out_fifo_1_rd_en									(w_out_fifo_1_rd_en), 

		.clk 												(hps_clk),				
   		.reset_n 											(hps_rst_n),
   		.write_done											(hps_0_f2h_irq0_irq[1]),
		
		.M_axi_awid 										(axi_ddr3_awid),
		.M_axi_awaddr 										(axi_ddr3_awaddr),
		.M_axi_awlen 										(axi_ddr3_awlen),
		.M_axi_awsize 										(axi_ddr3_awsize),
		.M_axi_awburst 										(axi_ddr3_awburst),
		.M_axi_awlock 										(axi_ddr3_awlock),
		.M_axi_awcache 										(axi_ddr3_awcache),						 	
		.M_axi_awprot 										(axi_ddr3_awprot),
   		.M_axi_awqos 										(axi_ddr3_awqos),
		.M_axi_awvalid 										(axi_ddr3_awvalid),
		.M_axi_awready 										(axi_ddr3_awready),
		
		.M_axi_wdata 										(axi_ddr3_wdata),		
		.M_axi_wstrb 										(axi_ddr3_wstrb),		
		.M_axi_wlast 										(axi_ddr3_wlast),		
		.M_axi_wvalid   									(axi_ddr3_wvalid),		
		.M_axi_wready										(axi_ddr3_wready),

		.M_axi_bid											(axi_ddr3_bid), 
		.M_axi_bresp										(axi_ddr3_bresp),
		.M_axi_bvalid										(axi_ddr3_bvalid),
		.M_axi_bready										(axi_ddr3_bready),					
	);

	// Configuration Controller
	axi_mem #
	(
		.C_S_AXI_ID_WIDTH									(12),
		.C_S_AXI_DATA_WIDTH									(32),
		.C_S_AXI_ADDR_WIDTH									(10),
		.C_S_AXI_AWUSER_WIDTH								(0),
		.C_S_AXI_ARUSER_WIDTH								(0),
		.C_S_AXI_WUSER_WIDTH								(0),
		.C_S_AXI_RUSER_WIDTH								(0),
		.C_S_AXI_BUSER_WIDTH								(0)
	)
	axi_mem_inst
	(
		.Start 												(w_Start),

		.max_pool_en 										(max_pool_en),
		.expand_en 											(expand_en),
		.in_layer_ddr3_data_rdy 							(w_in_layer_ddr3_data_rdy),
		.No_of_input_layers 								(w_No_of_input_layers),
		.No_of_rows 										(w_No_of_rows),
		.No_of_cols 										(w_No_of_cols),

		.No_of_expand_layers 								(No_of_expand_layers),
		.No_of_squeeze_layers 								(No_of_squeeze_layers),

		.input_layer_axi_start_addr 						(w_input_layer_axi_start_addr),
		.larger_block_en									(w_larger_block_en),
		.allocated_space_per_row							(w_allocated_space_per_row),
		.stride2en											(w_stride2en),
		.burst_per_row										(w_burst_per_row),
		.read_burst_len										(w_read_burst_len),

		.skip_en 											(w_skip_en),

		.kernel_0_start_addr 								(w_kernel_0_start_addr),
		.kernel_0_end_addr 									(w_kernel_0_end_addr),
		.kernel_0_wrap_en 									(w_kernel_0_wrap_en),

		.kernel_1_start_addr 								(w_kernel_1_start_addr),
		.kernel_1_end_addr 									(w_kernel_1_end_addr),
		.kernel_1_wrap_en 									(w_kernel_1_wrap_en),

		.kernel_2_start_addr 								(w_kernel_2_start_addr),
		.kernel_2_end_addr 									(w_kernel_2_end_addr),
		.kernel_2_wrap_en 									(w_kernel_2_wrap_en),

		.kernel_3_start_addr 								(w_kernel_3_start_addr),
		.kernel_3_end_addr 									(w_kernel_3_end_addr),
		.kernel_3_wrap_en 									(w_kernel_3_wrap_en),

		.kernel_4_start_addr 								(w_kernel_4_start_addr),
		.kernel_4_end_addr 									(w_kernel_4_end_addr),
		.kernel_4_wrap_en 									(w_kernel_4_wrap_en),

		.No_of_output_layers								(w_No_of_output_layers),
		.No_of_output_rows									(w_No_of_output_rows),
		.No_of_output_cols									(w_No_of_output_cols),
		.output_layer_axi_address 							(w_output_layer_axi_address),

		.out_larger_block_en 								(w_out_larger_block_en),
		.out_allocated_space_per_row 						(w_out_allocated_space_per_row),
		.out_burst_per_row 									(w_out_burst_per_row),
		.out_read_burst_len 								(w_out_read_burst_len),

		.squ_repeat_en_o 									(w_squ_repeat_en),
		.avg_en_o 											(w_avg_en),
		.one_exp_ker_addr_limit_o 							(w_one_exp_ker_addr_limit),
		.exp_ker_depth_o 									(w_exp_ker_depth),
		.layer_dimension_o 									(w_layer_dimension),
		.tot_exp1_ker_addr_limit_o 							(w_tot_exp1_ker_addr_limit),
		.one_exp_layer_addr_limit_o 						(w_one_exp_layer_addr_limit),
		.no_of_exp_kernals_o 								(w_no_of_exp_kernals),
		.exp_123_addr_space_o 								(w_exp_123_addr_space),
		.exp_12_addr_space_o 								(w_exp_12_addr_space),
		.exp_1_addr_space_o 								(w_exp_1_addr_space),
		.exp_tot_addr_space_o 								(w_exp_tot_addr_space),
		.max_tot_addr_space_o 								(w_max_tot_addr_space),
		.tot_squ_ker_addr_limit_o 							(w_tot_squ_ker_addr_limit),
		.one_squ_ker_addr_limit_o 							(w_one_squ_ker_addr_limit),
		.tot_repeat_squ_kernals_o 							(w_tot_repeat_squ_kernals),
		.squ_kernals_63_o 									(w_squ_kernals_63),
		.tot_squ_addr_limit_o 								(w_tot_squ_addr_limit),
		.no_of_squ_kernals_o 								(w_no_of_squ_kernals),
		.squ_3x3_ker_depth_o 								(w_squ_3x3_ker_depth),
		.squ_layer_dimension_o 								(w_squ_layer_dimension),

		.stream_in 											(stream),
		.stream_in_rd_en 									(stream_in_rd_en),
		.stream_in_count 									(stream_in_count),


		.S_AXI_ACLK											(hps_clk),
		.S_AXI_ARESETN										(hps_rst_n),

		.S_AXI_AWID											(hps_0_h2f_lw_axi_master_awid),
		.S_AXI_AWADDR										(hps_0_h2f_lw_axi_master_awaddr),
		.S_AXI_AWLEN										(hps_0_h2f_lw_axi_master_awlen),
		.S_AXI_AWSIZE										(hps_0_h2f_lw_axi_master_awsize),
		.S_AXI_AWBURST										(hps_0_h2f_lw_axi_master_awburst),
		.S_AXI_AWLOCK										(hps_0_h2f_lw_axi_master_awlock),
		.S_AXI_AWCACHE										(hps_0_h2f_lw_axi_master_awcache),
		.S_AXI_AWPROT										(hps_0_h2f_lw_axi_master_awprot),
		.S_AXI_AWQOS										(hps_0_h2f_lw_axi_master_awqos),
		.S_AXI_AWREGION										(hps_0_h2f_lw_axi_master_awregion),
	//	.S_AXI_AWUSER										(hps_0_h2f_lw_axi_master_awuser),
		.S_AXI_AWVALID										(hps_0_h2f_lw_axi_master_awvalid),
		.S_AXI_AWREADY										(hps_0_h2f_lw_axi_master_awready),

		.S_AXI_WDATA										(hps_0_h2f_lw_axi_master_wdata),
		.S_AXI_WSTRB										(hps_0_h2f_lw_axi_master_wstrb),
		.S_AXI_WLAST										(hps_0_h2f_lw_axi_master_wlast),
	//	.S_AXI_WUSER										(hps_0_h2f_lw_axi_master_wuser),
		.S_AXI_WVALID										(hps_0_h2f_lw_axi_master_wvalid),
		.S_AXI_WREADY										(hps_0_h2f_lw_axi_master_wready),

		.S_AXI_BID											(hps_0_h2f_lw_axi_master_bid),
		.S_AXI_BRESP										(hps_0_h2f_lw_axi_master_bresp),
	//	.S_AXI_BUSER										(hps_0_h2f_lw_axi_master_buser),
		.S_AXI_BVALID										(hps_0_h2f_lw_axi_master_bvalid),
		.S_AXI_BREADY										(hps_0_h2f_lw_axi_master_bready),

		.S_AXI_ARID											(hps_0_h2f_lw_axi_master_arid),
		.S_AXI_ARADDR										(hps_0_h2f_lw_axi_master_araddr),
		.S_AXI_ARLEN										(hps_0_h2f_lw_axi_master_arlen),
		.S_AXI_ARSIZE										(hps_0_h2f_lw_axi_master_arsize),
		.S_AXI_ARBURST										(hps_0_h2f_lw_axi_master_arburst),
		.S_AXI_ARLOCK										(hps_0_h2f_lw_axi_master_arlock),
		.S_AXI_ARCACHE										(hps_0_h2f_lw_axi_master_arcache),
		.S_AXI_ARPROT										(hps_0_h2f_lw_axi_master_arprot),
		.S_AXI_ARQOS										(hps_0_h2f_lw_axi_master_arqos),
		.S_AXI_ARREGION										(hps_0_h2f_lw_axi_master_arregion),
	//	.S_AXI_ARUSER										(hps_0_h2f_lw_axi_master_aruser),
		.S_AXI_ARVALID										(hps_0_h2f_lw_axi_master_arvalid),
		.S_AXI_ARREADY										(hps_0_h2f_lw_axi_master_arready),

		.S_AXI_RID											(hps_0_h2f_lw_axi_master_rid),
		.S_AXI_RDATA										(hps_0_h2f_lw_axi_master_rdata),
		.S_AXI_RRESP										(hps_0_h2f_lw_axi_master_rresp),
		.S_AXI_RLAST										(hps_0_h2f_lw_axi_master_rlast),
	//	.S_AXI_RUSER										(hps_0_h2f_lw_axi_master_ruser),
		.S_AXI_RVALID										(hps_0_h2f_lw_axi_master_rvalid),
		.S_AXI_RREADY										(hps_0_h2f_lw_axi_master_rready)
	);

	// Squeeze net TOP
	squeezenet_top squeezenet_top_inst
	(
		.clk_i 												(hps_clk),
		.rst_n_i 											(hps_rst_n),

		.start_i 											(w_Start),
		.exp_1x1_en_i 										(expand_en),
		.max_en_i 											(max_pool_en),
		.squ_repeat_en_i 									(w_squ_repeat_en),
		.avg_en_i 											(w_avg_en),
		.one_exp_ker_addr_limit_i 							(w_one_exp_ker_addr_limit),
		.exp_ker_depth_i 									(w_exp_ker_depth),
		.layer_dimension_i 									(w_layer_dimension),
		.tot_exp1_ker_addr_limit_i 							(w_tot_exp1_ker_addr_limit),
		.one_exp_layer_addr_limit_i 						(w_one_exp_layer_addr_limit),
		.no_of_exp_kernals_i 								(w_no_of_exp_kernals),
		.exp_123_addr_space_i 								(w_exp_123_addr_space),
		.exp_12_addr_space_i 								(w_exp_12_addr_space),
		.exp_1_addr_space_i 								(w_exp_1_addr_space),
		.exp_tot_addr_space_i 								(w_exp_tot_addr_space),
		.max_tot_addr_space_i 								(w_max_tot_addr_space),
		.tot_squ_ker_addr_limit_i 							(w_tot_squ_ker_addr_limit),
		.one_squ_ker_addr_limit_i 							(w_one_squ_ker_addr_limit),
		.tot_repeat_squ_kernals_i 							(w_tot_repeat_squ_kernals),
		.squ_kernals_63_i 									(w_squ_kernals_63),
		.tot_squ_addr_limit_i 								(w_tot_squ_addr_limit),
		.no_of_squ_kernals_i 								(w_no_of_squ_kernals),
		.squ_3x3_ker_depth_i 								(w_squ_3x3_ker_depth),
		.squ_layer_dimension_i 								(w_squ_layer_dimension),

		.layer_req_o 										(w_in_layer_req),
		.layer_ready_i 										(sream_in_valid),
		.layer_data_i 										(input_layer_data),

		.fifo_exp_3x3_clr_i 								(w_Start),
		.fifo_exp_3x3_wr_data_i 							(w_kernel_0_fifo_wr_data),
		.fifo_exp_3x3_wr_en_i 								(w_kernel_0_fifo_wr_en),
		.fifo_exp_3x3_data_count_o 							(w_kernel_0_fifo_count),

		.fifo_exp_1x1_clr_i 								(w_Start),
		.fifo_exp_1x1_wr_data_i 							(w_kernel_1_fifo_wr_data),
		.fifo_exp_1x1_wr_en_i 								(w_kernel_1_fifo_wr_en),
		.fifo_exp_1x1_data_count_o 							(w_kernel_1_fifo_count),

		.fifo_exp_bash_clr_i 								(w_Start),
		.fifo_exp_bash_wr_data_i 							(w_kernel_2_fifo_wr_data),
		.fifo_exp_bash_wr_en_i 								(w_kernel_2_fifo_wr_en),
		.fifo_exp_bash_data_count_o 						(w_kernel_2_fifo_count),
	
		.fifo_squeeze_clr_i 								(w_Start),
		.fifo_squeeze_wr_data_i 							(w_kernel_3_fifo_wr_data),
		.fifo_squeeze_wr_en_i 								(w_kernel_3_fifo_wr_en),
		.fifo_squeeze_data_count_o 							(w_kernel_3_fifo_count),

		.fifo_squ_bash_clr_i 								(w_Start),
		.fifo_squ_bash_wr_data_i 							(w_kernel_4_fifo_wr_data),
		.fifo_squ_bash_wr_en_i 								(w_kernel_4_fifo_wr_en),
		.fifo_squ_bash_data_count_o 						(w_kernel_4_fifo_count),
	
		.fifo_out_rd_data_o 								(w_output_layer_1_data),
		.fifo_out_rd_en_i 									(w_out_fifo_1_rd_en),
		.fifo_out_empty_o 									(),
		.fifo_out_data_count 								(w_out_fifo_1_dcount)
	);



endmodule

	