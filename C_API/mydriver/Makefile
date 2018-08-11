obj-m += test_int.o

KERNELPATH = /home/vasan/AP85/linux/linux-socfpga/

all:
	make -C $(KERNELPATH) M=$(PWD)  modules

clean:
	make -C $(KERNELPATH) M=$(PWD) clean