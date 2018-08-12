import random


# create 49*49 sized 5 image layers
# each image layer will be aliged to 4k blocks

NO_OF_LAYERS = 16
ROW_SIZE = 13
COL_SIZE = 13

#initial 4k empty space for simulation
byte_list = []
zero_fill = [5]*(4096)
byte_list.extend(zero_fill)
for i in range(NO_OF_LAYERS):
	for j in range(ROW_SIZE):
		for k in range(COL_SIZE):
			byte_list.append(random.randint(0,255))
		zero_fill = [5]*(16 - COL_SIZE)
		byte_list.extend(zero_fill)
	zero_fill = [5]*(4096 - 16 * ROW_SIZE)
	byte_list.extend(zero_fill)

OFFSET = 4096

#code for expected output
ROW_SPACE = 16
expected_stream = []
for l in range(int(ROW_SIZE)):
	for k in range(NO_OF_LAYERS):
		for m in range(int(COL_SIZE)):
			j = m  #2*m + 1
			i = l  #2*l + 1
			
			win_0_0 =  0 if ((i == 0) |  (j == 0))    else byte_list[k * 4096  + (i-1)*ROW_SPACE + j-1 + OFFSET]
			win_1_0 =  0  if ((i == 0)) else byte_list[k * 4096  + (i-1)*ROW_SPACE + j + OFFSET]
			win_2_0 =  0 if ((i == 0) |  (j == COL_SIZE -1)) else byte_list[k * 4096  + (i-1)*ROW_SPACE + j+1 + OFFSET]

			win_0_1 =  0 if (j == 0)  else byte_list[k * 4096  + (i)*ROW_SPACE + j-1 + OFFSET]
			win_1_1 = byte_list[k * 4096  + (i)*ROW_SPACE + j + OFFSET]
			win_2_1 =  0 if (j == COL_SIZE -1)  else byte_list[k * 4096  + (i)*ROW_SPACE + j+1 + OFFSET]

			win_0_2 = 0 if ((j == 0) | (i == ROW_SIZE - 1)) else byte_list[k * 4096  + (i+1)*ROW_SPACE + j-1 + OFFSET]
			win_1_2 = 0 if ((i == ROW_SIZE - 1)) else byte_list[k * 4096  + (i+1)*ROW_SPACE + j + OFFSET]
			win_2_2 = 0 if ((i == ROW_SIZE - 1) | (j == COL_SIZE -1)) else byte_list[k * 4096  + (i+1)*ROW_SPACE + j+1 + OFFSET]

			expected_stream.append([win_0_0, win_1_0, win_2_0, win_0_1, win_1_1, win_2_1, win_0_2, win_1_2, win_2_2])
			print(str(i) + " " + str(j) + " " + str(k) + ' ' + str(byte_list[k * 4096  + (i)*ROW_SIZE + j+1 + OFFSET]))

# byte_list = []



# writing mem init file
f_coe = open('mem_init1.coe', 'w')
f_coe.write('memory_initialization_radix=16;\nmemory_initialization_vector=')
for i in range(int(len(byte_list)/8)):
	row = byte_list[i * 8 : (i +1) * 8]
	hex_int = (row[7] << 56) + (row[6] << 48) + (row[5] << 40) + (row[4] << 32) + (row[3] << 24) + (row[2] << 16) + (row[1] << 8) + (row[0])
	f_coe.write(format(hex_int, 'x') + ",\n")
f_coe.close();
# print(byte_list)

# print(expected_stream)

f_exp = open('expected.txt', 'w')
for i in range(int(len(expected_stream))):
	win_3x3 = [str(i) for i in expected_stream[i]]
	f_exp.write(', '.join(win_3x3) + ',\n')

f_exp.close()