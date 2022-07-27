// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

#include "size.p4"

#ifndef __DEFINE__
#define __DEFINE__

#define IP_VERSION_4 4

#define IP_VER_BITS 4
#define ETH_TYPE_BYTES 2
#define ETH_HDR_BYTES 14
#define IPV4_HDR_BYTES 20
#define UDP_HDR_BYTES 8

typedef bit<3>  fwd_type_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> l4_port_t;


#if defined(__TARGET_TOFINO__)
@p4runtime_translation("tna/PortId_t", 32)
#endif
type bit<9> BasicPortId_t;

const bit<8> DEFAULT_APP_ID = 0;
const bit<9> CPU_PORT = //inset CPU port

const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_ARP  = 0x0806;
const bit<16> ETHERTYPE_PACKET_OUT = 0xBF01;

const bit<8> PROTO_TCP = 6;
const bit<8> PROTO_UDP = 17;

const bit<4> IPV4_MIN_IHL = 5;

action nop() {
    NoAction();
}

#endif // __DEFINE__
