f_exp = open('expected.txt', 'r')
f_act = open('/home/vasan/altera/AP85/output_files/output.txt', 'r')

f_exp_data = f_exp.read();
f_act_data = f_act.read();

f_exp_data = f_exp_data.split(',')
f_act_data = f_act_data.split(',')

for i in range(2704):
	int_act = int(f_act_data[i])
	int_exp = int(f_exp_data[i])
	if(int_act != int_exp):
		print('f_act_data: ' + str(int_exp) +' f_exp_data: ' + str(int_act))
		print('error at row: ' + str(int(i/9)), ' col: ' + str(i % 9))
		break