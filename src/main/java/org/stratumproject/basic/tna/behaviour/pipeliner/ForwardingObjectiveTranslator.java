// Copyright 2017-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

package org.stratumproject.basic.tna.behaviour.pipeliner;

import com.google.common.collect.ImmutableSet;
import org.onosproject.net.DeviceId;
import org.onosproject.net.PortNumber;
import org.onosproject.net.flow.DefaultTrafficTreatment;
import org.onosproject.net.flow.TrafficTreatment;
import org.onosproject.net.flow.criteria.Criterion;
import org.onosproject.net.flowobjective.ForwardingObjective;
import org.onosproject.net.flowobjective.ObjectiveError;
import org.onosproject.net.pi.runtime.PiAction;
import org.stratumproject.basic.tna.behaviour.BasicCapabilities;
import org.stratumproject.basic.tna.behaviour.P4InfoConstants;

import java.util.Set;
import java.util.stream.Collectors;

import static java.lang.String.format;
import static org.stratumproject.basic.tna.behaviour.BasicUtils.outputPort;

/**
 * ObjectiveTranslator implementation ForwardingObjective.
 */
class ForwardingObjectiveTranslator
        extends AbstractObjectiveTranslator<ForwardingObjective> {

    //FIXME: Max number supported by PI
    static final int CLONE_TO_CPU_ID = 511;

    private static final Set<Criterion.Type> TABLE0_CRITERIA = ImmutableSet.of(
            Criterion.Type.IN_PORT,
            Criterion.Type.ETH_DST,
            Criterion.Type.ETH_SRC,
            Criterion.Type.ETH_TYPE,
            Criterion.Type.IP_PROTO,
            Criterion.Type.IPV4_SRC,
            Criterion.Type.IPV4_DST,
            Criterion.Type.TCP_SRC,
            Criterion.Type.TCP_DST,
            Criterion.Type.UDP_SRC,
            Criterion.Type.UDP_DST);

    ForwardingObjectiveTranslator(DeviceId deviceId, BasicCapabilities capabilities) {
        super(deviceId, capabilities);
    }

    @Override
    public ObjectiveTranslation doTranslate(ForwardingObjective obj)
            throws BasicPipelinerException {

        final ObjectiveTranslation.Builder resultBuilder =
                ObjectiveTranslation.builder();
        switch (obj.flag()) {
            case VERSATILE:
                processVersatileFwd(obj, resultBuilder);
                break;
            case EGRESS:
            default:
                log.warn("Unsupported ForwardingObjective type '{}'", obj.flag());
                return ObjectiveTranslation.ofError(ObjectiveError.UNSUPPORTED);
        }
        return resultBuilder.build();
    }

    private void processVersatileFwd(ForwardingObjective obj,
                                     ObjectiveTranslation.Builder resultBuilder)
            throws BasicPipelinerException {

        final Set<Criterion.Type> unsupportedCriteria = obj.selector().criteria()
                .stream()
                .map(Criterion::type)
                .filter(t -> !TABLE0_CRITERIA.contains(t))
                .collect(Collectors.toSet());

        if (!unsupportedCriteria.isEmpty()) {
            throw new BasicPipelinerException(format(
                    "unsupported ACL criteria %s", unsupportedCriteria.toString()));
        }

        table0Rule(obj, resultBuilder);
    }

    private void table0Rule(ForwardingObjective obj,
                            ObjectiveTranslation.Builder resultBuilder)
            throws BasicPipelinerException {
        if (obj.nextId() == null && obj.treatment() != null) {
            final TrafficTreatment treatment = obj.treatment();
            final PortNumber outPort = outputPort(treatment);
            if (outPort != null
                    && outPort.equals(PortNumber.CONTROLLER)
                    && treatment.allInstructions().size() == 1) {
                final PiAction aclAction;
                    // Action is COPY_TO_CPU
                    aclAction = PiAction.builder()
                            .withId(P4InfoConstants.BASIC_INGRESS_TABLE0_COPY_TO_CPU)
                            .build();
                final TrafficTreatment piTreatment = DefaultTrafficTreatment.builder()
                        .piTableAction(aclAction)
                        .build();
                resultBuilder.addFlowRule(flowRule(
                        obj, P4InfoConstants.BASIC_INGRESS_TABLE0_TABLE0, obj.selector(), piTreatment));
                return;
            }
        }
    }


}
