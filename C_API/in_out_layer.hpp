#include<iostream>

int initialise_input_output_layer(unsigned int lw_AXI_offset, unsigned short No_of_input_rows, unsigned short no_of_input_cols
		, unsigned short No_of_input_layers, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers
		, unsigned int start_in_layer_axi_address, bool max_pool_en, bool expand_en, bool stride2en, unsigned char layer_ID
		, unsigned int start_out_layer_axi_address);
unsigned int calculate_axi_settings(unsigned short No_of_rows, unsigned short No_of_cols, bool stride2en);