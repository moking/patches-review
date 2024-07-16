Subject: [PATCH v3 0/9] Enabling DCD emulation support in Qemu


The patch series are based on Jonathan's branch cxl-2023-09-26.

The main changes include,
1. Update cxl_find_dc_region to detect the case the range of the extent cross
    multiple DC regions.
2. Add comments to explain the checks performed in function
    cxl_detect_malformed_extent_list. (Jonathan)
3. Minimize the checks in cmd_dcd_add_dyn_cap_rsp.(Jonathan)
4. Update total_extent_count in add/release dynamic capacity response function.
    (Ira and Jorgen Hansen).
5. Fix the logic issue in test_bits and renamed it to
    test_any_bits_set to clear its function.
6. Add pending extent list for dc extent add event.
7. When add extent response is received, use the pending-to-add list to
    verify the extents are valid.
8. Add test_any_bits_set and cxl_insert_extent_to_extent_list declaration to
    cxl_device.h so it can be used in different files.
9. Updated ct3d_qmp_cxl_event_log_enc to include dynamic capacity event
    log type.
10. Extract the functionality to delete extent from extent list to a helper
    function.
11. Move the update of the bitmap which reflects which blocks are backed with
dc extents from the moment when a dc extent is offered to the moment when it
is accepted from the host.
12. Free dc_name after calling address_space_init to avoid memory leak when
    returning early. (Nathan)
13. Add code to detect and reject QMP requests without any extents. (Jonathan)
14. Add code to detect and reject QMP requests where the extent len is 0.
15. Change the QMP interface and move the region-id out of extents and now
    each command only takes care of extent add/release request in a single
    region. (Jonathan)
16. Change the region bitmap length from decode_len to len.
17. Rename "dpa" to "offset" in the add/release dc extent qmp interface.
    (Jonathan)
18. Block any dc extent release command if the exact extent is not already in
    the extent list of the device.

The code is tested together with Ira's kernel DCD support:
https://github.com/weiny2/linux-kernel/tree/dcd-v3-2023-10-30

Cover letter from v2 is here:
https://lore.kernel.org/linux-cxl/20230724162313.34196-1-fan.ni@samsung.com/T/#m63039621087023691c9749a0af1212deb5549ddf

Last version (v2) is here:
https://lore.kernel.org/linux-cxl/20230725183939.2741025-1-fan.ni@samsung.com/

More DCD related discussions are here:
https://lore.kernel.org/linux-cxl/650cc29ab3f64_50d07294e7@iweiny-mobl.notmuch/


