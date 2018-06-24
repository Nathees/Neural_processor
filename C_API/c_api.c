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
#define DDR3_SPAN            0x1000000


unsigned int calculate_axi_settings(unsigned int No_of_rows, unsigned int No_of_cols, unsigned char stride2en){


	unsigned int burst_per_row = (No_of_rows % 128 == 0 ? No_of_rows/128 : No_of_rows/128 + 1);
	unsigned int read_burst_len = No_of_rows > 64 ? 15 : 7;
	unsigned int allocated_space_per_row = (burst_per_row * (read_burst_len + 1) * 8) <= 64 ? 64 : 256;


	allocated_space_per_row = stride2en ? allocated_space_per_row * 2: allocated_space_per_row;


	unsigned int larger_block_en = (No_of_rows * No_of_cols > 4096 ? 1 : 0) ;
	unsigned int Record = (allocated_space_per_row & 0x0000ffff) | ((burst_per_row << 16) & 0x00ff0000) | ((read_burst_len << 28) & 0xf0000000) | (((unsigned int)stride2en << 25) & 0x02000000) | (((unsigned int)larger_block_en << 24) & 0x01000000);

	return Record;

}

int initialise_input_output_layer(unsigned char* lw_AXI_offset, unsigned short No_of_actual_input_rows, unsigned short No_of_actual_input_cols
		, unsigned short No_of_input_layers, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers
		, unsigned char* start_in_layer_axi_address, unsigned char max_pool_en, unsigned char avg_pool_en, unsigned char expand_en, unsigned char stride2en, unsigned char layer_ID
		, unsigned char* start_out_layer_axi_address, unsigned char * ddr3_offset, unsigned int ker_3x3_offset, unsigned int ker_1x1_offset, unsigned int exp_bias_offset, unsigned int sq_ker_offset,
		unsigned int sq_bias_offset) {




	//-----------------------------------------------------------------------
	//----------common parameters and input layer--------------------------
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
	unsigned char* reg_axi_address;

	//-----------------------------------------------------------------------
	//----------common paprameters and input layer--------------------------
	//-----------------------------------------------------------------------

	unsigned short No_of_input_rows = stride2en ? (No_of_actual_input_rows - 1)/2 : No_of_actual_input_rows;
	unsigned short no_of_input_cols = stride2en ? (No_of_actual_input_cols - 1)/2 : No_of_actual_input_cols;


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
	 	reg_axi_address = lw_AXI_offset + 16;
	 	memcpy(reg_axi_address, &Record, 4);
	 	printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);




	 // 0x0000000c -------        start of input layer axi address
	 //uintptr_t Record_ptr = (unsigned int) ;
		Record = (unsigned int) start_in_layer_axi_address - input_axi_shift;
		reg_axi_address = lw_AXI_offset + 12;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);







	//----------------------------------------------------------------------
	//-----------output layer parameters------------------------------------
	//----------------------------------------------------------------------


	 unsigned int No_of_output_Rows = max_pool_en ? (No_of_input_rows -1)/2 : No_of_input_rows;
	 No_of_output_Rows = avg_pool_en? 1 : No_of_output_Rows;
	 unsigned int No_of_output_Cols = max_pool_en ? (no_of_input_cols - 1)/2 : no_of_input_cols;
	 No_of_output_Cols = avg_pool_en ? No_of_squeeze_layers : No_of_output_Cols;
	 unsigned int No_output_layers = avg_pool_en ? 1 : No_of_squeeze_layers;




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
		reg_axi_address = lw_AXI_offset + 140;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);



	//----------------------------------------------------------------------
	//-----------FIRE Layer COnfiguration------------------------------------
	//----------------------------------------------------------------------


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


	// Squeeze repeat enable
		unsigned char squ_repeat_en = 0;
		if (No_of_expand_layers * No_of_squeeze_layers > 16384)
			squ_repeat_en = 1;
		else
			squ_repeat_en = 0;


//----------------------------------------------------------------------
//-----------Kernel loader parameters-----------------------------------
//----------------------------------------------------------------------

	// 0x00000020 ------- kernel0 settings        
		Record = 1;
		reg_axi_address = lw_AXI_offset + 0x20;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000024 ------- kernel0 - AXI address start        
		Record = (unsigned int)ddr3_offset + ker_3x3_offset;
		reg_axi_address = lw_AXI_offset + 0x24;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000028 ------- kernel0 -AXI end address 
		unsigned int ker_3x3_size =  9 * No_of_input_layers* No_of_expand_layers;       
		Record = (unsigned int)ddr3_offset + ker_3x3_offset + ker_3x3_size;
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
		Record = (unsigned int)ddr3_offset + ker_1x1_offset;
		reg_axi_address = lw_AXI_offset + 0x34;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000038 ------- kernel1 -AXI end address 
		unsigned int ker_1x1_size =  1 * No_of_input_layers* No_of_expand_layers;       
		Record = (unsigned int)ddr3_offset + ker_1x1_offset + ker_1x1_size;
		reg_axi_address = lw_AXI_offset + 0x38;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);



	// 0x00000040 ------- kernel2 settings 
		Record = 0;       
		reg_axi_address = lw_AXI_offset + 0x40;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000044 ------- kernel2 - AXI address start        
		Record = (unsigned int)ddr3_offset + exp_bias_offset;
		reg_axi_address = lw_AXI_offset + 0x44;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000048 ------- kernel2 -AXI end address 
		unsigned int bias_size =  2 *No_of_expand_layers;       
		Record = (unsigned int)ddr3_offset + exp_bias_offset + bias_size;
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
		Record = (unsigned int)ddr3_offset + sq_ker_offset;
		reg_axi_address = lw_AXI_offset + 0x54;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000058 ------- kernel4 -AXI end address 
		unsigned int sq_ker_size =  2 * No_of_expand_layers* No_of_squeeze_layers;       
		Record = (unsigned int)ddr3_offset + sq_ker_offset + sq_ker_size;
		reg_axi_address = lw_AXI_offset + 0x58;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);



	// 0x00000060 ------- kernel5 settings 
		Record = 0;       
		reg_axi_address = lw_AXI_offset + 0x60;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


	// 0x00000064 ------- kernel5 - AXI address start        
		Record = (unsigned int)ddr3_offset + sq_bias_offset;
		reg_axi_address = lw_AXI_offset + 0x64;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);

	// 0x00000068 ------- kernel5 -AXI end address       
		Record = (unsigned int)ddr3_offset + sq_bias_offset + No_of_squeeze_layers;
		reg_axi_address = lw_AXI_offset + 0x68;
		memcpy(reg_axi_address, &Record, 4);
		printf("\nReg Address:%x Value:%x", (unsigned int)reg_axi_address, Record);


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
          unsigned short in_row_size = 56;
          unsigned short in_col_size = 56;
          unsigned short no_of_input_layers = 16;
          unsigned short no_of_exp_kernels = 64;
          unsigned short no_of_squeeze_kernels = 16;
          unsigned char max_pool_en = 1;
          unsigned char avg_pool_en = 0;
          unsigned char exp_en = 1;
          unsigned char stride2en = 0;

          unsigned int kernel_0_offset = 0x80000;
          unsigned int kernel_1_offset = 0x110000;
          unsigned int kernel_2_offset = 0x114000;
          unsigned int kernel_3_offset = 0x115000;
          unsigned int kernel_4_offset = 0x125000;

          // calculated parameters
          unsigned short out_row_size =  stride2en ? (in_row_size - 1)/2 : in_row_size;
          out_row_size = max_pool_en ? (out_row_size-1)/2 : out_row_size;
          out_row_size = avg_pool_en ? 1 : out_row_size;
          unsigned short out_col_size = stride2en ? (in_col_size - 1)/2 : in_col_size;
          out_col_size = max_pool_en ? (out_col_size-1)/2 : out_col_size;
          out_col_size = avg_pool_en ? no_of_squeeze_kernels : out_col_size;
          unsigned short no_of_output_layers = avg_pool_en? 1 :no_of_squeeze_kernels;

          unsigned int in_layer_blk_size = in_row_size * in_col_size > 4096 ? 65536 : 4096;
          unsigned short allocated_space_per_row = in_row_size > 64 ? 256 : 64;

          unsigned int out_layer_blk_size = out_row_size * out_col_size > 4096 ? 65536 : 4096;
          unsigned short out_allocated_space_per_row = out_col_size > 64 ? 256 : 64;

          printf("\nin_layer_blk_size: %d", in_layer_blk_size);
          printf("\nin_allocated_space_per_row: %d", allocated_space_per_row);

          printf("\nout_layer_blk_size: %d", out_layer_blk_size);
          printf("\nout_allocated_space_per_row: %d", out_allocated_space_per_row);


          //Map LED_PIO Physical Address to Virtual Address Space
          lw_addr = mmap( NULL, REG_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, (ALT_LWFPGASLVS_OFST) );
          ddr3_common = mmap( NULL, DDR3_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, (ddr3_fpga) );


          // setting input layer
          FILE *f = fopen("input_layer_c.bin", "rb");
          for(k = 0; k < no_of_input_layers; k++){
			  for(i = 0; i < in_row_size; i++){
					  fread((ddr3_common+ k * in_layer_blk_size + (i * allocated_space_per_row)), 1, in_col_size, f);
			   }
          }
          fclose(f);


          f = fopen("ker_3x3.bin", "rb");
          unsigned int ker_3x3_size =  9 * no_of_input_layers* no_of_exp_kernels;
          fread(ddr3_common + kernel_0_offset, 1, ker_3x3_size ,f);
          fclose(f);

          f = fopen("ker_1x1.bin", "rb");
          unsigned int ker_1x1_size =  1 * no_of_input_layers* no_of_exp_kernels;
          fread(ddr3_common + kernel_1_offset, 1, ker_1x1_size, f);
          fclose(f);

          f = fopen("bias.bin", "rb");
          fread(ddr3_common + kernel_2_offset, 1, no_of_exp_kernels*2 ,f);
          fclose(f);

          f = fopen("sq_ker.bin", "rb");
          unsigned int sq_ker_size = 2*no_of_exp_kernels*no_of_squeeze_kernels;
          fread(ddr3_common + kernel_3_offset, 1, sq_ker_size,f);
          fclose(f);

          f = fopen("sq_bias.bin", "rb");
          unsigned int sq_bias_size = no_of_squeeze_kernels;
          fread(ddr3_common + kernel_4_offset, 1, sq_bias_size,f);
          fclose(f);

//          for(k = 0; k < 0x1000; k++){
//        	  *(ddr3_common+ 0x80000 + k) =  k%10;
//          }






          // common parameters
          unsigned int row_0 = 0x0003010d;
          unsigned int row_1 = 0x00380038;
          unsigned int row_2 = 0x00100040;
          unsigned int row_3 = 0x2FFFFFC0;
          unsigned int row_4 = 0x70010040;

          // kernel loader paramter
          unsigned int row_8 = 0x00000001;
          unsigned int row_9 =  0x30080000;
          unsigned int row_10 = 0x30082400;

          unsigned int row_12 = 0x00000000;
          unsigned int row_13 = 0x30083000;
          unsigned int row_14 = 0x30083400;

          unsigned int row_16 = 0x00000000;
          unsigned int row_17 = 0x30083500;
          unsigned int row_18 = 0x30083580;

          unsigned int row_20 = 0x00000000;
          unsigned int row_21 = 0x30084000;
          unsigned int row_22 = 0x30084800;

          unsigned int row_24 = 0x00000000;
          unsigned int row_25 = 0x30084900;
          unsigned int row_26 = 0x30084910;

          // output layer parameters
          unsigned int row_32 = 0x00000010;
          unsigned int row_33 = 0x00380038;
          unsigned int row_34 = 0x30040000;
          unsigned int row_35 = 0x70010040;

          // fire configuration
          unsigned int row_36 = 0x00370f10;
          unsigned int row_37 = 0x037f00ff;
          unsigned int row_38 = 0x0f202f0f;

          unsigned int row_39 = 0x01ae037e;

          unsigned int row_40 = 0x000800ff;

          unsigned int row_41 = 0x000f0380;

          unsigned int row_42 = 0x000f01bf;

          unsigned int row_43 = 0x00370040;

          // common parameter
//          memcpy(lw_addr+4, &row_1, 4);
//          memcpy(lw_addr+8, &row_2, 4);
//          memcpy(lw_addr+12, &row_3, 4);
//          memcpy(lw_addr+16, &row_4, 4);


         //  kernel loader
//          memcpy(lw_addr+32, &row_8, 4);
//          memcpy(lw_addr+36, &row_9, 4);
//          memcpy(lw_addr+40, &row_10, 4);
//
//          memcpy(lw_addr+48, &row_12, 4);
//          memcpy(lw_addr+52, &row_13, 4);
//          memcpy(lw_addr+56, &row_14, 4);
//
//          memcpy(lw_addr+64, &row_16, 4);
//          memcpy(lw_addr+68, &row_17, 4);
//          memcpy(lw_addr+72, &row_18, 4);
//
//          memcpy(lw_addr+80, &row_20, 4);
//          memcpy(lw_addr+84, &row_21, 4);
//          memcpy(lw_addr+88, &row_22, 4);
//
//          memcpy(lw_addr+96, &row_24, 4);
//          memcpy(lw_addr+100, &row_25, 4);
//          memcpy(lw_addr+104, &row_26, 4);


          //output layer
//          memcpy(lw_addr+128, &row_32, 4);
//          memcpy(lw_addr+132, &row_33, 4);
//          memcpy(lw_addr+136, &row_34, 4);
//          memcpy(lw_addr+140, &row_35, 4);

          // fire module
//          memcpy(lw_addr+144, &row_36, 4);
//          memcpy(lw_addr+148, &row_37, 4);
//          memcpy(lw_addr+152, &row_38, 4);
//          memcpy(lw_addr+156, &row_39, 4);
//          memcpy(lw_addr+160, &row_40, 4);
//          memcpy(lw_addr+164, &row_41, 4);
//          memcpy(lw_addr+168, &row_42, 4);
//          memcpy(lw_addr+172, &row_43, 4);

          initialise_input_output_layer(lw_addr, in_row_size, in_col_size
                    		, no_of_input_layers, no_of_exp_kernels, no_of_squeeze_kernels
                    		, (unsigned char*)0x30000000, max_pool_en, avg_pool_en, exp_en, stride2en, 5
                    		, (unsigned char*)(0x30000000 + 0x400000), (unsigned char*)0x30000000, kernel_0_offset, kernel_1_offset, kernel_2_offset, kernel_3_offset, kernel_4_offset );
          // issue start signal
//          memcpy(lw_addr+4, &row_1, 4);
          //memcpy(lw_addr, &row_0, 4);


          usleep(100000);
          printf("reading value in ddr3 output address space\n");
          //int i = 0;

          for(k = 0; k < no_of_output_layers; k++){
        	  printf("\nlayer id: %d\n", k);
			  for(i = 0; i < out_row_size; i++){
				  for(j = 0; j < out_col_size; j++){
					 printf("%d ", *(ddr3_common+ 0x400000 + out_layer_blk_size * k + (i * out_allocated_space_per_row) + j)) ;
				 }
				  printf("\n");
			  }
			  printf("\n");
          }

          munmap(lw_addr, REG_SPAN);
          munmap(ddr3_common, DDR3_SPAN);
          close(fd);
          return(0);
}

