`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2018 08:21:52 AM
// Design Name: 
// Module Name: window_3x3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//module window_3x3(
//	// trigger signal
//	input start,
//
//	// block ram interface
//	//output [0:0] ena,
//	//output [0:0] wea,
//	//input  [7:0] addra,
//	//output [63:0] dina,
//
//	output [0:0] enb,
//	output [7:0] addrb,
//	input  [63:0] doutb,
//
//	// output to processing
//	output [71:0] window_data,
//	output [0:0] window_valid,
//	input        window_ready
//
//    );
//
//
//	
//endmodule

module reg_fifo_16(

	input clk,
	input reset_n,
	input Start, 
	input one_row_complete,
	input stride2en,
	input [127:0] data_in,
	input [0:0] push,
	input [0:0] pop,
	output[47:0] data_o,
	output[3:0] count

	);

	reg [239:0] reg_file;
	reg [239:0] w_reg_file;
	reg [47:0] w_data_o;

	reg[3:0] r_ptr;
	reg[3:0] w_ptr;
	reg[3:0] r_count;

	wire [3:0] w_ptr_next = (w_ptr +8 >= 15) ?  w_ptr - 7 : w_ptr +8;
	wire [3:0] r_ptr_next_stride1 = (r_ptr +1 >= 15) ?  r_ptr -14 : r_ptr +1;
	wire [3:0] r_ptr_next_stride2 = (r_ptr +2 >= 15) ?  r_ptr -13 : r_ptr +2;

	wire [3:0] r_ptr_next = (stride2en ? r_ptr_next_stride2 : r_ptr_next_stride1);

    assign count =  r_count;

    wire can_be_popped = (r_count >= 3 ? 1 : 0);
    wire can_be_pushed = (r_count <= 7 ? 1 : 0);


    always@(posedge clk) begin
    	if(~reset_n | Start) begin
    		r_count <= 0;
    	end else if(one_row_complete) begin
    		r_count <= 0;
    	end else if(pop & can_be_popped & push & can_be_pushed) begin
    		r_count <=  (w_ptr_next >= r_ptr_next) ? w_ptr_next - r_ptr_next : 15- r_ptr_next + w_ptr_next;
    	end else if(pop & can_be_popped) begin
    		r_count <=  (w_ptr >= r_ptr_next) ? w_ptr - r_ptr_next : 15- r_ptr_next + w_ptr;
    	end else if(push & can_be_pushed) begin
    		r_count <=	(w_ptr_next >= r_ptr) ? w_ptr_next - r_ptr : 15- r_ptr + w_ptr_next;
    	end
    end


	always @(posedge clk) begin : proc_fifo_rpt
		if(~reset_n | Start) begin
			r_ptr <= 0;
		end else if(one_row_complete) begin
			r_ptr <= 0;
		end else if(pop & can_be_popped ) begin
			r_ptr <= r_ptr_next ;
		end
	end

	always @(posedge clk) begin : proc_fifo_wptr
		if(~reset_n) begin
			w_ptr <= 1;
		end else if((one_row_complete | Start) & stride2en) begin
			w_ptr <= 0;
		end else if((one_row_complete | Start)) begin
			w_ptr <= 1;
		end else if(push & can_be_pushed) begin
			w_ptr <= w_ptr_next; 
		end
	end

	always @(posedge clk) begin : proc_reg_file
		if(~reset_n || one_row_complete || Start) begin
			reg_file <= 0;
		end else if(push & can_be_pushed) begin
			reg_file <= w_reg_file;
		end
	end

	always @(*) begin : proc_write
		case(w_ptr)
			4'b0000: w_reg_file <= {reg_file[239:128], data_in[127:0]};
			4'b0001: w_reg_file <= {reg_file[239:144], data_in[127:0], reg_file[15:0]};
			4'b0010: w_reg_file <= {reg_file[239:160], data_in[127:0], reg_file[31:0]};
			4'b0011: w_reg_file <= {reg_file[239:176], data_in[127:0], reg_file[47:0]};
			4'b0100: w_reg_file <= {reg_file[239:192], data_in[127:0], reg_file[63:0]};
			4'b0101: w_reg_file <= {reg_file[239:208], data_in[127:0], reg_file[79:0]};
			4'b0110: w_reg_file <= {reg_file[239:224], data_in[127:0], reg_file[95:0]};
			4'b0111: w_reg_file <= {data_in[127:0], reg_file[111:0]};
			4'b1000: w_reg_file <= {data_in[111:0], reg_file[127:16], data_in[127:112]};
			4'b1001: w_reg_file <= {data_in[95:0], reg_file[143:32],  data_in[127:96]};
			4'b1010: w_reg_file <= {data_in[79:0], reg_file[159:48],  data_in[127:80]};
			4'b1011: w_reg_file <= {data_in[63:0], reg_file[175:64],  data_in[127:64]};
			4'b1100: w_reg_file <= {data_in[47:0], reg_file[191:80],  data_in[127:48]};
			4'b1101: w_reg_file <= {data_in[31:0], reg_file[207:96],  data_in[127:32]};
			4'b1110: w_reg_file <= {data_in[15:0], reg_file[223:112], data_in[127:16]};
			default : w_reg_file <= reg_file;
		endcase
	end


	always @(*) begin : proc_read
		case (r_ptr)
			4'b0000: w_data_o <= {reg_file[47:0]};
			4'b0001: w_data_o <= {reg_file[63:16]};
			4'b0010: w_data_o <= {reg_file[79:32]};
			4'b0011: w_data_o <= {reg_file[95:48]};
			4'b0100: w_data_o <= {reg_file[111:64]};
			4'b0101: w_data_o <= {reg_file[127:80]};
			4'b0110: w_data_o <= {reg_file[143:96]};
			4'b0111: w_data_o <= {reg_file[159:112]};
			4'b1000: w_data_o <= {reg_file[175:128]};
			4'b1001: w_data_o <= {reg_file[191:144]};
			4'b1010: w_data_o <= {reg_file[207:160]};
			4'b1011: w_data_o <= {reg_file[223:176]};
			4'b1100: w_data_o <= {reg_file[239:192]};
			4'b1101: w_data_o <= {reg_file[15:0], reg_file[239:208]};
			4'b1110: w_data_o <= {reg_file[31:0], reg_file[239:224]};
			default : w_data_o <= {reg_file[47:0]};
		endcase
	end

	assign data_o = w_data_o;
	

endmodule // reg_fifo