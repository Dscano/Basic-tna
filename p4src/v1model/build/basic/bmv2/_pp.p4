#include <core.p4>
#define V1MODEL_VERSION 20180101
#include <v1model.p4>

typedef bit<48> mac_t;
typedef bit<32> ip_address_t;
typedef bit<16> l4_port_t;
typedef bit<9> port_t;
typedef bit<16> next_hop_id_t;
const port_t CPU_PORT = 255;
typedef bit<8> MeterColor;
const MeterColor MeterColor_GREEN = 8w0;
const MeterColor MeterColor_YELLOW = 8w1;
const MeterColor MeterColor_RED = 8w2;
@controller_header("packet_in") header packet_in_header_t {
    bit<9> ingress_port;
    bit<7> _padding;
}

@controller_header("packet_out") header packet_out_header_t {
    bit<9> egress_port;
    bit<7> _padding;
}

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

const bit<8> ETH_HEADER_LEN = 14;
header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

const bit<8> IPV4_MIN_HEAD_LEN = 20;
header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
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

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length_;
    bit<16> checksum;
}

const bit<8> UDP_HEADER_LEN = 8;
struct headers_t {
    packet_out_header_t packet_out;
    packet_in_header_t  packet_in;
    ethernet_t          ethernet;
    ipv4_t              ipv4;
    tcp_t               tcp;
    udp_t               udp;
}

struct local_metadata_t {
    bit<16>       l4_src_port;
    bit<16>       l4_dst_port;
    next_hop_id_t next_hop_id;
    bit<16>       selector;
    bool          compute_checksum;
}

parser parser_impl(packet_in packet, out headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    state start {
        transition select(standard_metadata.ingress_port) {
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
        transition select(hdr.ethernet.ether_type) {
            0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        local_metadata.l4_src_port = hdr.tcp.src_port;
        local_metadata.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        local_metadata.l4_src_port = hdr.udp.src_port;
        local_metadata.l4_dst_port = hdr.udp.dst_port;
        transition accept;
    }
}

control deparser(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
    }
}

action nop() {
    NoAction();
}
control port_counters_ingress(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    counter(511, CounterType.packets) ingress_port_counter;
    apply {
        ingress_port_counter.count((bit<32>)standard_metadata.ingress_port);
    }
}

control port_counters_egress(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    counter(511, CounterType.packets) egress_port_counter;
    apply {
        egress_port_counter.count((bit<32>)standard_metadata.egress_port);
    }
}

control port_meters_ingress(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    meter(511, MeterType.bytes) ingress_port_meter;
    MeterColor ingress_color = MeterColor_GREEN;
    apply {
        ingress_port_meter.execute_meter<MeterColor>((bit<32>)standard_metadata.ingress_port, ingress_color);
        if (ingress_color == MeterColor_RED) {
            mark_to_drop(standard_metadata);
        }
    }
}

control port_meters_egress(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    meter(511, MeterType.bytes) egress_port_meter;
    MeterColor egress_color = MeterColor_GREEN;
    apply {
        egress_port_meter.execute_meter<MeterColor>((bit<32>)standard_metadata.egress_port, egress_color);
        if (egress_color == MeterColor_RED) {
            mark_to_drop(standard_metadata);
        }
    }
}

control verify_checksum_control(inout headers_t hdr, inout local_metadata_t local_metadata) {
    apply {
    }
}

control compute_checksum_control(inout headers_t hdr, inout local_metadata_t local_metadata) {
    apply {
        update_checksum(hdr.ipv4.isValid(), { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.dscp, hdr.ipv4.ecn, hdr.ipv4.len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr }, hdr.ipv4.hdr_checksum, HashAlgorithm.csum16);
    }
}

control packetio_ingress(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    apply {
        if (standard_metadata.ingress_port == CPU_PORT) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
            hdr.packet_out.setInvalid();
            exit;
        }
    }
}

control packetio_egress(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    apply {
        if (standard_metadata.egress_port == CPU_PORT) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = standard_metadata.ingress_port;
        }
    }
}

control table0_control(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    direct_counter(CounterType.packets_and_bytes) table0_counter;
    action set_next_hop_id(next_hop_id_t next_hop_id) {
        local_metadata.next_hop_id = next_hop_id;
    }
    action send_to_cpu() {
        standard_metadata.egress_spec = CPU_PORT;
    }
    action set_egress_port(port_t port) {
        standard_metadata.egress_spec = port;
    }
    action drop() {
        mark_to_drop(standard_metadata);
    }
    table table0 {
        key = {
            standard_metadata.ingress_port: ternary;
            hdr.ethernet.src_addr         : ternary;
            hdr.ethernet.dst_addr         : ternary;
            hdr.ethernet.ether_type       : ternary;
            hdr.ipv4.src_addr             : ternary;
            hdr.ipv4.dst_addr             : ternary;
            hdr.ipv4.protocol             : ternary;
            local_metadata.l4_src_port    : ternary;
            local_metadata.l4_dst_port    : ternary;
        }
        actions = {
            set_egress_port;
            send_to_cpu;
            set_next_hop_id;
            drop;
        }
        const default_action = drop();
        counters = table0_counter;
    }
    apply {
        table0.apply();
    }
}

control host_meter_control(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    MeterColor meter_tag = MeterColor_GREEN;
    direct_meter<MeterColor>(MeterType.bytes) host_meter;
    action read_meter() {
        host_meter.read(meter_tag);
    }
    table host_meter_table {
        key = {
            hdr.ethernet.src_addr: lpm;
        }
        actions = {
            read_meter();
            NoAction;
        }
        meters = host_meter;
        default_action = NoAction();
    }
    apply {
        host_meter_table.apply();
        if (meter_tag == MeterColor_RED) {
            mark_to_drop(standard_metadata);
        }
    }
}

control ingress(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
        port_counters_ingress.apply(hdr, standard_metadata);
        port_meters_ingress.apply(hdr, standard_metadata);
        packetio_ingress.apply(hdr, standard_metadata);
        table0_control.apply(hdr, local_metadata, standard_metadata);
        host_meter_control.apply(hdr, local_metadata, standard_metadata);
    }
}

control egress(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
        port_counters_egress.apply(hdr, standard_metadata);
        port_meters_egress.apply(hdr, standard_metadata);
        packetio_egress.apply(hdr, standard_metadata);
    }
}

V1Switch(parser_impl(), verify_checksum_control(), ingress(), egress(), compute_checksum_control(), deparser()) main;

