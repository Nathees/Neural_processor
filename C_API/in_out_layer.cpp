#include <iostream>
#include <string.h>
#include "in_out_layer.hpp"

#define debug_en 1

int initialise_input_output_layer(unsigned int* lw_AXI_offset, unsigned short No_of_input_rows, unsigned short no_of_input_cols
		, unsigned short No_of_input_layers, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers
		, unsigned int* start_in_layer_axi_address, bool max_pool_en, bool expand_en, bool stride2en, unsigned char layer_ID
		, unsigned int* start_out_layer_axi_address) {

	//-----------------------------------------------------------------------
	//----------common paprameters and input layer--------------------------
	//-----------------------------------------------------------------------

	// 0x00000000 ------- 		 (byte0[0] == Start processing), (byte0[1] = max_pool_en), ((byte0[2] = expand_en), ((byte0[3] = in_layer_ddr3_data_rdy), (byte1 = layer_ID) , (byte2, byte3 = No_of_input_layers)
	// 0x00000014 -------        (byte1, byte0 = No_of_rows), (byte3, byte2 = no_of_cols)
	// 0x00000008 -------        (byte0, byte1 == No_of_expand_layers), (byte2, byte3 = No_of_squeeze_layers)
	// 0x0000000c -------        start of input layer axi address
	// 0x00000010 -------        (byte01, byte0 = allocated_space_per_row), (byte2 = burst_per_row),  (byte3[7:4] = read_burst_len, byte3[25:24] = stride2en, larger_block_en)

	//----------------------------------------------------------------------
	//-----------output layer parameters------------------------------------
	//----------------------------------------------------------------------

	// 0x00000080 -------        (byte0, byte1 = No of output layers ) 
	// 0x00000084 -------        (byte0, byte1 = No_of_rows, byte2, byte3 = no_of_cols)
	// 0x00000088 -------        start of output layer axi address
	// 0x0000008c -------        (byte01, byte0 = out_allocated_space_per_row), (byte2 = out_burst_per_row),  (byte3[31:28] = write_burst_len, byte3[24:24] = larger_block_en)

	 
	unsigned int Record;
	unsigned int* reg_axi_address;

	//-----------------------------------------------------------------------
	//----------common paprameters and input layer--------------------------
	//-----------------------------------------------------------------------

	// 0x00000014 -------        (byte1, byte0 = No_of_rows), (byte3, byte2 = no_of_cols)
	 	Record = No_of_input_rows | (unsigned int) (no_of_input_cols << 16);
	 	reg_axi_address = lw_AXI_offset + 4;
	 	memcpy(reg_axi_address, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting Row_size: " << No_of_input_rows <<" Col_size: " << no_of_input_cols << " Record: " << Record << " Address: " << reg_axi_address << std::endl;
	 	#endif
	 	
	// 0x00000008 -------        (byte0, byte1 == No_of_expand_layers), (byte2, byte3 = No_of_squeeze_layers)
		Record = No_of_expand_layers | (unsigned int) (No_of_squeeze_layers << 16);
		reg_axi_address = lw_AXI_offset + 8;
	 	memcpy(reg_axi_address, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting No_of_expand_layers: " << No_of_expand_layers <<" No_of_squeeze_layers: " << No_of_squeeze_layers << " Record: " << Record << " Address: " << reg_axi_address << std::endl;
	 	#endif

	// 0x0000000c -------        start of input layer axi address
	 	Record = (unsigned int)start_in_layer_axi_address;
	 	reg_axi_address = lw_AXI_offset + 12;
	 	memcpy(lw_AXI_offset+12, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting start of input layer axi address: " << start_in_layer_axi_address  << " Record: "<< Record << " Address: " << reg_axi_address << std::endl;
	 	#endif

	// 0x00000010 -------        (byte01, byte0 = allocated_space_per_row), (byte2 = burst_per_row),  (byte3[7:4] = read_burst_len, byte3[25:24] = stride2en, larger_block_en)
	 	Record = calculate_axi_settings(No_of_input_rows, no_of_input_cols, stride2en);
	 	reg_axi_address = lw_AXI_offset + 16;
	 	memcpy(lw_AXI_offset+16, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting start of input layer axi configs: " << "(byte01, byte0 = allocated_space_per_row), (byte2 = burst_per_row),  (byte3[7:4] = read_burst_len, byte3[25:24] = stride2en, larger_block_en) "  << " Record: "<< Record << " Address: " << reg_axi_address << std::endl;
	 	#endif



	//----------------------------------------------------------------------
	//-----------output layer parameters------------------------------------
	//----------------------------------------------------------------------

	 unsigned int No_of_output_Rows = max_pool_en ? No_of_input_rows/2 + 1 : No_of_input_rows;
	 unsigned int No_of_output_Cols = max_pool_en ? no_of_input_cols/2 + 1 : no_of_input_cols;
	 unsigned int No_output_layers = No_of_squeeze_layers;

	// 0x00000080 -------        (byte0, byte1 = No of output layers )
	 	Record = No_output_layers;
	 	reg_axi_address = lw_AXI_offset + 128;
	 	memcpy(lw_AXI_offset+128, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting No_output_layers: " << No_output_layers  << " Record: "<< Record << " Address: " << reg_axi_address << std::endl;
	 	#endif

	// 0x00000084 -------        (byte0, byte1 = No_of_rows, byte2, byte3 = no_of_cols)
	 	Record = No_of_output_Rows | (unsigned int) (No_of_output_Cols << 16);
	 	reg_axi_address = lw_AXI_offset + 132;
	 	memcpy(lw_AXI_offset+132, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting No_of_output_Rows: " << No_of_output_Rows  <<" No_of_output_Cols: " << No_of_output_Cols <<  " Record: "<< Record << " Address: " << reg_axi_address << std::endl;
	 	#endif

	// 0x00000088 -------        start of output layer axi address
	 	Record = (unsigned int)start_out_layer_axi_address;
	 	reg_axi_address = lw_AXI_offset + 136;
	 	memcpy(lw_AXI_offset+136, &Record, 4);
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting start of output layer axi address: " << start_out_layer_axi_address  << " Record: "<< Record << " Address: " << reg_axi_address << std::endl;
	 	#endif

	// 0x0000008c -------        (byte01, byte0 = out_allocated_space_per_row), (byte2 = out_burst_per_row),  (byte3[31:28] = write_burst_len, byte3[24:24] = larger_block_en)
		Record = calculate_axi_settings(No_of_output_Rows, No_of_output_Cols, 0);
		reg_axi_address = lw_AXI_offset + 140;
	 	memcpy(lw_AXI_offset+136, &Record, 4);	
	 	#ifdef debug_en
	 		std::cout << std::hex << "\nSetting start of input layer axi configs: " << "(byte01, byte0 = out_allocated_space_per_row), (byte2 = out_burst_per_row),  (byte3[31:28] = write_burst_len, byte3[24:24] = larger_block_en) "  << " Record: "<< Record << " Address: " << reg_axi_address << std::endl;
	 	#endif

	 	 	
}

unsigned int calculate_axi_settings(unsigned short No_of_rows, unsigned short No_of_cols, bool stride2en){
	unsigned int No_of_eight_byte_blks = (No_of_rows % 8 == 0 ? No_of_rows/8 : (No_of_rows/8) + 1); 
	unsigned int burst_per_row = (No_of_eight_byte_blks > 16) ? (No_of_eight_byte_blks % 16 == 0 ? No_of_eight_byte_blks/16 : No_of_eight_byte_blks/16 + 1) : 1;
	unsigned int read_burst_len = (No_of_eight_byte_blks > 16) ? 16 : No_of_eight_byte_blks - 1;
	unsigned int allocated_space_per_row = burst_per_row * (read_burst_len + 1) * 8;
	unsigned int larger_block_en = (No_of_rows * No_of_cols > 4096 ? 1 : 0) ;

	unsigned int Record = (allocated_space_per_row & 0x0000ffff) | ((burst_per_row << 16) & 0x00ff0000) | ((read_burst_len << 28) & 0xf0000000) | (((unsigned int)stride2en << 25) & 0x02000000) | (((unsigned int)larger_block_en << 24) & 0x02000000);

	return Record;

}


int main(int argc, char const *argv[])
{
	/* code */
	initialise_input_output_layer(0x02000000, 56, 56
		, 64, 64, 64
		, 0xf0000000, 0, 1, 0, 2
		, 0xff000000);
	return 0;
}