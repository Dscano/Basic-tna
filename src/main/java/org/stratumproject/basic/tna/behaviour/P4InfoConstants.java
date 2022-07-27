// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

// Do not modify this file manually, use `make constants` to generate this file.

package org.stratumproject.basic.tna.behaviour;

import org.onosproject.net.pi.model.PiActionId;
import org.onosproject.net.pi.model.PiActionParamId;
import org.onosproject.net.pi.model.PiPacketMetadataId;
import org.onosproject.net.pi.model.PiMatchFieldId;
import org.onosproject.net.pi.model.PiTableId;
/**
 * P4Info constants.
 */
public final class P4InfoConstants {

    // hide default constructor
    private P4InfoConstants() {
    }

    // Header field IDs
    public static final PiMatchFieldId HDR_EG_PORT =
            PiMatchFieldId.of("eg_port");
    public static final PiMatchFieldId HDR_ETH_DST =
            PiMatchFieldId.of("eth_dst");
    public static final PiMatchFieldId HDR_ETH_SRC =
            PiMatchFieldId.of("eth_src");
    public static final PiMatchFieldId HDR_ETH_TYPE =
            PiMatchFieldId.of("eth_type");
    public static final PiMatchFieldId HDR_IG_PORT =
            PiMatchFieldId.of("ig_port");
    public static final PiMatchFieldId HDR_IP_PROTO =
            PiMatchFieldId.of("ip_proto");
    public static final PiMatchFieldId HDR_IPV4_DST =
            PiMatchFieldId.of("ipv4_dst");
    public static final PiMatchFieldId HDR_IPV4_SRC =
            PiMatchFieldId.of("ipv4_src");
    public static final PiMatchFieldId HDR_L4_DPORT =
            PiMatchFieldId.of("l4_dport");
    public static final PiMatchFieldId HDR_L4_SPORT =
            PiMatchFieldId.of("l4_sport");
    public static final PiTableId BASIC_EGRESS_STATS_FLOWS =
            PiTableId.of("BasicEgress.stats.flows");
    public static final PiTableId BASIC_INGRESS_TABLE0_TABLE0 =
            PiTableId.of("BasicIngress.table0.table0");
    // Indirect Counter IDs
    public static final PiActionId BASIC_INGRESS_TABLE0_COPY_TO_CPU =
            PiActionId.of("BasicIngress.table0.copy_to_cpu");;
    public static final PiActionId BASIC_INGRESS_TABLE0_DROP =
            PiActionId.of("BasicIngress.table0.drop");
    public static final PiActionId BASIC_INGRESS_TABLE0_SET_OUTPUT =
            PiActionId.of("BasicIngress.table0.set_egress_port");
    public static final PiActionId NOP = PiActionId.of("nop");
    // Action Param IDs
    public static final PiActionParamId CPU_PORT =
            PiActionParamId.of("cpu_port");
    public static final PiActionParamId PORT_NUM =
            PiActionParamId.of("port_num");
    public static final PiPacketMetadataId EGRESS_PORT =
            PiPacketMetadataId.of("egress_port");
    public static final int EGRESS_PORT_BITWIDTH = 32;
    public static final PiPacketMetadataId INGRESS_PORT =
            PiPacketMetadataId.of("ingress_port");
    public static final int INGRESS_PORT_BITWIDTH = 32;
    public static final PiPacketMetadataId PAD0 = PiPacketMetadataId.of("pad0");
    public static final int PAD0_BITWIDTH = 7;

}
