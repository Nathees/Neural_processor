## Squeezenet v1.1 Config
##layer 1 :- 	dim = 113 		depth = 3 		exp_kernal = 64 	squ_kernal = 16 	exp_1x1_en = 0 		max_en = 1 		avg_en = 0
##layer 2 :- 	dim = 56 		depth = 16 		exp_kernal = 64 	squ_kernal = 16 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
##layer 3 :- 	dim = 56 		depth = 16 		exp_kernal = 64 	squ_kernal = 32 	exp_1x1_en = 1 		max_en = 1 		avg_en = 0
##layer 4 :- 	dim = 27 		depth = 32 		exp_kernal = 128 	squ_kernal = 32 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
##layer 5 :- 	dim = 27 		depth = 32 		exp_kernal = 128 	squ_kernal = 48 	exp_1x1_en = 1 		max_en = 1 		avg_en = 0
##layer 6 :- 	dim = 13 		depth = 48 		exp_kernal = 192 	squ_kernal = 48 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
##layer 7 :- 	dim = 13 		depth = 48 		exp_kernal = 192 	squ_kernal = 64 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
##layer 8 :- 	dim = 13 		depth = 64 		exp_kernal = 256 	squ_kernal = 64 	exp_1x1_en = 1 		max_en = 0 		avg_en = 0
##layer 9 :- 	dim = 13 		depth = 64 		exp_kernal = 256 	squ_kernal = 100 	exp_1x1_en = 1 		max_en = 0 		avg_en = 1

##layer 9 :- 	
dim = 56 		
depth = 16 		
exp_kernal = 64 	
squ_kernal = 16 	
exp_1x1_en = 1 		
max_en = 0 		
avg_en = 0

##Configurations :- EXPAND 3X3 KERNAL CONTROLLER
##one_exp3_ker_addr_limit_i :- [NO of expand kernals / 4]
##exp3_ker_depth_i 	  		:- [depth - 1]
##layer_dimension_i 		:- [dimnision -1]

##Configurations :- EXPAND 1X1 KERNAL CONTROLLER
##tot_exp1_ker_addr_limit_i :- [(NO of expand kernals * depth) / 4 ] - 1
##one_exp1_ker_addr_limit_i :- [NO of expand kernals / 4]
##exp1_ker_depth_i 	  		:- [depth - 1]
##layer_dimension_i 		:- [dimnision -1]

##Configurations :- 
##one_exp_layer_addr_limit_i:- [(dimension * expand kernals / 4)] - 1
##exp_ker_depth_i 	  		:- [depth - 1]
##layer_dimension_i 		:- [dimnision -1]
##no_of_exp_kernals_i 		:- [2 * NO of expand kernals / 8 - 1]

##exp_123_addr_space_i 		:- [expand kernal / 4 * 3] - 1 	
##exp_12_addr_space_i 		:- [expand kernal / 4 * 2]
##exp_1_addr_space_i 			:- [expand kernal / 4 * 1] - 1
##exp_tot_addr_space_i 		:- [expand layer dim * expand kernal / 4] - 2
##max_tot_addr_space_i 		:- [max layer dim * expand kernal / 4] - 2

##Configurations :- Squeeze KERNAL CONTROLLER
##tot_squ_ker_addr_limit_i 	:- [(NO of squeeze kernals * depth / 8 ] - 1
##one_squ_ker_addr_limit_i 	:- [(depth / 2) / 8]
##tot_repeat_squ_kernals_i	:- [No of squeeze kernal * layer height]
##squ_kernals_63_i 			:- [No of squeeze kernal - 1] 		//if(>63) ? 63 : actual
##layer_dimension_i 			:- [dimension - 1]

##Configurations :- MAX 2 SQUEEZE
##tot_squ_addr_limit_i 		:- [(dimension * depth / 2) / 8] - 1 // After max pool
##no_of_squ_kernals_i 		:- [No of squeeze kernal - 1]
##squ_3x3_ker_depth_i 		:- [squeeze 3x3 depth]
##layer_dim_i 				:- [dimension - 1]
##squ_layer_dimension_i 	:- [Squeeze layer dimension - 1] // After max pool

valid_config = 1

## Check expand Kernel
if exp_kernal < 64 : 
	valid_config = 0;
	print('Expand Kernel should be >= 64')
elif (depth > 64) :
	valid_config = 0;
	print('Input Layer depth should be <= 64')
elif (exp_kernal * depth > 16384) :
	valid_config = 0;
	print('Expand Kernel x depth should be <= 16384')


## Layer dimension after maxpool
max_dim = 0
if dim % 2 == 0 :
	max_dim = (dim >> 1) - 1
else : 
	max_dim = (dim >> 1)

## Squeeze repeat enable
squ_repeat_en = 0
if (exp_kernal * squ_kernal > 16384) :
	squ_repeat_en = 1
else :
	squ_repeat_en = 0

## Max Squeeze Kernel
max_squ_kernel = 0
if (exp_kernal * squ_kernal > 16384) :
	if (16384 % exp_kernal != 0) :
		valid_config = 0
		print('config error in repeat squeeze kernel')
	else :
		max_squ_kernel = 16384 // exp_kernal
else :
	max_squ_kernel = squ_kernal

## Squeeze layer Input dimension
squ_dim = 0;
if max_en : 
	squ_dim = max_dim
else :
	squ_dim = dim

if valid_config :
	print('exp_1x1_en_i = ',exp_1x1_en) 
	print('max_en_i = ',max_en)
	print('one_exp_ker_addr_limit_i = ', exp_kernal//4)
	print('exp_ker_depth_i = ', depth-1)
	print('layer_dimension_i = ', dim-1)
	print('tot_exp1_ker_addr_limit_i = ', ((exp_kernal * depth) // 4) - 1)  
	print('one_exp_layer_addr_limit_i = ', ((dim * exp_kernal) // 4) - 1)  
	print('no_of_exp_kernals_i = ', ((2 * exp_kernal) // 8) - 1) 
	print('exp_123_addr_space_i = ', (exp_kernal // 4 * 3) - 1)  	
	print('exp_12_addr_space_i = ', exp_kernal // 4 * 2) 
	print('exp_1_addr_space_i = ', (exp_kernal // 4 * 1) - 1)  
	print('exp_tot_addr_space_i = ', (dim * exp_kernal // 4) - 2)
	print('max_tot_addr_space_i = ', (max_dim * exp_kernal // 4) - 2)   
	
	print('squ_repeat_en_i = ',squ_repeat_en) 
	print('avg_en_i = ',avg_en) 
	print('tot_squ_ker_addr_limit_i = ', (squ_kernal * 2 * exp_kernal // 8) - 1) 
	print('one_squ_ker_addr_limit_i = ', exp_kernal // 8)
	print('squ_kernals_63_i = ', max_squ_kernel - 1) 
	print('tot_squ_addr_limit_i = ', (squ_dim * exp_kernal // 8) - 1)
	print('no_of_squ_kernals_i = ', squ_kernal - 1) 
	print('squ_3x3_ker_depth_i = ', exp_kernal) 
	print('squ_layer_dimension_i = ', squ_dim - 1)  


	print('\n\nAddress Space')

	reg_axi_address = 144;
	fire_config = (dim - 1) << 16;
	fire_config = fire_config + ((depth - 1) << 8);
	fire_config = fire_config + (exp_kernal // 4);
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;
	fire_config = (((dim * exp_kernal) // 4 ) - 1) << 16;
	fire_config = fire_config + (((exp_kernal * depth) // 4) - 1);
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;
	fire_config = ((exp_kernal // 4 * 1) - 1) << 24;
	fire_config = fire_config + ((exp_kernal // 4 * 2) << 16);
	fire_config = fire_config + (((exp_kernal // 4 * 3) - 1) << 8);
	fire_config = fire_config + ((2 * exp_kernal // 8) - 1);
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;
	fire_config = ((max_dim * exp_kernal // 4) - 2) << 16;
	fire_config = fire_config + ((dim * exp_kernal // 4) - 2);
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;	
	fire_config = (exp_kernal // 8) << 16;
	fire_config = fire_config + ((squ_kernal * 2 * exp_kernal // 8) - 1);
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;
	fire_config = (max_squ_kernel - 1) << 16;
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;
	fire_config = (squ_kernal - 1) << 16;
	fire_config = fire_config + ((squ_dim * exp_kernal // 8) - 1);
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))

	reg_axi_address = reg_axi_address + 4;
	fire_config = 0;
	fire_config = (squ_dim - 1) << 16;
	fire_config = fire_config + exp_kernal;
	print('Addr : ',reg_axi_address,' = ',hex(fire_config))