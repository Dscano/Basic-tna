// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#ifndef __HEADER__
#define __HEADER__

#include "define.p4"


@controller_header("packet_in")
header packet_in_header_t {
    BasicPortId_t ingress_port;
    bit<7>         _pad0;
}

// This header must have a pseudo ethertype at offset 12, to be parseable as an
// Ethernet frame in the ingress parser.
@controller_header("packet_out")
header packet_out_header_t {
    @padding bit<7>   pad0;
    BasicPortId_t     egress_port;
}

header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}

// NOTE: splitting the eth_type from the ethernet header helps to match on
//  the actual eth_type without checking validity bit of the VLAN tags.
header eth_type_t {
    bit<16> value;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header tcp_t {
    bit<16> sport;
    bit<16> dport;
    // Not matched/modified. Treat as payload.
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

// Without @pa_container_size basiccUpfDownlinkTest fails
// FIXME: test with future SDE releases and eventually remove pragmas
header udp_t {
    bit<16> sport;
    bit<16> dport;
    bit<16> len;
    bit<16> checksum;
}

// Common metadata which is bridged from ingress to egress.
@flexible
struct bridged_metadata_base_t {
    PortId_t                 ig_port;
    bit<16>                  ip_eth_type;
}

header bridged_metadata_t {
    bridged_metadata_base_t base;
#ifdef V1MODEL
// Use padding to make the header multiple of 8 bits,
// condition required by p4c when compiling for bmv2.
    bit<1>                 _pad0;
#endif
}

// Ingress pipeline-only metadata
//@pa_auto_init_metadata
struct Basic_ingress_metadata_t {
    bridged_metadata_t       bridged;
    bool                     egress_port_set;
    bit<16>                  l4_src_port;
    bit<16>                  l4_dst_port;
    bool                     ipv4_checksum_err;
}

//@pa_auto_init_metadata
struct Basic_egress_metadata_t {
    bridged_metadata_t    bridged;
    PortId_t              cpu_port;
    bit<16>               pkt_length;
}

struct ingress_headers_t {
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
    ethernet_t ethernet;
    eth_type_t eth_type;
    ipv4_t ipv4;
    tcp_t tcp;
    udp_t udp;
}

struct egress_headers_t {
    packet_in_header_t packet_in;
    ethernet_t ethernet;
    eth_type_t eth_type;
    ipv4_t ipv4;
    udp_t udp;
    tcp_t tcp;
}

#endif // __HEADER__
