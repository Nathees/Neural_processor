module mux_2 (
	input 		in1_i,
	input 		in2_i,
	input 		sel_i,
	output 		out_o
	);

	assign out_o = sel_i ? in2_i : in1_i;
	
endmodule // mux_2