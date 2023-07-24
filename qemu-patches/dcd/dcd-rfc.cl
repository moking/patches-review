
Since the early draft of DCD support in kernel is out
(https://lore.kernel.org/linux-cxl/20230417164126.GA1904906@bgt-140510-bm03/T/#t),
this patch series provide dcd emulation in qemu so people who are interested
can have a early try. It is noted that the patch series may need to be updated
accordingly if the kernel side implementation changes.

To support DCD emulation, the patch series add DCD related mailbox command
support (CXL Spec 3.0: 8.2.9.8.9), and extend the cxl type3 memory device
with dynamic capacity extent and region representative.
To support read/write to the dynamic capacity of the device, a host backend
is provided and necessary check mechnism is added to ensure the dynamic
capacity accessed is backed with active dc extents.
Currently FM related mailbox commands (cxl spec 3.0: 7.6.7.6) is not supported
, but we add two qmp interfaces for adding/releasing dynamic capacity extents.
Also, the support for multiple hosts sharing the same DCD case is missing.

Things we can try with the patch series together with kernel dcd code:
1. Create DC regions to cover the address range of the dynamic capacity
regions.
2. Add/release dynamic capacity extents to the device and notify the
kernel.
3. Test kernel side code to accept added dc extents and create dax devices,
and release dc extents and notify the device 
4. Online the memory range backed with dc extents and let application use
them.

The patch series is based on Jonathan's local qemu branch:
https://gitlab.com/jic23/qemu/-/tree/cxl-2023-02-28

Simple tests peformed with the patch series:
1 Install cxl modules:

modprobe -a cxl_acpi cxl_core cxl_pci cxl_port cxl_mem

2 Create dc regions:

region=$(cat /sys/bus/cxl/devices/decoder0.0/create_dc_region)
echo $region> /sys/bus/cxl/devices/decoder0.0/create_dc_region
echo 256 > /sys/bus/cxl/devices/$region/interleave_granularity
echo 1 > /sys/bus/cxl/devices/$region/interleave_ways
echo "dc" >/sys/bus/cxl/devices/decoder2.0/mode
echo 0x10000000 >/sys/bus/cxl/devices/decoder2.0/dpa_size
echo 0x10000000 > /sys/bus/cxl/devices/$region/size
echo  "decoder2.0" > /sys/bus/cxl/devices/$region/target0
echo 1 > /sys/bus/cxl/devices/$region/commit
echo $region > /sys/bus/cxl/drivers/cxl_region/bind

/home/fan/cxl/tools-and-scripts# cxl list
[
  {
    "memdevs":[
      {
        "memdev":"mem0",
        "pmem_size":536870912,
        "ram_size":0,
        "serial":0,
        "host":"0000:0d:00.0"
      }
    ]
  },
  {
    "regions":[
      {
        "region":"region0",
        "resource":45365592064,
        "size":268435456,
        "interleave_ways":1,
        "interleave_granularity":256,
        "decode_state":"commit"
      }
    ]
  }
]

3 Add two dc extents (128MB each) through qmp interface

{ "execute": "qmp_capabilities" }                                               
                                                                                
{ "execute": "cxl-add-dynamic-capacity-event",                                  
	"arguments": {                                                              
		 "path": "/machine/peripheral/cxl-pmem0",
		"region-id" : 0,                         
		 "num-extent": 2,
		"dpa":0,
		"extent-len": 128                    
	}                                                                           
}      

/home/fan/cxl/tools-and-scripts# lsmem 
RANGE                                  SIZE   STATE REMOVABLE   BLOCK
0x0000000000000000-0x000000007fffffff    2G  online       yes    0-15
0x0000000100000000-0x000000027fffffff    6G  online       yes   32-79
0x0000000a90000000-0x0000000a9fffffff  256M offline           338-339

Memory block size:       128M
Total online memory:       8G
Total offline memory:    256M


4.Online the momory with 'daxctl online-memory dax0.0' to online the memory

/home/fan/cxl/ndctl# ./build/daxctl/daxctl online-memory dax0.0
[  230.730553] Fallback order for Node 0: 0 1 
[  230.730825] Fallback order for Node 1: 1 0 
[  230.730953] Built 2 zonelists, mobility grouping on.  Total pages: 2042541
[  230.731110] Policy zone: Normal
onlined memory for 1 device

root@bgt-140510-bm03:/home/fan/cxl/ndctl# lsmem 
RANGE                                  SIZE   STATE REMOVABLE BLOCK
0x0000000000000000-0x000000007fffffff    2G  online       yes  0-15
0x0000000100000000-0x000000027fffffff    6G  online       yes 32-79
0x0000000a90000000-0x0000000a97ffffff  128M  online       yes   338
0x0000000a98000000-0x0000000a9fffffff  128M offline             339

Memory block size:       128M
Total online memory:     8.1G
Total offline memory:    128M

5 using dc extents as regular memory

/home/fan/cxl/ndctl# numactl --membind=1 ls
CONTRIBUTING.md  README.md  clean_config.sh  cscope.out   git-version-gen
ndctl	       scripts	test.h      version.h.in COPYING		 acpi.h
config.h.meson   cxl	  make-git-snapshot.sh	ndctl.spec.in  sles	tools
Documentation	 build	    contrib	     daxctl	  meson.build		rhel
tags	topology.png LICENSES	 ccan	    cscope.files
git-version  meson_options.txt	rpmbuild.sh    test	util


QEMU command line cxl configuration:

RP1="-object memory-backend-file,id=cxl-mem1,share=on,mem-path=/tmp/cxltest.raw,size=512M \
-object memory-backend-file,id=cxl-mem2,share=on,mem-path=/tmp/cxltest2.raw,size=512M \
-object memory-backend-file,id=cxl-lsa1,share=on,mem-path=/tmp/lsa.raw,size=512M \
-device pxb-cxl,bus_nr=12,bus=pcie.0,id=cxl.1 \                            
-device cxl-rp,port=0,bus=cxl.1,id=root_port13,chassis=0,slot=2 \          
-device cxl-type3,bus=root_port13,memdev=cxl-mem1,lsa=cxl-lsa1,dc-memdev=cxl-mem2,id=cxl-pmem0,num-dc-regions=1\
-M cxl-fmw.0.targets.0=cxl.1,cxl-fmw.0.size=4G,cxl-fmw.0.interleave-granularity=8k"


Kernel DCD support used to test the changes

The code is tested with the posted kernel dcd support:
https://git.kernel.org/pub/scm/linux/kernel/git/cxl/cxl.git/log/?h=for-6.5/dcd-preview

commit: f425bc34c600e2a3721d6560202962ec41622815

To make the test work, we have made the following changes to the above kernel commit:

diff --git a/drivers/cxl/core/mbox.c b/drivers/cxl/core/mbox.c
index 5f04bbc18af5..5f421d3c5cef 100644
--- a/drivers/cxl/core/mbox.c
+++ b/drivers/cxl/core/mbox.c
@@ -68,6 +68,7 @@ static struct cxl_mem_command cxl_mem_commands[CXL_MEM_COMMAND_ID_MAX] = {
 	CXL_CMD(SCAN_MEDIA, 0x11, 0, 0),
 	CXL_CMD(GET_SCAN_MEDIA, 0, CXL_VARIABLE_PAYLOAD, 0),
 	CXL_CMD(GET_DC_EXTENT_LIST, 0x8, CXL_VARIABLE_PAYLOAD, 0),
+	CXL_CMD(GET_DC_CONFIG, 0x2, CXL_VARIABLE_PAYLOAD, 0),
 };
 
 /*
diff --git a/drivers/cxl/core/region.c b/drivers/cxl/core/region.c
index 291c716abd49..ae10e3cf43a1 100644
--- a/drivers/cxl/core/region.c
+++ b/drivers/cxl/core/region.c
@@ -194,7 +194,7 @@ static int cxl_region_manage_dc(struct cxl_region *cxlr)
 		}
 		cxlds->dc_list_gen_num = extent_gen_num;
 		dev_dbg(cxlds->dev, "No of preallocated extents :%d\n", rc);
-		enable_irq(cxlds->cxl_irq[CXL_EVENT_TYPE_DCD]);
+		/*enable_irq(cxlds->cxl_irq[CXL_EVENT_TYPE_DCD]);*/
 	}
 	return 0;
 err:
@@ -2810,7 +2810,8 @@ int cxl_add_dc_extent(struct cxl_dev_state *cxlds, struct resource *alloc_dpa_re
 				dev_dax->align, memremap_compat_align()))) {
 		rc = alloc_dev_dax_range(dev_dax, hpa,
 					resource_size(alloc_dpa_res));
-		return rc;
+		if (rc)
+			return rc;
 	}
 
 	rc = xa_insert(&cxlr_dc->dax_dev_list, hpa, dev_dax, GFP_KERNEL);
diff --git a/drivers/cxl/pci.c b/drivers/cxl/pci.c
index 9e45b1056022..653bec203838 100644
--- a/drivers/cxl/pci.c
+++ b/drivers/cxl/pci.c
@@ -659,7 +659,7 @@ static int cxl_event_irqsetup(struct cxl_dev_state *cxlds)
 
 	/* Driver enables DCD interrupt after creating the dc cxl_region */
 	rc = cxl_event_req_irq(cxlds, policy.dyncap_settings, CXL_EVENT_TYPE_DCD,
-					IRQF_SHARED | IRQF_ONESHOT | IRQF_NO_AUTOEN);
+					IRQF_SHARED | IRQF_ONESHOT);
 	if (rc) {
 		dev_err(cxlds->dev, "Failed to get interrupt for event dc log\n");
 		return rc;
diff --git a/include/uapi/linux/cxl_mem.h b/include/uapi/linux/cxl_mem.h
index 6ca85861750c..910a48259239 100644
--- a/include/uapi/linux/cxl_mem.h
+++ b/include/uapi/linux/cxl_mem.h
@@ -47,6 +47,7 @@
 	___C(SCAN_MEDIA, "Scan Media"),                                   \
 	___C(GET_SCAN_MEDIA, "Get Scan Media Results"),                   \
 	___C(GET_DC_EXTENT_LIST, "Get dynamic capacity extents"),         \
+	___C(GET_DC_CONFIG, "Get dynamic capacity configuration"),         \
 	___C(MAX, "invalid / last command")
 
 #define ___C(a, b) CXL_MEM_COMMAND_ID_##a


