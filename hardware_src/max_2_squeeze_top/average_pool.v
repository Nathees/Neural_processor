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

module average_pool(
	clk_i,
	rst_n_i,

	start_i,
	avg_en_i,
	layer_dim_i,
	classes_i,

	output_data_i,
	output_flag_i,
	output_fifo_busy_o,

	fifo_out_rd_data_o,
	fifo_out_rd_en_i,
	fifo_out_empty_o,
	fifo_out_data_count
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
	layer_dim_i 			:- [dimension - 1]
	classes_i 				:- [No of classes - 1]

	*/

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// COnfig Control Signals
	input 															start_i;
	input 															avg_en_i;
	input 				[4:0]										layer_dim_i;
	input 				[9:0]										classes_i;

	// Output Data COntrol Signals
	input 		  		[11:0]										output_data_i;
	input 		 													output_flag_i;
	output 	reg  													output_fifo_busy_o;

	// Output FIFO Control Signals
	output 				[7:0] 										fifo_out_rd_data_o;
	input 															fifo_out_rd_en_i;
	output 															fifo_out_empty_o;
	output 				[9:0] 										fifo_out_data_count;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// Config Control Signals
	reg 															r_avg_en;
	reg 				[4:0] 										r_layer_dim;
	reg 				[9:0] 										r_no_of_classes;

	reg 				[4:0] 										r_col_count;
	reg 															r_class_flag;
	reg 				[9:0] 										r_class_count;
	reg 															r_row_flag;
	reg 				[4:0] 										r_row_count;

	/// COL Addition COntrol Signals
	wire 				[11:0] 										w_col_add_data_sum;
	reg 				[11:0] 										r_col_add_data_2;
	wire 															w_col_add_en;
	reg 				[3:0] 										r_col_add_out_flag_temp;
	reg 															r_col_add_out_flag;

	/// ROW Addition COntrol Signals
	wire 				[11:0] 										w_row_add_data;
	reg 				[2:0]										r_row_add_en_temp;
	reg 															r_row_add_en;
	reg 				[7:0] 										r_row_add_out_flag_temp;
	reg 															r_row_add_out_flag;
	reg 				[8:0]										r_last_row_flag_temp;
	reg 															r_last_row_flag;

	// Average FIFO COntrol Signals
	wire 				[11:0] 										w_avg_fifo_rd_data;
	reg 				[11:0] 										r_avg_fifo_rd_data;
	wire 															w_avg_fifo_rd_en;
	wire 															w_avg_fifo_wr_en;

	// Output FIFO Control Signals
	reg 				[7:0] 										r_out_fifo_wr_data;
	reg 															r_out_fifo_wr_en;
	
//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------

	// COnfig
	always @(posedge clk_i) begin : CONFIG
		if(~rst_n_i) begin
			r_avg_en 			<= 0;
			r_layer_dim 		<= 0;
			r_no_of_classes 	<= 0;
		end 
		else if(start_i) begin
			r_avg_en 			<= avg_en_i;
			r_layer_dim 		<= layer_dim_i[4:0];
			r_no_of_classes 	<= classes_i;
		end
	end

	// Col Count
	always @(posedge clk_i) begin : COL_COUNT
		if(~rst_n_i || start_i) begin
			r_col_count <= 0;
		end 
		else if(output_flag_i && r_col_count == r_layer_dim) begin
			r_col_count <= 0;
		end
		else if(output_flag_i) begin
			r_col_count <= r_col_count + 1;
		end
	end

	// Class flag
	always @(posedge clk_i) begin : CLASS_FLAG
		if(~rst_n_i || start_i) begin
			r_class_flag <= 0;
		end else begin
			r_class_flag <= (output_flag_i && r_col_count == r_layer_dim);
		end
	end

	// Class Count
	always @(posedge clk_i) begin : CLASS_COUNT
		if(~rst_n_i || start_i) begin
			r_class_count <= 0;
		end 
		else if(r_class_flag && r_class_count == r_no_of_classes) begin
			r_class_count <= 0;
		end 
		else if(r_class_flag) begin
			r_class_count <= r_class_count + 1;
		end
	end

	// Row flag
	always @(posedge clk_i) begin : ROW_FLAG
		if(~rst_n_i || start_i) begin
			r_row_flag <= 0;
		end else begin
			r_row_flag <= (r_class_flag && r_class_count == r_no_of_classes);
		end
	end

	// Row Count
	always @(posedge clk_i) begin : ROW_COUNT
		if(~rst_n_i || start_i) begin
			r_row_count <= 0;
		end 
		else if(r_row_flag && r_row_count == r_layer_dim) begin
			r_row_count <= 0;
		end
		else if(r_row_flag) begin
			r_row_count <= r_row_count + 1;
		end
	end

	// Column Add enable
	assign w_col_add_en = (output_flag_i && r_col_count != 0);

	// Column Add out flag
	always @(posedge clk_i) begin : COL_ADD_OUT_FLAG
		if(~rst_n_i || start_i) begin
			r_col_add_out_flag_temp 		<= 0;
			r_col_add_out_flag 				<= 0;
		end else begin
			r_col_add_out_flag_temp[0:0]	<= output_flag_i;
			r_col_add_out_flag_temp[1:1]	<= r_col_add_out_flag_temp[0:0];
			r_col_add_out_flag_temp[2:2]	<= r_col_add_out_flag_temp[1:1];
			r_col_add_out_flag_temp[3:3]	<= r_col_add_out_flag_temp[2:2];
			r_col_add_out_flag 				<= r_col_add_out_flag_temp[3:3];
		end
	end

	// Column Add Input 2 
	always @(posedge clk_i) begin : COL_ADD_DATA_2
		if(~rst_n_i) begin
			r_col_add_data_2 <= 0;
		end 
		else if(r_col_add_out_flag) begin
			r_col_add_data_2 <= w_col_add_data_sum;
		end
	end

	// Average FIFO Read enable
	assign w_avg_fifo_rd_en = (r_class_flag && r_row_count != 0);  // ***************** mistake

	// Average FIFO Read Data
	always @(posedge clk_i) begin : AVG_FIFO_RD_DATA
		if(~rst_n_i) begin
			r_avg_fifo_rd_data <= 0;
		end else begin
			r_avg_fifo_rd_data <= w_avg_fifo_rd_data;
		end
	end

	// Row Add enable
	always @(posedge clk_i) begin : ROW_ADD_EN
		if(~rst_n_i || start_i) begin
			r_row_add_en_temp 		<= 0;
			r_row_add_en 			<= 0;
		end else begin
			r_row_add_en_temp[0:0] 	<= (r_class_flag && r_row_count != 0);
			r_row_add_en_temp[1:1] 	<= r_row_add_en_temp[0:0];
			r_row_add_en_temp[2:2] 	<= r_row_add_en_temp[1:1];
			r_row_add_en 			<= r_row_add_en_temp[2:2];
		end
	end

	// Row Add out flag
	always @(posedge clk_i) begin : ROW_ADD_OUT_FLAG
		if(~rst_n_i || start_i) begin
			r_row_add_out_flag_temp 		<= 0;
			r_row_add_out_flag 				<= 0;
		end else begin
			r_row_add_out_flag_temp[0:0]	<= r_class_flag;
			r_row_add_out_flag_temp[1:1]	<= r_row_add_out_flag_temp[0:0];
			r_row_add_out_flag_temp[2:2]	<= r_row_add_out_flag_temp[1:1];
			r_row_add_out_flag_temp[3:3]	<= r_row_add_out_flag_temp[2:2];
			r_row_add_out_flag_temp[4:4]	<= r_row_add_out_flag_temp[3:3];
			r_row_add_out_flag_temp[5:5]	<= r_row_add_out_flag_temp[4:4];
			r_row_add_out_flag_temp[6:6]	<= r_row_add_out_flag_temp[5:5];
			r_row_add_out_flag_temp[7:7]	<= r_row_add_out_flag_temp[6:6];
			r_row_add_out_flag 				<= r_row_add_out_flag_temp[7:7];
		end
	end
	
	// Average FIFO Write Enable
	assign w_avg_fifo_wr_en =  r_row_add_out_flag;

	// Last Row flag
	always @(posedge clk_i) begin : LAST_ROW_FLAG_TEMP
		if(~rst_n_i || start_i) begin
			r_last_row_flag_temp[0:0] <= 0;
		end 
		else if(r_row_flag && r_row_count == r_layer_dim - 1) begin
			r_last_row_flag_temp[0:0] <= 1;
		end
	end
	always @(posedge clk_i) begin : LAST_ROW_FLAG // ***************** doubt
		if(~rst_n_i || start_i) begin
			r_last_row_flag_temp[6:1] 	<= 0;
			r_last_row_flag 			<= 0;
		end 
		else begin
			r_last_row_flag_temp[1:1] 	<= r_last_row_flag_temp[0:0];
			r_last_row_flag_temp[2:2] 	<= r_last_row_flag_temp[1:1];
			r_last_row_flag_temp[3:3] 	<= r_last_row_flag_temp[2:2];
			r_last_row_flag_temp[4:4] 	<= r_last_row_flag_temp[3:3];
			r_last_row_flag_temp[5:5] 	<= r_last_row_flag_temp[4:4];
			r_last_row_flag_temp[6:6] 	<= r_last_row_flag_temp[5:5];
			r_last_row_flag_temp[7:7] 	<= r_last_row_flag_temp[6:6];
			r_last_row_flag_temp[8:8] 	<= r_last_row_flag_temp[7:7];
			r_last_row_flag 			<= r_last_row_flag_temp[8:8];
		end
	end

	// Output FIFO Write data

	wire [7:0] w_row_add_data_rounded;
	wire [7:0] output_data_i_rounded;

	assign w_row_add_data_rounded = w_row_add_data[10:3] == 8'hff ? w_row_add_data[10:3] : w_row_add_data[10:3] + 1;
	assign output_data_i_rounded = output_data_i[10:3] == 8'hff ? output_data_i[10:3] : output_data_i[10:3] + 1;
	always @(posedge clk_i) begin : OUT_FIFO_WR_DATA
		if(~rst_n_i) begin
			r_out_fifo_wr_data <= 0;
		end 
		else if(r_avg_en) begin
			r_out_fifo_wr_data <= {w_row_add_data[11:11], w_row_add_data_rounded[7:1]}; //w_row_add_data[11:4];
		end
		else begin
			r_out_fifo_wr_data <= {output_data_i[11:11], output_data_i_rounded[7:1]}; //output_data_i[11:4];
		end
	end

	// Output FIFO write enable
	always @(posedge clk_i) begin : OUT_FIFO_WR_EN
		if(~rst_n_i || start_i) begin
			r_out_fifo_wr_en <= 0;
		end 
		else if(r_avg_en) begin
			r_out_fifo_wr_en <= (r_last_row_flag && r_row_add_out_flag);
		end
		else begin
			r_out_fifo_wr_en <= output_flag_i;
		end
	end

	// Output FIFO Busy
	always @(posedge clk_i) begin : OUT_FIFO_BUSY
		if(~rst_n_i || start_i) begin
			output_fifo_busy_o <= 0;
		end 
		else begin
			output_fifo_busy_o <= (fifo_out_data_count > 950);
		end
	end
	

	reg [15:0] r_out_count  /*synthesis noprune */;
	always @(posedge clk_i) begin 
		if(~rst_n_i || start_i) begin
			r_out_count <= 0;
		end else if(r_out_fifo_wr_en) begin
			r_out_count <= r_out_count + 1;
		end
	end
//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	// Output FIFO
	average_fifo average_fifo_inst
	(
		.clock 							(clk_i),
		.aclr 							(start_i),

		.data 							(w_row_add_data),
		.wrreq 							(w_avg_fifo_wr_en),
		.usedw 							(),

		.q 								(w_avg_fifo_rd_data),
		.rdreq 							(w_avg_fifo_rd_en),
		.empty 							()
	);

	// Col Addition
	add_en_12 temp_add_col_inst
	(
		.clk_i 							(clk_i),
		.rst_n_i 						(rst_n_i),

		.data_1_i 						(output_data_i),
		.data_2_i 						(r_col_add_data_2),
		.data_sum_o 					(w_col_add_data_sum),

		.add_en_i 						(w_col_add_en),
		.skip_neg_en_i 					(0)
	);

	// row Addition
	add_en_12 temp_add_row_inst
	(
		.clk_i 							(clk_i),
		.rst_n_i 						(rst_n_i),

		.data_1_i 						(w_col_add_data_sum),
		.data_2_i 						(r_avg_fifo_rd_data),
		.data_sum_o 					(w_row_add_data),

		.add_en_i 						(r_row_add_en),
		.skip_neg_en_i 					(0)
	);

	// Output FIFO
	output_fifo output_fifo_inst
	(
		.clock 							(clk_i),
		.aclr 							(start_i),

		.data 							(r_out_fifo_wr_data),
		.wrreq 							(r_out_fifo_wr_en),
		.usedw 							(fifo_out_data_count),

		.q 								(fifo_out_rd_data_o),
		.rdreq 							(fifo_out_rd_en_i),
		.empty 							(fifo_out_empty_o)
	);

endmodule

