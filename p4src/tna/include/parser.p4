// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#ifndef __PARSER__
#define __PARSER__

#include "shared/header.p4"
#include "shared/define.p4"

parser BasicIngressParser (packet_in  packet,
    /* Basic.p4 */
    out ingress_headers_t               hdr,
    out Basic_ingress_metadata_t      Basic_md,
    /* TNA */
    out ingress_intrinsic_metadata_t   ig_intr_md) {
    Checksum() ipv4_checksum;

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        Basic_md.bridged.setValid();
        Basic_md.bridged.base.ig_port = ig_intr_md.ingress_port;
        Basic_md.egress_port_set = false;
        transition select(ig_intr_md.ingress_port){
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition parse_eth_type;
    }

    state parse_eth_type {
        packet.extract(hdr.eth_type);
        transition select(hdr.eth_type.value) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        Basic_md.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        Basic_md.l4_src_port = hdr.tcp.sport;
        Basic_md.l4_dst_port= hdr.tcp.dport;
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        Basic_md.l4_src_port = hdr.udp.sport;
        Basic_md.l4_dst_port= hdr.udp.dport;
        transition accept;
    }
}

control BasicIngressDeparser(packet_out packet,
    /* Basic.p4 */
    inout ingress_headers_t hdr,
    in Basic_ingress_metadata_t Basic_md,
    /* TNA */
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        packet.emit(hdr);
    }
}

parser BasicEgressParser (packet_in packet,
    /* Basic.p4 */
    out egress_headers_t hdr,
    out Basic_egress_metadata_t Basic_md,
    /* TNA */
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }

}


control BasicEgressDeparser(packet_out packet,
    /* Basic.p4 */
    inout egress_headers_t hdr,
    in Basic_egress_metadata_t Basic_md,
    /* TNA */
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum() ipv4_checksum;
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            });
        }
        packet.emit(hdr);
    }
}

#endif // __PARSER__
