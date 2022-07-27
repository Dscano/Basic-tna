// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#include "shared/header.p4"

control PacketIoIngress(inout ingress_headers_t hdr,
                        inout Basic_ingress_metadata_t basic_md,
                        in    ingress_intrinsic_metadata_t ig_intr_md,
                        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
                        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        if (hdr.packet_out.isValid()) {
            ig_intr_md_for_tm.ucast_egress_port = (PortId_t) hdr.packet_out.egress_port;
            basic_md.egress_port_set = true;
            hdr.packet_out.setInvalid();
            // Straight to output port.
            basic_md.bridged.setInvalid();
            ig_intr_md_for_tm.bypass_egress = 1;
            exit;
        }
    }
}

control PacketIoEgress(inout egress_headers_t hdr,
                       inout Basic_egress_metadata_t basic_md,
                       in egress_intrinsic_metadata_t eg_intr_md) {

    apply {
        if (eg_intr_md.egress_port == basic_md.cpu_port) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = (BasicPortId_t)basic_md.bridged.base.ig_port;
            exit;
        }
    }

}