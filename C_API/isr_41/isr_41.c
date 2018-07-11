#include <linux/module.h> /*Neededbyallmodules*/
#include <linux/kernel.h> /*NeededforKERN_INFO*/
#include <linux/init.h> /*Neededforthemacros*/
#include <linux/interrupt.h>
#include <linux/sched.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/of.h>

#include <linux/printk.h> 
#include <linux/kobject.h> 
#include <linux/sysfs.h> 
#include <linux/fs.h> 
#include <linux/string.h>

static struct kobject *isr_41_object;
#define DEVNAME "isr_41"


static int isr_41_received;

static ssize_t get_isr (struct kobject *kobj, struct kobj_attribute *attr,
                      char *buf)
{
		int tmp_cpy;
		tmp_cpy = isr_41_received;
        isr_41_received = 0;
        return sprintf(buf, "%d\n", tmp_cpy);
}

static ssize_t isr_reset(struct kobject *kobj, struct kobj_attribute *attr,
                      char *buf, size_t count)
{
        sscanf(buf, "%du", &isr_41_received);
        return count;
}

static struct kobj_attribute isr_41_received_attribute =__ATTR(isr_41_received, 0660, get_isr,isr_reset);


static irq_handler_t __test_isr(int irq, void* dev_id, struct pt_regs* regs)
{
	printk(KERN_INFO DEVNAME": ISR\n");
	isr_41_received = 1;
	return (irq_handler_t) IRQ_HANDLED;
}

static int __isr_41_driver_probe(struct platform_device* pdev)
{
	int irq_num;
    int error = 0;
	//struct netlink_kernel_cfg cfg;

	irq_num = platform_get_irq(pdev,0);
	printk(KERN_INFO DEVNAME":IRQ%dabouttoberegistered!\n",irq_num); 
	printk("Entering: %s\n", __FUNCTION__);
    isr_41_object = kobject_create_and_add("ISR_41", kernel_kobj);
    if(!isr_41_object)
            return -ENOMEM;

    error = sysfs_create_file(isr_41_object, &isr_41_received_attribute.attr);
    if (error) {
            printk("failed to create the foo file in /sys/kernel/isr_41 \n");
            return error;
    }

	return request_irq(irq_num,(irq_handler_t)__test_isr,0,DEVNAME, NULL);
} 

static int __isr_41_driver_remove(struct platform_device* pdev)
{
	int irq_num;
	irq_num = platform_get_irq(pdev,0);
	printk(KERN_INFO"test_int:IRQ%dabouttobefreed!\n",irq_num);
	free_irq(irq_num,NULL);
    kobject_put(isr_41_object);
	return 0;
}


static const struct of_device_id __isr_41_driver_id[] = {
	{.compatible="altr,socfpga−mysoftip1_isr_41"},
	{}
};


static struct platform_driver __isr_41_driver={
	.driver={
		.name=DEVNAME,
		.owner=THIS_MODULE,
		.of_match_table=of_match_ptr(__isr_41_driver_id),
	},
	.probe = __isr_41_driver_probe,
	.remove = __isr_41_driver_remove
};


// module_init(__isr_41_driver_probe);
// module_exit(__isr_41_driver_remove);

module_platform_driver (__isr_41_driver);
MODULE_LICENSE ("GPL");