// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#include <core.p4>
#include <tna.p4>

#include "shared/define.p4"
#include "shared/header.p4"


control Table0 (inout ingress_headers_t hdr,
                inout Basic_ingress_metadata_t basic_md,
                in    ingress_intrinsic_metadata_t ig_intr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    BasicPortId_t ig_port = (BasicPortId_t)ig_intr_md.ingress_port;

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table0_counter;

    action copy_to_cpu() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
        table0_counter.count();
    }

    action set_egress_port(BasicPortId_t port_num) {
       ig_intr_md_for_tm.ucast_egress_port = (PortId_t)port_num;
       ig_intr_md_for_tm.bypass_egress = 1;
       table0_counter.count();
    }

    action drop() {
       ig_intr_md_for_dprsr.drop_ctl = 0x1;
       table0_counter.count();
    }

    table table0 {
        key = {
            ig_port                        : ternary @name("ig_port");
            hdr.ethernet.src_addr          : ternary @name("eth_src");
            hdr.ethernet.dst_addr          : ternary @name("eth_dst");
            hdr.eth_type.value             : ternary @name("eth_type");
            hdr.ipv4.src_addr              : ternary @name("ipv4_src");
            hdr.ipv4.dst_addr              : ternary @name("ipv4_dst");
            hdr.ipv4.protocol              : ternary @name("ip_proto");
            basic_md.l4_src_port           : ternary @name("l4_sport");
            basic_md.l4_dst_port           : ternary @name("l4_dport");
        }
        actions = {
            set_egress_port;
            copy_to_cpu;
            drop;
        }
        const default_action = drop();
        counters = table0_counter;
        size = TABLE0_TABLE_SIZE;
    }

    apply {
        table0.apply();
     }
}
