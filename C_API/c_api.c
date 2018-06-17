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
	unsigned int No_of_eight_byte_blks = (No_of_rows % 8 == 0 ? No_of_rows/8 : (No_of_rows/8) + 1);
	//unsigned int burst_per_row = (No_of_eight_byte_blks > 16) ? (No_of_eight_byte_blks % 16 == 0 ? No_of_eight_byte_blks/16 : No_of_eight_byte_blks/16 + 1) : 1;
	unsigned int burst_per_row = (No_of_rows % 128 == 0 ? No_of_rows/128 : No_of_rows/128 + 1);
	unsigned int read_burst_len = No_of_rows > 64 ? 15 : 7;//(No_of_eight_byte_blks > 16) ? 16 : No_of_eight_byte_blks - 1;
	unsigned int allocated_space_per_row = (burst_per_row * (read_burst_len + 1) * 8) <= 64 ? 64 : 256;
	allocated_space_per_row = stride2en ? allocated_space_per_row * 2: allocated_space_per_row;
	unsigned int larger_block_en = (No_of_rows * No_of_cols > 4096 ? 1 : 0) ;

	unsigned int Record = (allocated_space_per_row & 0x0000ffff) | ((burst_per_row << 16) & 0x00ff0000) | ((read_burst_len << 28) & 0xf0000000) | (((unsigned int)stride2en << 25) & 0x02000000) | (((unsigned int)larger_block_en << 24) & 0x01000000);

	return Record;

}

int initialise_input_output_layer(unsigned char* lw_AXI_offset, unsigned short No_of_actual_input_rows, unsigned short No_of_actual_input_cols
		, unsigned short No_of_input_layers, unsigned short No_of_expand_layers, unsigned short No_of_squeeze_layers
		, unsigned char* start_in_layer_axi_address, unsigned char max_pool_en, unsigned char expand_en, unsigned char stride2en, unsigned char layer_ID
		, unsigned char* start_out_layer_axi_address) {

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

	unsigned short No_of_input_rows = stride2en ? No_of_actual_input_rows/2 : No_of_actual_input_rows;
	unsigned short no_of_input_cols = stride2en ? No_of_actual_input_cols/2 : No_of_actual_input_cols;


	// 0x00000014 -------        (byte1, byte0 = No_of_rows), (byte3, byte2 = no_of_cols)
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

	 unsigned int No_of_output_Rows = max_pool_en ? No_of_input_rows/2 + 1 : No_of_input_rows;
	 unsigned int No_of_output_Cols = max_pool_en ? no_of_input_cols/2 + 1 : no_of_input_cols;
	 unsigned int No_output_layers = No_of_squeeze_layers;

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



	// 0x00000000 ------- 		 (byte0[0] == Start processing), (byte0[1] = max_pool_en), ((byte0[2] = expand_en), ((byte0[3] = in_layer_ddr3_data_rdy), (byte1 = layer_ID) , (byte2, byte3 = No_of_input_layers)
		Record = ( 1 | (max_pool_en << 1) & 0x00000002) | ((expand_en << 2) & 0x00000004) | 0x00000008 | ((layer_ID << 8) & 0x0000ff00) | ((No_of_input_layers << 16) & 0xffff0000);
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

          //Map LED_PIO Physical Address to Virtual Address Space
          lw_addr = mmap( NULL, REG_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, (ALT_LWFPGASLVS_OFST) );


          ddr3_common = mmap( NULL, DDR3_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, (ddr3_fpga) );

         // FILE *f = fopen("input_layer_c.bin", "rb");
          for(k = 0; k < 200; k++){
			  for(i = 0; i < 3; i++){
				  for(j = 0; j < 3; j++){
					  *(ddr3_common+ k * 4096 + (i * 64) + j) = i+j+k+4;
				  }
			   }
          }
//          fclose(f);
//          f = fopen("ker_3x3.bin", "rb");
//          fread(ddr3_common + 0x80000, 1, 0x2400,f);
//          fclose(f);
//
//          f = fopen("ker_1x1.bin", "rb");
//          fread(ddr3_common + 0x83000, 1, 0x400,f);
//          fclose(f);
//
//          f = fopen("bias.bin", "rb");
//          fread(ddr3_common + 0x83500, 1, 0x80,f);
//          fclose(f);
//
//          f = fopen("sq_ker.bin", "rb");
//          fread(ddr3_common + 0x84000, 1, 0x800,f);
//          fclose(f);
//
//          f = fopen("sq_bias.bin", "rb");
//          fread(ddr3_common + 0x84900, 1, 0x10,f);
//          fclose(f);

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
          memcpy(lw_addr+32, &row_8, 4);
          memcpy(lw_addr+36, &row_9, 4);
          memcpy(lw_addr+40, &row_10, 4);

          memcpy(lw_addr+48, &row_12, 4);
          memcpy(lw_addr+52, &row_13, 4);
          memcpy(lw_addr+56, &row_14, 4);

          memcpy(lw_addr+64, &row_16, 4);
          memcpy(lw_addr+68, &row_17, 4);
          memcpy(lw_addr+72, &row_18, 4);

          memcpy(lw_addr+80, &row_20, 4);
          memcpy(lw_addr+84, &row_21, 4);
          memcpy(lw_addr+88, &row_22, 4);

          memcpy(lw_addr+96, &row_24, 4);
          memcpy(lw_addr+100, &row_25, 4);
          memcpy(lw_addr+104, &row_26, 4);


          //output layer
//          memcpy(lw_addr+128, &row_32, 4);
//          memcpy(lw_addr+132, &row_33, 4);
//          memcpy(lw_addr+136, &row_34, 4);
//          memcpy(lw_addr+140, &row_35, 4);

          // fire module
          memcpy(lw_addr+144, &row_36, 4);
          memcpy(lw_addr+148, &row_37, 4);
          memcpy(lw_addr+152, &row_38, 4);
          memcpy(lw_addr+156, &row_39, 4);
          memcpy(lw_addr+160, &row_40, 4);
          memcpy(lw_addr+164, &row_41, 4);
          memcpy(lw_addr+168, &row_42, 4);
          memcpy(lw_addr+172, &row_43, 4);

          initialise_input_output_layer(lw_addr, 3, 3
                    		, 200, 64, 200
                    		, (unsigned char*)0x30000000, 0, 1, 0, 5
                    		, (unsigned char*)(0x30000000 + 0x400000));
          // issue start signal
//          memcpy(lw_addr+4, &row_1, 4);
          //memcpy(lw_addr, &row_0, 4);


          usleep(10000);
          printf("reading value in ddr3 output address space\n");
          //int i = 0;

          for(k = 0; k < 200; k++){
			  for(i = 0; i < 3; i++){
				  for(j = 0; j < 3; j++){
					 printf("%d ", *(ddr3_common+ 0x400000 + 4096 * k + (i * 64) + j)) ;
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
