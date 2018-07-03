#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
//#include "in_out_layer.h"

#define ALT_LWFPGASLVS_OFST 0xFF200000
#define ddr3_fpga 0x30000000
#define LED_PIO_BASE             0x3000
#define REG_SPAN            0x100
#define DDR3_SPAN            0xf000000


unsigned int calculate_axi_settings(unsigned int No_of_rows, unsigned int No_of_cols, unsigned char stride2en){


	unsigned int burst_per_row = (No_of_cols <= 128 ? 1 : (No_of_cols <= 256 ? 2 : No_of_cols/128 + 1));
	unsigned int read_burst_len = No_of_cols <= 16 ? 1 : (No_of_cols <= 32 ? 3 : (No_of_cols <= 64 ? 7 :(No_of_cols <= 128 ? 15 : 15)));
	unsigned int allocated_space_per_row = (burst_per_row * (read_burst_len + 1) * 8);

	allocated_space_per_row = stride2en ? allocated_space_per_row * 2: allocated_space_per_row;


	unsigned int larger_block_en = (No_of_rows * No_of_cols > 4096 ? 1 : 0) ;
	unsigned int Record = (allocated_space_per_row & 0x0000ffff) | ((burst_per_row << 16) & 0x00ff0000) | ((read_burst_len << 28) & 0xf0000000) | (((unsigned int)stride2en << 25) & 0x02000000) | (((unsigned int)larger_block_en << 24) & 0x01000000);

	return Record;

}


int  configure_common_params(unsigned char* lw_AXI_offset, unsigned short No_of_input_rows, unsigned short no_of_input_cols, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers, unsigned short No_of_actual_input_rows, unsigned short No_of_actual_input_cols, unsigned char stride2en, unsigned char* start_in_layer_axi_address, unsigned short* Input_row_space_){


	unsigned int Record;
	unsigned char* reg_axi_address;
	// 0x00000004 -------        (byte1, byte0 = No_of_rows), (byte3, byte2 = no_of_cols)
	 	Record = No_of_input_rows | (unsigned int) (no_of_input_cols << 16);
	 	reg_axi_address = lw_AXI_offset + 4;
	 	memcpy(reg_axi_address, &Record, 4);
	 	printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	// 0x00000008 -------        (byte0, byte1 == No_of_expand_layers), (byte2, byte3 = No_of_squeeze_layers)
		Record = No_of_expand_layers | (unsigned int) (No_of_squeeze_layers << 16);
		reg_axi_address = lw_AXI_offset + 8;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	// 0x00000010 -------        (byte01, byte0 = allocated_space_per_row), (byte2 = burst_per_row),  (byte3[7:4] = read_burst_len, byte3[25:24] = stride2en, larger_block_en)
	 	Record = calculate_axi_settings(No_of_actual_input_rows, No_of_actual_input_cols, stride2en);
	 	unsigned int input_axi_shift = stride2en ? 0 : Record & 0x0000ffff;
	 	*Input_row_space_ = input_axi_shift;
	 	reg_axi_address = lw_AXI_offset + 16;
	 	memcpy(reg_axi_address, &Record, 4);
	 	printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	 // 0x0000000c -------        start of input layer axi address
	 //uintptr_t Record_ptr = (unsigned int) ;
		Record = (unsigned int) start_in_layer_axi_address - input_axi_shift;
		reg_axi_address = lw_AXI_offset + 12;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

}

int configure_output_layer_params(unsigned char* lw_AXI_offset, unsigned short No_output_layers, unsigned short No_of_output_Rows, unsigned short No_of_output_Cols, unsigned char* start_out_layer_axi_address, unsigned short* Output_row_space_){


	unsigned int Record;
	unsigned char* reg_axi_address;

	// 0x00000080 -------        (byte0, byte1 = No of output layers )
	 	Record = No_output_layers;
	 	reg_axi_address = lw_AXI_offset + 128;
	 	memcpy(reg_axi_address, &Record, 4);
	 	printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	// 0x00000084 -------        (byte0, byte1 = No_of_rows, byte2, byte3 = no_of_cols)
	 	Record = No_of_output_Rows | (unsigned int) (No_of_output_Cols << 16);
	 	reg_axi_address = lw_AXI_offset + 132;
	 	memcpy(reg_axi_address, &Record, 4);
	 	printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	// 0x00000088 -------        start of output layer axi address
	 	Record = (unsigned int) start_out_layer_axi_address;
	 	reg_axi_address = lw_AXI_offset + 136;
	 	memcpy(reg_axi_address, &Record, 4);
	 	printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	// 0x0000008c -------        (byte01, byte0 = out_allocated_space_per_row), (byte2 = out_burst_per_row),  (byte3[31:28] = write_burst_len, byte3[24:24] = larger_block_en)
		Record = calculate_axi_settings(No_of_output_Rows, No_of_output_Cols, 0);
		*Output_row_space_ = Record & 0x0000ffff;
		reg_axi_address = lw_AXI_offset + 140;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);
}


int configure_fire(unsigned char* lw_AXI_offset, unsigned short No_of_input_layers, unsigned short No_of_input_rows, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers, unsigned char max_pool_en){

		unsigned char* reg_axi_address;
		unsigned int fire_config = 0;

		//Layer dimension after maxpool
		int max_dim = 0;
		if (No_of_input_rows % 2 == 0)
			max_dim = (No_of_input_rows >> 1) - 1;
		else
			max_dim = (No_of_input_rows >> 1);

		// Max Squeeze Kernel
		int max_squ_kernel = 0;
		if (No_of_expand_layers * No_of_squeeze_layers > 16384)
			if (16384 % No_of_expand_layers != 0)
				printf("config error in repeat squeeze kernel\n");
			else
				max_squ_kernel = 16384; // exp_kernal
		else
			max_squ_kernel = No_of_squeeze_layers;

		// Squeeze layer Input dimension
		int squ_dim = 0;
		if (max_pool_en)
			squ_dim = max_dim;
		else
			squ_dim = No_of_input_rows;

	// 	0x00000090
		reg_axi_address = lw_AXI_offset + 144;
		fire_config = (No_of_input_rows - 1) << 16;
		fire_config = fire_config + ((No_of_input_layers - 1) << 8);
		fire_config = fire_config + (unsigned int)(No_of_expand_layers / 4);
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


	// 	0x00000094
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 148;
		fire_config = (((No_of_input_rows * No_of_expand_layers) / 4 ) - 1) << 16;
		fire_config = fire_config + (((No_of_expand_layers * No_of_input_layers) / 4) - 1);
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


	// 	0x00000098
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 152;
		fire_config = ((No_of_expand_layers / 4 * 1) - 1) << 24;
		fire_config = fire_config + ((No_of_expand_layers / 4 * 2) << 16);
		fire_config = fire_config + (((No_of_expand_layers / 4 * 3) - 1) << 8);
		fire_config = fire_config + ((2 * No_of_expand_layers / 8) - 1);
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


	// 	0x0000009C
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 156;
		fire_config = ((max_dim * No_of_expand_layers / 4) - 2) << 16;
		fire_config = fire_config + ((No_of_input_rows * No_of_expand_layers / 4) - 2);
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


 	// 	0x000000A0
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 160;
		fire_config = (No_of_expand_layers / 8) << 16;
		fire_config = fire_config + ((No_of_squeeze_layers * 2 * No_of_expand_layers / 8) - 1);
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


	// 	0x000000A4
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 164;
		fire_config = (max_squ_kernel - 1) << 16;
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


	// 	0x000000A8
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 168;
		fire_config = (No_of_squeeze_layers - 1) << 16;
		fire_config = fire_config + ((squ_dim * No_of_expand_layers / 8) - 1);
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


	// 	0x000000AC
		fire_config = 0;
		reg_axi_address = lw_AXI_offset + 172;
		fire_config = (squ_dim - 1) << 16;
		fire_config = fire_config + No_of_expand_layers;
		memcpy(reg_axi_address, &fire_config, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, fire_config);


		return 0;

}

int configure_kernel_loader(unsigned short layer_ID, unsigned char* lw_AXI_offset, unsigned char*ddr3_offset, unsigned short No_of_input_layers, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers, unsigned int kernels_offset, unsigned int kernels_space,  unsigned int ker_3x3_offset, unsigned int ker_1x1_offset, unsigned int exp_bias_offset, unsigned int sq_ker_offset, unsigned int sq_bias_offset, unsigned char* squ_repeat_en_){

	unsigned int Record;
	unsigned char* reg_axi_address;

	// Squeeze repeat enable
		unsigned char squ_repeat_en = 0;
		if (No_of_expand_layers * No_of_squeeze_layers > 16384)
			squ_repeat_en = 1;
		else
			squ_repeat_en = 0;

		*squ_repeat_en_ = squ_repeat_en;

	// 0x00000020 ------- kernel0 settings        
		Record = 1;
		reg_axi_address = lw_AXI_offset + 0x20;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000024 ------- kernel0 - AXI address start        
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ ker_3x3_offset;
		reg_axi_address = lw_AXI_offset + 0x24;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000028 ------- kernel0 -AXI end address 
		unsigned int ker_3x3_size =  9 * No_of_input_layers* No_of_expand_layers;       
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ ker_3x3_offset + ker_3x3_size;
		reg_axi_address = lw_AXI_offset + 0x28;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	// 0x00000030 ------- kernel1 settings 
		Record = 0;       
//		if(expand_en == 0){
//			Record = Record | 0x2;
//		}
		reg_axi_address = lw_AXI_offset + 0x30;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000034 ------- kernel1 - AXI address start        
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ ker_1x1_offset;
		reg_axi_address = lw_AXI_offset + 0x34;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000038 ------- kernel1 -AXI end address 
		unsigned int ker_1x1_size =  1 * No_of_input_layers* No_of_expand_layers;       
		Record = (unsigned int)ddr3_offset + ker_1x1_offset + kernels_offset+ layer_ID * kernels_space+ ker_1x1_size;
		reg_axi_address = lw_AXI_offset + 0x38;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);



	// 0x00000040 ------- kernel2 settings 
		Record = 0;       
		reg_axi_address = lw_AXI_offset + 0x40;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000044 ------- kernel2 - AXI address start        
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ exp_bias_offset;
		reg_axi_address = lw_AXI_offset + 0x44;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000048 ------- kernel2 -AXI end address 
		unsigned int bias_size =  2 *No_of_expand_layers;       
		Record = (unsigned int)ddr3_offset + exp_bias_offset + kernels_offset+ layer_ID * kernels_space+ bias_size;
		reg_axi_address = lw_AXI_offset + 0x48;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);



	// 0x00000050 ------- kernel4 settings 
		if(squ_repeat_en){
			Record = 1; 
		} else {
			Record = 0;       
		}
		reg_axi_address = lw_AXI_offset + 0x50;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000054 ------- kernel4 - AXI address start        
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ sq_ker_offset;
		reg_axi_address = lw_AXI_offset + 0x54;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000058 ------- kernel4 -AXI end address 
		unsigned int sq_ker_size =  2 * No_of_expand_layers* No_of_squeeze_layers;       
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ sq_ker_offset + sq_ker_size;
		reg_axi_address = lw_AXI_offset + 0x58;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);



	// 0x00000060 ------- kernel5 settings 
		Record = 0;       
		reg_axi_address = lw_AXI_offset + 0x60;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000064 ------- kernel5 - AXI address start        
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ sq_bias_offset;
		reg_axi_address = lw_AXI_offset + 0x64;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000068 ------- kernel5 -AXI end address       
		Record = (unsigned int)ddr3_offset + kernels_offset+ layer_ID * kernels_space+ sq_bias_offset + No_of_squeeze_layers;
		reg_axi_address = lw_AXI_offset + 0x68;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

		return 0;
}



int set_weights_in_ddr3(unsigned short layer_ID, unsigned char* ddr3_common, unsigned short No_of_input_layers, unsigned short No_of_expand_kernels, unsigned short No_of_squeeze_kernels, unsigned int kernels_offset, unsigned int kernels_space, unsigned int kernel_0_offset,  unsigned int kernel_1_offset, unsigned int kernel_2_offset, unsigned int kernel_3_offset, unsigned int kernel_4_offset){

		char file_name[100];
		FILE * f;

		sprintf(file_name, "ker_3x3_%d.bin", layer_ID);
		f = fopen(file_name, "rb");
		if(f == NULL){
			printf("\nError: unable to open %s\n", file_name);
		} else {
			unsigned int ker_3x3_size =  9 * No_of_input_layers* No_of_expand_kernels;
			fread(ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_0_offset, 1, ker_3x3_size ,f);
			printf("\nCopying ker_3x3_%d.bin data at %x size: %x\n", layer_ID, ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_0_offset, ker_3x3_size);
			fclose(f);
		}

		sprintf(file_name, "ker_1x1_%d.bin", layer_ID);
		f = fopen(file_name, "rb");
		if(f == NULL){
			printf("Error: unable to open %s\n", file_name);
		} else {
			unsigned int ker_1x1_size =  1 * No_of_input_layers* No_of_expand_kernels;
			fread(ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_1_offset, 1, ker_1x1_size, f);
			printf("\nCopying ker_1x1_%d.bin data at %x size: %x\n", layer_ID, ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_1_offset, ker_1x1_size);
			fclose(f);
		}

		sprintf(file_name, "bias_%d.bin", layer_ID);
		f = fopen(file_name, "rb");
		if(f == NULL){
			printf("Error: unable to open %s\n", file_name);
		} else {
			fread(ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_2_offset, 1, No_of_expand_kernels*2 ,f);
			printf("\nCopying bias_%d.bin data at %x size: %x\n", layer_ID, ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_2_offset, No_of_expand_kernels*2);
			fclose(f);
		}

		sprintf(file_name, "sq_ker_%d.bin", layer_ID);
		f = fopen(file_name, "rb");
		if(f == NULL){
			printf("Error: unable to open %s\n", file_name);
		} else {
			unsigned int sq_ker_size = 2*No_of_expand_kernels * No_of_squeeze_kernels;
			fread(ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_3_offset, 1, sq_ker_size,f);
			printf("\nCopying sq_ker_%d.bin data at %x size: %x\n", layer_ID, ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_3_offset, sq_ker_size);
			fclose(f);
		}

		sprintf(file_name, "sq_bias_%d.bin", layer_ID);
		f = fopen(file_name, "rb");
		if(f == NULL){
			printf("Error: unable to open %s\n", file_name);
		} else {
			unsigned int sq_bias_size = No_of_squeeze_kernels;
			fread(ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_4_offset, 1, sq_bias_size,f);
			printf("\nCopying sq_bias_%d.bin data at %x size: %x\n", layer_ID, ddr3_common+ kernels_offset + kernels_space * layer_ID + kernel_4_offset, sq_bias_size);
			fclose(f);
		}
}




int initialise_and_start_coprocessor(unsigned char* lw_AXI_offset, unsigned short No_of_actual_input_rows, unsigned short No_of_actual_input_cols
		, unsigned short No_of_input_layers, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers
		, unsigned char* start_in_layer_axi_address, unsigned char max_pool_en, unsigned char avg_pool_en, unsigned char expand_en, unsigned char stride2en, unsigned char layer_ID
		, unsigned char* start_out_layer_axi_address, unsigned char * ddr3_offset, unsigned int kernels_offset, unsigned int kernels_space, unsigned int ker_3x3_offset, unsigned int ker_1x1_offset, unsigned int exp_bias_offset, unsigned int sq_ker_offset,
		unsigned int sq_bias_offset, unsigned short* No_of_output_layers, unsigned short* No_of_output_Rows_, unsigned short* No_of_output_Cols_, unsigned short* Input_row_space_, unsigned short* Output_row_space_ ) {


	unsigned int Record;
	unsigned char* reg_axi_address;
	unsigned char squ_repeat_en;

	//-----------------------------------------------------------------------
	//----------common paprameters and input layer--------------------------
	//-----------------------------------------------------------------------

	unsigned short No_of_input_rows = stride2en ? (No_of_actual_input_rows - 1)/2 : No_of_actual_input_rows;
	unsigned short No_of_input_cols = stride2en ? (No_of_actual_input_cols - 1)/2 : No_of_actual_input_cols;

	configure_common_params(lw_AXI_offset, No_of_input_rows, No_of_input_cols, No_of_expand_layers, No_of_squeeze_layers, No_of_actual_input_rows, No_of_actual_input_cols, stride2en, start_in_layer_axi_address, Input_row_space_);


	//----------------------------------------------------------------------
	//-----------output layer parameters------------------------------------
	//----------------------------------------------------------------------


	 unsigned int No_of_output_Rows = max_pool_en ? (No_of_input_rows -1)/2 : No_of_input_rows;
	 No_of_output_Rows = avg_pool_en? 1 : No_of_output_Rows;
	 *No_of_output_Rows_ = No_of_output_Rows;

	 unsigned int No_of_output_Cols = max_pool_en ? (No_of_input_cols - 1)/2 : No_of_input_cols;
	 No_of_output_Cols = avg_pool_en ? No_of_squeeze_layers : No_of_output_Cols;
	 *No_of_output_Cols_ = No_of_output_Cols;

	 unsigned int No_output_layers = avg_pool_en ? 1 : No_of_squeeze_layers;
	 *No_of_output_layers = No_output_layers;




	configure_output_layer_params(lw_AXI_offset, No_output_layers, No_of_output_Rows, No_of_output_Cols, start_out_layer_axi_address, Output_row_space_);



	//----------------------------------------------------------------------
	//-----------FIRE Layer COnfiguration------------------------------------
	//----------------------------------------------------------------------

	configure_fire(lw_AXI_offset, No_of_input_layers, No_of_input_rows, No_of_expand_layers, No_of_squeeze_layers, max_pool_en);

//----------------------------------------------------------------------
//-----------Kernel loader parameters-----------------------------------
//----------------------------------------------------------------------

	configure_kernel_loader(layer_ID, lw_AXI_offset, ddr3_offset, No_of_input_layers, No_of_expand_layers, No_of_squeeze_layers, kernels_offset, kernels_space, ker_3x3_offset, ker_1x1_offset, exp_bias_offset, sq_ker_offset, sq_bias_offset, &squ_repeat_en);


	//----------------------------------------------------------------------
	//-----------Start Signal-----------------------------------------------
	//----------------------------------------------------------------------

	// 0x00000000 ------- 		 (byte0[0] == Start processing), (byte0[1] = max_pool_en), ((byte0[2] = expand_en), ((byte0[3] = in_layer_ddr3_data_rdy), (byte1 = layer_ID) , (byte2, byte3 = No_of_input_layers)
		Record = ( 1 | (max_pool_en << 1) & 0x00000002) | ((expand_en << 2) & 0x00000004) | 0x00000008 | ((avg_pool_en <<5) &0x00000020)  | ((squ_repeat_en << 4) &0x00000010)  |((layer_ID << 8) & 0x0000ff00) | ((No_of_input_layers << 16) & 0xffff0000);
		reg_axi_address = lw_AXI_offset + 0;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);
		printf("\nIssuing start signal...\n");

	 	return 0;
}




int main(void)
{
          unsigned char *lw_addr, *ddr3_common;
          int fd;
          int i, j, k;

          fd = open("/dev/mem", (O_RDWR | O_SYNC));

          // layer parameters
          unsigned int No_of_Layers = 1; // 1 2 3 4 5 6 7 8 9
          unsigned int layer_ID = 0;
          unsigned short No_of_actual_input_rows = 27;
          unsigned short No_of_actual_input_cols = 27;
          unsigned short No_of_input_layers[10] = {32, 16, 16, 32, 32, 48, 48, 64, 64};
          unsigned short No_of_expand_kernels[10] = {128, 64,64, 128, 128, 192, 192, 256, 256};
          unsigned short No_of_squeeze_kernels[10] = {32, 16, 32, 32, 48, 48, 64, 64, 1000};
          unsigned char max_pool_en[10] = {0, 1, 0, 0, 1, 0, 0, 0, 0};
          unsigned char avg_pool_en[10] = {0, 0, 0, 0, 0, 0, 0, 0, 1};
          unsigned char expand_en[10] = {1, 1, 1, 1, 1, 1, 1, 1, 1};
          unsigned char stride2en[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0};


          unsigned int kernels_offset = 0x1000000;
          unsigned int kernels_space = 	0x100000;
          unsigned int kernel_0_offset = 0x000000;
          unsigned int kernel_1_offset = 0x050000;
          unsigned int kernel_2_offset = 0x060000;
          unsigned int kernel_3_offset = 0x061000;
          unsigned int kernel_4_offset = 0x0f0000;


          unsigned int output_layer_offset_one = 0x2000000;
          unsigned int output_layer_offset_two = 0x2100000;
          unsigned int output_layer_offset;
          unsigned int input_layer_offset;


          // calculated parameters
          unsigned short out_row_size;
          unsigned short out_col_size;
          unsigned short No_of_output_layers;

          unsigned short in_allocated_space_per_row = 32;
          unsigned short out_allocated_space_per_row;


          //Map LED_PIO Physical Address to Virtual Address Space
          lw_addr = mmap( NULL, REG_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, (ALT_LWFPGASLVS_OFST) );
          ddr3_common = mmap( NULL, DDR3_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, (ddr3_fpga) );

          unsigned short file_read_row_size = No_of_actual_input_cols % 4 == 0 ? No_of_actual_input_cols : (No_of_actual_input_cols/4 + 1) * 4;

          unsigned int in_layer_blk_size = No_of_actual_input_rows * No_of_actual_input_cols > 4096 ? 65536 : 4096;
          printf("\nin_layer_blk_size: %d", in_layer_blk_size);
          printf("\nin_allocated_space_per_row: %d", in_allocated_space_per_row);
          FILE *f = fopen("input_layer_c.bin", "rb");
			for(k = 0; k < No_of_input_layers[0]; k++){
			  for(i = 0; i < No_of_actual_input_rows; i++){
					  fread((ddr3_common+ k * in_layer_blk_size + (i * in_allocated_space_per_row)), 1, file_read_row_size, f);
			   }
			}
			fclose(f);

          // Initialising Kernel weights
		for(i = 0; i < No_of_Layers; i++){
			set_weights_in_ddr3(i, ddr3_common, No_of_input_layers[i], No_of_expand_kernels[i], No_of_squeeze_kernels[i], kernels_offset, kernels_space, kernel_0_offset, kernel_1_offset, kernel_2_offset, kernel_3_offset, kernel_4_offset);
		}


        // initialise_and_start_coprocessor(lw_addr, No_of_actual_input_rows, No_of_actual_input_cols, No_of_input_layers, No_of_expand_kernels, No_of_squeeze_kernels, ddr3_fpga, max_pool_en, avg_pool_en, expand_en, stride2en, layer_ID, ddr3_fpga+output_layer_offset_one, ddr3_fpga, kernels_offset, kernels_space, kernel_0_offset, kernel_1_offset, kernel_2_offset, kernel_3_offset, kernel_4_offset, &No_of_output_layers, &out_row_size, &out_col_size, &in_allocated_space_per_row, &out_allocated_space_per_row);

        // usleep(100000);


        printf("reading value in ddr3 output address space\n");
          //int i = 0;

        for(layer_ID = 0; layer_ID < No_of_Layers; layer_ID++){
        	if(layer_ID % 2 == 0){
        		output_layer_offset = output_layer_offset_one;
        	} else {
        		output_layer_offset = output_layer_offset_two;
        	}

        	if(layer_ID  == 0){
        		input_layer_offset = 0;
        	} else if(layer_ID % 2 == 0){
        		input_layer_offset = output_layer_offset_two;
        	} else {
        		input_layer_offset = output_layer_offset_one;
        	}
	        initialise_and_start_coprocessor(lw_addr, No_of_actual_input_rows, No_of_actual_input_cols, No_of_input_layers[layer_ID], No_of_expand_kernels[layer_ID], No_of_squeeze_kernels[layer_ID], ddr3_fpga + input_layer_offset, max_pool_en[layer_ID], avg_pool_en[layer_ID], expand_en[layer_ID], stride2en[layer_ID], layer_ID, ddr3_fpga+output_layer_offset, ddr3_fpga, kernels_offset, kernels_space, kernel_0_offset, kernel_1_offset, kernel_2_offset, kernel_3_offset, kernel_4_offset, &No_of_output_layers, &out_row_size, &out_col_size, &in_allocated_space_per_row, &out_allocated_space_per_row);

	        No_of_actual_input_rows = out_row_size;
	        No_of_actual_input_cols = out_col_size;
	        //No_of_input_layers = No_of_squeeze_kernels[i];

	        usleep(100000);
	        printf("reading value in ddr3 output address space\n");
		    unsigned int out_layer_blk_size = out_row_size * out_col_size > 4096 ? 65536 : 4096;
		    printf("\n####################################################################\n");
		    printf("######################## FIRE %d ##############################\n", layer_ID);
		    printf("##################################################################");
		    printf("\nout_layer_blk_size: %d", out_layer_blk_size);
		    printf("\nout_allocated_space_per_row: %d", out_allocated_space_per_row);
		    for(k = 0; k < No_of_output_layers; k++){
		    	printf("\nlayer id: %d\n", k);
				for(i = 0; i < out_row_size; i++){
					for(j = 0; j < out_col_size; j++){
						 //printf("Reading from address:%d\n", (ddr3_common+ output_layer_offset_one + out_layer_blk_size * k + (i * out_allocated_space_per_row) + j));
						printf("%d ", *(ddr3_common+ output_layer_offset + out_layer_blk_size * k + (i * out_allocated_space_per_row) + j)) ;
					}
					  printf("\n");
				}
				  printf("\n");
		    }
		}

          munmap(lw_addr, REG_SPAN);
          munmap(ddr3_common, DDR3_SPAN);
          close(fd);
          return(0);
}


