Enabling DCD emulation support in Qemu

v1->v2:

1. fix a regression issue mentioned by Iry[1]:
2. fix a compile warning due to uninitialized 'rip' in qmp processing function.


[1] https://lore.kernel.org/linux-cxl/64bfe7b090843_12757b2945b@iweiny-mobl.notmuch/T/#m09983a3dbaa9135a850e345d86714bf2ab957ef6
