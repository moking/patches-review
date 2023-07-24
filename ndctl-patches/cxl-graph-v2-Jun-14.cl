Subject: [ndctl PATCH v2 0/2] cxl-graph: add a new command to construct CXL
 topology graph images

v1[1]->v2:
1. Simplified Patch 1 which adds parent_dport attribute to root port and
memdev for plotting cxl topology by leveraging the existing function
`cxl_port_get_parent_dport` in ndctl v77.
2. Introduced a new cxl command 'cxl graph' for cxl topology plotting instead
of implementing the functionality as an option in 'cxl list'.
3. Moved all graph plotting code to a separated file: graph.c.
4. Reverted the changes made to `cxl list` functionality, now its behavior
remains the same as before.
5. Added a new option "-t" for cxl graph command, it takes either 'plain' or
'graph' to determine whether we dump cxl topology to a json formatted file
or plot the topology to a graph. By default, it will plot the graph.
6. Added a function to validate the input cxl topology for "--input" option.
7. Added new code logic to handle cases where there are inactive memdevs.
8 Modified the plotting logic to make plotting work properly with different
user inputs (from options supported by cxl graph). For example, now we can plot
topology graph only for a specific endpoint or memdev.
9. Fix some comments and bugs in graph.c

Below is the cover letter of v1[1]:
This patch series extends the `cxl list` subcommand to show the cxl
topology visually. Mattew Ho first worked on the code and provided an
initial patch as list below[1].

This patch series includes the following two patches,
1) Patch 1 adds a parent_dport attribute to ports and type 3 memory devices
to show which downstream port a component is attached. This attribute will be 
used in patch 2 to generate the cxl topology graph.
2) Patch 2 extends the `cxl list` subcommand to dump the cxl topology to a
json format file or generate a graph showing the cxl topology. To use the
extended function, the option `-o output.suffix` is added. Acceptable output
suffixes include .jpeg, .jpg and .png for generating a graph and for other
suffix, it will dump the json-formatted cxl topology to the file, which
can be used the input file (with --input option) to generate the graph
later.

Patch 2 reuses the plotting functions in Matthew Ho's patch, which are updated
to work with parent_dport attribute in patch 1. Also, some bugs are
fixed. More detailed changes are listed in Patch 2's commit log.

The patch series is applied cleanly on ndctl v77, and tested with the
following different cxl topologies,
1) a single memdev attached the only root port of the single HB in the system;
2) two memdevs attached to the two root ports of the single HB in the system;
3) four memdevs attached to two HBs, each of which has two root ports;
4) four memdevs attached to the downstream ports of a cxl switch which is
attached to one of the two root ports of a HB in the system.


[1] [ndctl PATCH 0/2] cxl-list: Construct CXL topology graph images
https://lore.kernel.org/linux-cxl/20221220182510.2734032-1-fan.ni@samsung.com/
[2] Mattew Ho's patch:
https://lore.kernel.org/linux-cxl/cover.1660895649.git.sunfishho12@gmail.com/
