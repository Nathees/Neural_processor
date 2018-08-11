module top_sim();


		localparam C_S_AXI_ID_WIDTH = 1;
		localparam C_S_AXI_DATA_WIDTH = 64;
		localparam C_S_AXI_ADDR_WIDTH = 32;
		localparam C_S_AXI_AWUSER_WIDTH = 0;
		localparam C_S_AXI_WUSER_WIDTH = 0;
		localparam C_S_AXI_RUSER_WIDTH = 0;
		localparam C_S_AXI_BUSER_WIDTH = 0;
		localparam STREAM_DATA_WIDTH = 72;
		localparam C_S_AXI_BURST_LEN = 8;


		reg clk;
		reg reset_n;
		
		reg Start;

		wire [71:0] data_o;
		wire  		valid_o;
		wire w_input_layer_1_rdy;


		wire [C_S_AXI_ID_WIDTH-1:0] w_AXI_AWID;
		wire [C_S_AXI_ADDR_WIDTH-1:0] w_AXI_AWADDR;
		wire [7:0] w_AXI_AWLEN;
		wire [2:0] w_AXI_AWSIZE;
		wire [1:0] w_AXI_AWBURST;
		wire [0:0] w_AXI_AWLOCK;
		wire [3:0] w_AXI_AWCACHE;
		wire [2:0] w_AXI_AWPROT;
		wire [3:0] w_AXI_AWQOS;
		wire [3:0] w_AXI_AWREGION;
		wire [C_S_AXI_AWUSER_WIDTH-1:0] w_AXI_AWUSER;
		wire [0:0] w_AXI_AWVALID;
		wire [0:0] w_AXI_AWREADY;
		wire [C_S_AXI_DATA_WIDTH-1:0] w_AXI_WDATA;
		wire [(C_S_AXI_DATA_WIDTH)/8 -1:0] w_AXI_WSTRB;
		wire [0:0] w_AXI_WLAST;
		wire [C_S_AXI_WUSER_WIDTH-1:0] w_AXI_WUSER;
		wire [0:0] w_AXI_WVALID;
		wire [0:0] w_AXI_WREADY;
		wire [C_S_AXI_ID_WIDTH-1:0] w_AXI_BID;
		wire [1:0] w_AXI_BRESP;
		wire [C_S_AXI_BUSER_WIDTH-1:0] w_AXI_BUSER;
		wire [0:0] w_AXI_BVALID;
		wire [0:0] w_AXI_BREADY;
		wire [C_S_AXI_ID_WIDTH-1:0] w_AXI_ARID;
		wire [C_S_AXI_ADDR_WIDTH-1:0] w_AXI_ARADDR;
		wire [7:0] w_AXI_ARLEN;
		wire [2:0] w_AXI_ARSIZE;
		wire [1:0] w_AXI_ARBURST;
		wire [0:0] w_AXI_ARLOCK;
		wire [3:0] w_AXI_ARCACHE;
		wire [2:0] w_AXI_ARPROT;
		wire [3:0] w_AXI_ARQOS;
		wire [3:0] w_AXI_ARREGION;
		wire [C_S_AXI_RUSER_WIDTH-1:0] w_AXI_ARUSER;
		wire [0:0] w_AXI_ARVALID;
		wire [0:0] w_AXI_ARREADY;
		wire [C_S_AXI_ID_WIDTH-1:0] w_AXI_RID;
		wire [C_S_AXI_DATA_WIDTH-1:0] w_AXI_RDATA;
		wire [1:0] w_AXI_RRESP;
		wire [0:0] w_AXI_RLAST;
		wire [C_S_AXI_RUSER_WIDTH-1:0] w_AXI_RUSER;
		wire [0:0] w_AXI_RVALID;
		wire [0:0] w_AXI_RREADY;

	// axi_mem  #
	// (
	// 	.C_S_AXI_ID_WIDTH(1),
	// 	.C_S_AXI_DATA_WIDTH(32),
	// 	.C_S_AXI_ADDR_WIDTH(10),
	// 	.C_S_AXI_AWUSER_WIDTH(0),
	// 	.C_S_AXI_ARUSER_WIDTH(0),
	// 	.C_S_AXI_WUSER_WIDTH(0),
	// 	.C_S_AXI_RUSER_WIDTH(0),
	// 	.C_S_AXI_BUSER_WIDTH(0)
	// )
	// axi_mem_inst
	// (

	// 	.S_AXI_ACLK(clk),
	// 	.S_AXI_ARESETN(reset_n),
	// 	.S_AXI_AWID(w_AXI_AWID),
	// 	.S_AXI_AWADDR(w_AXI_AWADDR),
	// 	.S_AXI_AWLEN(w_AXI_AWLEN),
	// 	.S_AXI_AWSIZE(w_AXI_AWSIZE),
	// 	.S_AXI_AWBURST(w_AXI_AWBURST),
	// 	.S_AXI_AWLOCK(w_AXI_AWLOCK),
	// 	.S_AXI_AWCACHE(w_AXI_AWCACHE),
	// 	.S_AXI_AWPROT(w_AXI_AWPROT),
	// 	.S_AXI_AWQOS(w_AXI_AWQOS),
	// 	.S_AXI_AWREGION(w_AXI_AWREGION),
	// 	.S_AXI_AWUSER(w_AXI_AWUSER),
	// 	.S_AXI_AWVALID(w_AXI_AWVALID),
	// 	.S_AXI_AWREADY(w_AXI_AWREADY),
	// 	.S_AXI_WDATA(w_AXI_WDATA),
	// 	.S_AXI_WSTRB(w_AXI_WSTRB),
	// 	.S_AXI_WLAST(w_AXI_WLAST),
	// 	.S_AXI_WUSER(w_AXI_WUSER),
	// 	.S_AXI_WVALID(w_AXI_WVALID),
	// 	.S_AXI_WREADY(w_AXI_WREADY),
	// 	.S_AXI_BID(w_AXI_BID),
	// 	.S_AXI_BRESP(w_AXI_BRESP),
	// 	.S_AXI_BUSER(w_AXI_BUSER),
	// 	.S_AXI_BVALID(w_AXI_BVALID),
	// 	.S_AXI_BREADY(w_AXI_BREADY),
	// 	.S_AXI_ARID(w_AXI_ARID),
	// 	.S_AXI_ARADDR(w_AXI_ARADDR),
	// 	.S_AXI_ARLEN(w_AXI_ARLEN),
	// 	.S_AXI_ARSIZE(w_AXI_ARSIZE),
	// 	.S_AXI_ARBURST(w_AXI_ARBURST),
	// 	.S_AXI_ARLOCK(w_AXI_ARLOCK),
	// 	.S_AXI_ARCACHE(w_AXI_ARCACHE),
	// 	.S_AXI_ARPROT(w_AXI_ARPROT),
	// 	.S_AXI_ARQOS(w_AXI_ARQOS),
	// 	.S_AXI_ARREGION(w_AXI_ARREGION),
	// 	.S_AXI_ARUSER(w_AXI_ARUSER),
	// 	.S_AXI_ARVALID(w_AXI_ARVALID),
	// 	.S_AXI_ARREADY(w_AXI_ARREADY),
	// 	.S_AXI_RID(w_AXI_RID),
	// 	.S_AXI_RDATA(w_AXI_RDATA),
	// 	.S_AXI_RRESP(w_AXI_RRESP),
	// 	.S_AXI_RLAST(w_AXI_RLAST),
	// 	.S_AXI_RUSER(w_AXI_RUSER),
	// 	.S_AXI_RVALID(w_AXI_RVALID),
	// 	.S_AXI_RREADY(w_AXI_RREADY)
	// );




	blk_mem_gen_0 blk_mem_gen_0_inst(
	  .s_aclk(clk),
	  .s_aresetn(reset_n),

	  .s_axi_awid(w_AXI_AWID),
	  .s_axi_awaddr(w_AXI_AWADDR),
	  .s_axi_awlen(w_AXI_AWLEN),
	  .s_axi_awsize(w_AXI_AWSIZE),
	  .s_axi_awburst(w_AXI_AWBURST),
	  .s_axi_awvalid(w_AXI_AWVALID),
	  .s_axi_awready(w_AXI_AWREADY),

	  .s_axi_wdata(w_AXI_WDATA),
	  .s_axi_wstrb(w_AXI_WSTRB),
	  .s_axi_wlast(w_AXI_WLAST),
	  .s_axi_wvalid(w_AXI_WVALID),
	  .s_axi_wready(w_AXI_WREADY),

	  .s_axi_bid(w_AXI_BID),
	  .s_axi_bresp(w_AXI_BRESP),
	  .s_axi_bvalid(w_AXI_BVALID),
	  .s_axi_bready(w_AXI_BREADY),

	  .s_axi_arid(w_AXI_ARID),
	  .s_axi_araddr(w_AXI_ARADDR),
	  .s_axi_arlen(w_AXI_ARLEN),
	  .s_axi_arsize(w_AXI_ARSIZE),
	  .s_axi_arburst(w_AXI_ARBURST),
	  .s_axi_arvalid(w_AXI_ARVALID),
	  .s_axi_arready(w_AXI_ARREADY),

	  .s_axi_rid(w_AXI_RID),
	  .s_axi_rdata(w_AXI_RDATA),
	  .s_axi_rresp(w_AXI_RRESP),
	  .s_axi_rlast(w_AXI_RLAST),
	  .s_axi_rvalid(w_AXI_RVALID),
	  .s_axi_rready(w_AXI_RREADY)
);



	input_layer  #(

        .C_S_AXI_ID_WIDTH(3),
        .C_S_AXI_ADDR_WIDTH(32),
        .C_S_AXI_DATA_WIDTH(64),
        .C_S_AXI_BURST_LEN(8),
        .STREAM_DATA_WIDTH(72)
             
    ) input_layer_inst (
	// parameters from axi_lite
	        .Start(Start),
			.axi_address(32'hFF0),
			.larger_block_en(0),
			.allocated_space_per_row(16),
			.stride2en(0),
			.burst_per_row(1),
			.read_burst_len(1),
			.no_of_input_layers(16),
			.input_layer_row_size(13),
			.input_layer_col_size(13),
			.in_layer_ddr3_data_rdy(1'b1),
			.input_layer_1_data(data_o),
			.input_layer_1_valid(valid_o),
			.input_layer_1_rdy(w_input_layer_1_rdy), 
			.input_layer_1_id(), 


			.clk(clk),				
    		.reset_n(reset_n),
			.M_axi_awid(w_AXI_AWID), 	
			.M_axi_awaddr(w_AXI_AWADDR),	
			.M_axi_awlen(w_AXI_AWLEN),	
			.M_axi_awsize(w_AXI_AWSIZE), 	
			.M_axi_awburst(w_AXI_AWBURST),   
			.M_axi_awlock(w_AXI_AWLOCK),	
			.M_axi_awcache(w_AXI_AWCACHE), 	
			.M_axi_awprot(w_AXI_AWPROT), 	
    		.M_axi_awqos(w_AXI_AWQOS), 	
			.M_axi_awvalid(w_AXI_AWVALID),	
			.M_axi_awready(w_AXI_AWREADY), 	

	// AXI Write Data Control Signals
			.M_axi_wdata(w_AXI_WDATA),		
			.M_axi_wstrb(w_AXI_WSTRB),		
			.M_axi_wlast(w_AXI_WLAST),		
			.M_axi_wvalid(w_AXI_WVALID),		
			.M_axi_wready(w_AXI_WREADY),		

	// AXI Response Control Signals
			.M_axi_bid(w_AXI_BID), 			
			.M_axi_bresp(w_AXI_BRESP),		
			.M_axi_bvalid(w_AXI_BVALID), 		
			.M_axi_bready(w_AXI_BREADY),		

	// AXI Read Address Control Signals
			.M_axi_arid(w_AXI_ARID), 		
			.M_axi_araddr(w_AXI_ARADDR), 		
			.M_axi_arlen(w_AXI_ARLEN), 		
			.M_axi_arsize(w_AXI_ARSIZE), 		
			.M_axi_arburst(w_AXI_ARBURST), 		
			.M_axi_arlock(w_AXI_ARLOCK), 		
			.M_axi_arcache(w_AXI_ARCACHE), 		
			.M_axi_arprot(w_AXI_ARPROT), 		
			.M_axi_arqos(w_AXI_ARQOS),		
			.M_axi_arvalid(w_AXI_ARVALID),		
			.M_axi_arready(w_AXI_ARREADY),		

	// AXI Read Data Control Signals
			.M_axi_rid(w_AXI_RID), 			
			.M_axi_rdata(w_AXI_RDATA),		
			.M_axi_rresp(w_AXI_RRESP),		
    		.M_axi_rlast(w_AXI_RLAST),		
			.M_axi_rvalid(w_AXI_RVALID),		
			.M_axi_rready(w_AXI_RREADY)		
	);
	

    always #5 clk = ~clk;

    integer f;
    initial begin
    	f = $fopen("/home/vasan/altera/AP85/output_files/output.txt","w");
        Start = 0;
    	clk = 0;
    	reset_n = 0;

    	#500
    	reset_n = 1;
    	Start = 1;
    	#10
    	Start = 0;
    	#10000000
    	$fclose(f);
    end


    wire [7:0] win_0_0 = data_o[55:48];
    wire [7:0] win_1_0 = data_o[63:56];
    wire [7:0] win_2_0 = data_o[71:64];

    wire [7:0] win_2_1 = data_o[47:40];
    wire [7:0] win_1_1 = data_o[39:32];
    wire [7:0] win_0_1 = data_o[31:24];

    wire [7:0] win_2_2 = data_o[23:16];
    wire [7:0] win_1_2 = data_o[15:8];
    wire [7:0] win_0_2 = data_o[7:0];

    reg[3:0] r_rand_number;
    reg r_ready;

    assign w_input_layer_1_rdy = (r_rand_number== 1 ? 1 : 0);
    always @(posedge clk) begin : proc_r_rand_number
    	if(~reset_n) begin
    		r_rand_number <= 0;
    	end else begin
    		r_rand_number <= $random%8;
    	end
    end

    always @(posedge clk) begin : proc_fwrite
    	if(reset_n & valid_o & w_input_layer_1_rdy) begin
    		$fwrite(f,"%d, %d, %d, %d, %d, %d, %d, %d, %d,\n", win_0_0, win_1_0, win_2_0, win_0_1, win_1_1, win_2_1, win_0_2, win_1_2, win_2_2);
    	end 
    end



endmodule