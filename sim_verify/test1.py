import numpy as np
from scipy import signal as sg
dim = 13
dim_p=dim + 2
dep = 16
ker = 64
sq_ker = 32
pool_en = 0
av_pool_en = 0
random = 0 #TODO
sq_rep = 0 # repete squze kernl for last layer

###########quantization weight###########
from ctypes import *
def q(x):
    bits = cast(pointer(c_float(x)), POINTER(c_int32)).contents.value
    bits = bits + 0x100000; # round off
    bits=(bits>>21)<<21
    return cast(pointer(c_int32(bits)), POINTER(c_float)).contents.value
q8 = np.vectorize(q)
def qq(x):
    bits = cast(pointer(c_float(x)), POINTER(c_int32)).contents.value
    # bits = bits + 0x010000;
    # bits=(bits>>17)<<17
    bits=bits&0xfffe0000
    return cast(pointer(c_int32(bits)), POINTER(c_float)).contents.value
q12 = np.vectorize(qq)

def byt_flt(x):
    ee = ((x&0x7c)>>2)+112
    if((x&0x7c) == 0):
        if x&0x3==0:
            ee=0
        else:
            ee=112
    bits = ((x&0x80)<<24) | (ee)<<23 | (x&0x3)<<21
    # print(hex(bits))
    return cast(pointer(c_int32(bits)), POINTER(c_float)).contents.value
b2f = np.vectorize(byt_flt)

def flt_byt(x):
    x = cast(pointer(c_float(x)), POINTER(c_int32)).contents.value
    # print(hex(x))
    e = ((x&0x7F800000)>>23) - 112
    man = x&0x00600000
    sgn = x&0x80000000
    if e<0:
        e = 0
        man = 0
        sgn = 0
    if e>31:
        e = 31
    bits = sgn>>24 | e<<2 | man>>21
    return np.uint8(bits)
f2b = np.vectorize(flt_byt)

def add(x):
    while len(x)!=1:#hiearchical addition
        t=[]
        for a in range(0,len(x),2):
            t.append(qq(x[a])+qq(x[a+1]))
        x=t
    return x[0]
#######################         Input image
in_l = np.zeros(dim_p*dim_p*dep, dtype='uint8').reshape((dim_p,dim_p,dep))
if random == 0:
    # in_ori = np.arange(dim*dim*dep, dtype='uint8').reshape((dim,dim,dep))
    in_ori = np.random.randint(low = 60, high = 100, size = (dim*dim*dep),dtype='uint8').reshape((dim,dim,dep))
else:
    in_ori = np.random.randint(low = 0, high = 255, size = (dim,dim,dep), dtype='uint8')
in_l[1:-1,1:-1,:] = in_ori
# print(in_l[:,:,0]); print("_____________________-")
f_in = open("input_layer.txt","w")
f_in_b = open("input_layer.bin","wb")
for z in range(0,dim):
    for y in range(0,dep):
        for x in range(0,dim):
            lis = in_l[z:z+3,x:x+3,y].flatten().tolist()
            for rep in range(0,ker,4):
                f_in.write(str(lis)[1:-1]+'\n')
                f_in_b.write(bytearray(lis))
########################        expand kernels 
ker_l_1 = np.zeros(ker*dep, dtype='uint8').reshape((ker,dep))
# ker_l_1 = np.random.randint(low = 60, high = 100, size = (ker*dep),dtype='uint8').reshape((ker,dep))
f_k_1 = open("ker_1x1.txt","w")
f_k_1_b = open("ker_1x1.bin","wb")
# print(ker_l_1);print("________")
for z in range(0,dep):
    lis = ker_l_1[:,z]
    f_k_1_b.write(bytearray(lis))
    f_k_1.write(str(lis)[1:-1]+'\n')

ker_l_3 = np.zeros(ker*dep*9, dtype='uint8').reshape((ker,dep,9))
# print(ker_l_3[0,0,:]);print("________")
f_k_3 = open("ker_3x3.txt","w")
f_k_3_b = open("ker_3x3.bin","wb")
for m in range(0,dim): # repet 3x3 kernel
    for z in range(0,dep):
        lis = ker_l_3[:,z,:]
        for x in range(0,ker,8):
            for a in range(0,8):
                eig = lis[x+a,0:8]
                f_k_3_b.write(bytearray(eig))
                f_k_3.write(str(eig)[1:-1]+'\n')
            nin = lis[x:x+8,-1].flatten()[::-1] #reversed
            f_k_3_b.write(bytearray(nin))
            f_k_3.write(str(nin)[1:-1]+'\n')
ker_l_1 = b2f(ker_l_1)
ker_l_3 = b2f(ker_l_3)
########################        exapnd bias
#bis_1 = np.full(ker,60,dtype='uint8') #one
bis_1 = np.random.randint(low = 60, high = 100, size = (ker),dtype='uint8')
# bis_1 = np.full(ker,0x00,dtype='uint8')
# bis_3 = np.full(ker,0x3c,dtype='uint8')
bis_3 = np.full(ker,0x00,dtype='uint8')
b_bis = open("bias.txt","w")
b_bis_b = open("bias.bin","wb")
# print(bis_1)
for i in range(0,ker,4):
    b_bis.write(str(bis_3[i:i+4])[1:-1]+'\n')
    b_bis.write(str(bis_1[i:i+4])[1:-1]+'\n')
    b_bis_b.write(bytearray(bis_3[i:i+4]))
    b_bis_b.write(bytearray(bis_1[i:i+4]))
bis_1 = b2f(bis_1) ######### convert to float
# print(bis_1)
# print(sum(bis_1))
bis_3 = b2f(bis_3)
#######################        expand convolution
out_1 = np.zeros(ker*dep*dim*dim, dtype='float32').reshape((ker,dep,dim,dim))
for k in range(0,ker):
    for l in range(0,dep):
        res = sg.convolve(in_l[:,:,l],[[ker_l_1[k,l]]] , "valid").astype(float)
        out_1[k,l,:,:]=res[1:-1,1:-1]
# print(out_1[1,1,:,:]);print('______')
f_out_1 = open("out_1x1.txt","w")
f_out_1_b = open("out_1x1.bin","wb")
# out_1 = np.arange(ker*dep*dim*dim, dtype='uint8').reshape((ker,dep,dim,dim))
for r in range(0,dim):
    for d in range(0,dep):
        for c in range(0,dim):
            lis = f2b( out_1[:,d,r,c])
            f_out_1_b.write(bytearray(lis))
            f_out_1.write(str(lis)[1:-1]+'\n')


out_3 = np.zeros(ker*dep*dim*dim, dtype='float32').reshape((ker,dep,dim,dim))
for k in range(0,ker):
    for l in range(0,dep):
        kk = np.rot90(ker_l_3[k,l].reshape((3,3)),2)
        res = sg.convolve(in_l[:,:,l],kk , "valid").astype(float) # addre lus #################### change to 12bit
        out_3[k,l,:,:]=res
# print(out_3[1,1,:,:]);print('______')
# out_3 = np.arange(ker*dep*dim*dim, dtype='uint8').reshape((ker,dep,dim,dim))

f_out_3 = open("out_3x3.txt","w")
f_out_3_b = open("out_3x3.bin","wb")
for r in range(0,dim):
    for d in range(0,dep):
        for c in range(0,dim):
            lis = f2b(out_3[:,d,r,c])
            f_out_3_b.write(bytearray(lis))
            f_out_3.write(str(lis)[1:-1]+'\n')

############################ add bias and relu
out_1_tmp = np.zeros(ker*dim*dim, dtype='float32').reshape((ker,dim,dim))
for a in range(0,ker):# for exp kernel addition is sequential
    for b in range(0,dim):
        for c in range(0,dim):
            ans = 0.0
            for i in range(dep):
                ans = qq(ans + qq(out_1[a,i,b,c]))
            out_1_tmp[a,b,c]=ans
# print(out_1_tmp[0,:,:])
out_1 = out_1_tmp
# out_1 = np.sum(out_1,1,dtype='float32') ########change to 12 bit
# print(out_1[0,:,:])
for i in range(0,ker):
    out_1[i,:,:] = q12(q12(out_1[i,:,:]) + q12(bis_1[i]))
out_1[out_1 < 0] = 0.0 # no need for positive
exp_out_1 = open("exp_1.txt","w")
exp_out_1_b = open("exp_1.bin","wb")
for x in range(0,dim):
    for y in range(0,dim):
        lis=f2b(out_1[:,x,y])
        exp_out_1_b.write(bytearray(lis))
        exp_out_1.write(str(lis)[1:-1]+'\n')


out_3 = np.sum(out_3,1,dtype='float32') ############# change
for i in range(0,ker):
    out_3[i,:,:] = q12(q12(out_3[i,:,:]) + q12(bis_3[i]))
out_3[out_3 < 0] = 0.0
exp_out_3 = open("exp_3.txt","w")
exp_out_3_b = open("exp_3.bin","wb")
for x in range(0,dim):
    for y in range(0,dim):
        lis=f2b(out_3[:,x,y])
        exp_out_3_b.write(bytearray(lis))
        exp_out_3.write(str(lis)[1:-1]+'\n')

############################# pooling
dim_o = (dim - 1)//2
# out_1 = np.arange(ker*dim*dim, dtype='uint8').reshape((ker,dim,dim)) #test pool
# print(out_1)
pool_1 = np.zeros((ker,dim_o,dim_o), dtype = 'uint8') #initialize
for x in range(0,dim_o):
    xx = x*2
    for y in range(0,dim_o):
        yy = y*2
        pool_1[:,x,y]= np.amax(out_1[:,xx:xx+3,yy:yy+3],(1,2))
# print(out_1[:,:,:]);print(pool_1[:,:,:]) # pool checking 
pool_out_1 = open("pool_1.txt","w")
pool_out_1_b = open("pool_1.bin","wb")
# print(pool_1)
for x in range(0,dim_o):
    for y in range(0,dim_o):
        lis=pool_1[:,x,y]
        pool_out_1_b.write(bytearray(lis))
        pool_out_1.write(str(lis)[1:-1]+'\n')

# out_3 = np.arange(ker*dim*dim, dtype='uint8').reshape((ker,dim,dim)) #test pool
# print(out_3)
pool_3 = np.zeros((ker,dim_o,dim_o), dtype = 'uint8')
for x in range(0,dim_o):
    xx = x*2
    for y in range(0,dim_o):
        yy = y*2
        pool_3[:,x,y]= np.amax(out_3[:,xx:xx+3,yy:yy+3],(1,2))

pool_out_3 = open("pool_3.txt","w")
pool_out_3_b = open("pool_3.bin","wb")
# print(pool_3)
for x in range(0,dim_o):
    for y in range(0,dim_o):
        lis=pool_3[:,x,y]
        pool_out_3_b.write(bytearray(lis))
        pool_out_3.write(str(lis)[1:-1]+'\n')

########################## squeeze
sq_in=[] # dep*dim*dim
dep = ker*2 # TODO firs layer no ned 2
if pool_en == 1: # ########TODO add first layer heere
    sq_in = np.concatenate((pool_1, pool_3), axis=0)
    dim_sq = dim_o
else:
    sq_in = np.concatenate((out_1, out_3), axis=0)
    dim_sq = dim

# print(out_1[31,:,:])
# print(out_3[0,:,:])
# print(sq_in[31:33,:,:])
# sq_in = np.rollaxis(sq_in,0,3)

########################   squ kernel
if random == 0:
    #sq_ker_l = np.full(sq_ker*dep,65,dtype='uint8').reshape((sq_ker,dep))
    sq_ker_l = np.random.randint(low=60, high=100, size = (sq_ker*dep),dtype='uint8').reshape((sq_ker,dep))
    #sq_ker_l = np.zeros(sq_ker*dep, dtype='uint8').reshape((sq_ker,dep))
else:
    sq_ker_l = np.random.randint(low = 0, high = 255, size = (sq_ker,dep), dtype='uint8')

sq_k_1 = open("sq_ker.txt","w")
sq_k_1_b = open("sq_ker.bin","wb")
# print(sq_ker_l[0,:])
dep_h = dep//2

rep_no = 1
if(sq_rep == 1):
    rep_no = dim_sq
for r in range(0,rep_no):
    for x in range(0,sq_ker):
        for z in range(0,dep_h,8):
            lis = sq_ker_l[x,z+dep_h:z+dep_h+8]#kerle of 3x3 part
            sq_k_1.write(str(lis)[1:-1]+'\n')
            sq_k_1_b.write(bytearray(lis))

            lis = sq_ker_l[x,z:z+8]
            sq_k_1.write(str(lis)[1:-1]+'\n')
            sq_k_1_b.write(bytearray(lis))
    
sq_ker_l = b2f(sq_ker_l) #########converting to float
#######################    squ bias
#sq_bis_1 = np.full(sq_ker,0x1C,dtype='uint8')
sq_bis_1 = np.random.randint(low = 0, high = 255, size = (sq_ker),dtype='uint8')
# print(sq_bis_1)
f_sq_bis = open("sq_bias.txt","w")
f_sq_bis_b = open("sq_bias.bin","wb")
f_sq_bis.write(str(sq_bis_1)[1:-1]+'\n')
f_sq_bis_b.write(bytearray(sq_bis_1))

sq_bis_1 = b2f(sq_bis_1)# converting to float
######################    squ convoluve
sq_out = np.zeros((sq_ker,dep,dim_sq,dim_sq), dtype='float32')
for k in range(0,sq_ker):
    for l in range(0,dep):
        res = sg.convolve(sq_in[l,:,:],[[sq_ker_l[k,l]]] , "valid").astype(float)
        sq_out[k,l,:,:]=res

# print(sq_in[0:3,:,:])
# print(sq_ker_l[0,0])
# print(sq_out[0,2,:,:])

squ_out_tmp = np.zeros((sq_ker,dim_sq,dim_sq), dtype='float32')
for a in range(0,sq_ker):
    for b in range(0,dim_sq):
        for c in range(0,dim_sq):
            squ_out_tmp[a,b,c]=add(sq_out[a,:,b,c])
sq_out = squ_out_tmp
# print(sq_out[:,0,0])
# print(sq_bis_1)
for i in range(0,sq_ker):
    sq_out[i,:,:] = sq_out[i,:,:] + sq_bis_1[i]
sq_out[sq_out < 0] = 0 # no need for positive
# print(sq_out[:,0,0])

# sq_out = np.arange(sq_ker*dim_sq*dim_sq, dtype='uint8').reshape((sq_ker,dim_sq,dim_sq)) # test ouptu
# print(sq_out[0,:,:]);print('______')
f_sq_out_1 = open("sq_out.txt","w")
f_sq_out_1_b = open("sq_out.bin","wb")
for r in range(0,dim_sq):
    for d in range(0,sq_ker):
        lis = f2b(sq_out[d,r,:])
        f_sq_out_1_b.write(bytearray(lis))
        f_sq_out_1.write(str(lis)[1:-1]+'\n')

########################     avg pool
sq_bis_1 = np.ones(sq_ker,dtype='uint8') # actual value for convoution
if av_pool_en == 1:
    av_pool = np.sum(sq_out,axis = (1,2), dtype = 'uint8')
    f_av_out_1 = open("av_pool_out.txt","w")
    f_av_out_1_b = open("av_pool_out.bin","wb")
    f_av_out_1_b.write(bytearray(av_pool))
    f_av_out_1.write(str(av_pool)[1:-1]+'\n')