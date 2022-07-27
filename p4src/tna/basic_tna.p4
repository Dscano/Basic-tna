// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#include <core.p4>
#include <tna.p4>

#include "shared/define.p4"
#include "shared/size.p4"
#include "shared/header.p4"
#include "tna/include/parser.p4"
#include "tna/include/control/packetio.p4"
#include "tna/include/control/table0.p4"


control BasicIngress (
    /* Basic.p4 */
    inout ingress_headers_t hdr,
    inout Basic_ingress_metadata_t Basic_md,
    /* TNA */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md) {

    PacketIoIngress() pkt_io;
    Table0() table0;

    apply {
        pkt_io.apply(hdr, Basic_md, ig_intr_md, ig_tm_md, ig_dprsr_md); 
        table0.apply(hdr, Basic_md, ig_intr_md, ig_tm_md, ig_dprsr_md);
    }
}

control BasicEgress (
    /* Basic.p4 */
    inout egress_headers_t hdr,
    inout Basic_egress_metadata_t Basic_md,
    /* TNA */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md) {

    apply {}
}

Pipeline(
    BasicIngressParser(),
    BasicIngress(),
    BasicIngressDeparser(),
    BasicEgressParser(),
    BasicEgress(),
    BasicEgressDeparser()
) pipe;

Switch(pipe) main;
