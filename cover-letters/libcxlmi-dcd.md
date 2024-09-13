DCD: Add four DCD commands and test code

Per cxl spec r3.1, this patch series adds the following four DCD commands:
1. section 8.2.9.9.9.1, Get Dynamic Capacity Configuration (Opcode 4800h);
2. section 8.2.9.9.9.2, Get Dynamic Capacity Extent List (Opcode 4801h);
3. section 8.2.9.9.9.3, Add Dynamic Capacity Response (Opcode 4802h);
4. section 8.2.9.9.9.4, Release Dynamic Capacity (Opcode 4803h);

Also, we add some code in examples/cxl-mctp.c to test the above 4 commands.

The output looks like below,
==> get DC region configuration:
# of regions: 2
# of regions returned: 2
# of extents supported: 512
# of extents available: 512
# of tags supported: 0
# of tags available: 0
region 0: base 0 decode_len 268435456 region_len 268435456 block_size 2097152
region 1: base 268435456 decode_len 268435456 region_len 268435456 block_size 2097152
==> get extent list:
Try to read 0 extents starting with id: 0
# of total extents: 0
generation number: 0
# of extents returned: 0
==>get extent list after sending add dynamic capacity response (need hack QEMU
to accept the extents: two extents added)
Try to read 0 extents starting with id: 0
# of total extents: 2
generation number: 0
# of extents returned: 2
extent[0] : [1000000, 1000000]
extent[1] : [1, 10000000]
==>get extent list after sending release dynamic capacity (need hack QEMU
to accept the extents: two extents added)
Try to read 0 extents starting with id: 0
# of total extents: 0
generation number: 0

To make it easier, we add test workflow automation support in cxl-test-tool tool.
cxl-tool.py --test-libcxlmi

The following patch needs to be applied to qemu source code.
$(cxl_test_tool_dir)/test-workflows/0001-cxl-mailbox-utils-for-libcxlmi-testing-DCD.patch

cxl-test-tool:
https://github.com/moking/cxl-test-tool.git
