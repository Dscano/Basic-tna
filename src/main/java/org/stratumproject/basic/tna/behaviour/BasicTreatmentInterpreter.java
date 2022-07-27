// Copyright 2017-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

package org.stratumproject.basic.tna.behaviour;

import com.google.common.collect.ImmutableMap;
import org.onosproject.net.flow.TrafficTreatment;
import org.onosproject.net.flow.instructions.Instruction;
import org.onosproject.net.flow.instructions.Instructions.OutputInstruction;
import org.onosproject.net.pi.model.PiActionId;
import org.onosproject.net.pi.model.PiPipelineInterpreter.PiInterpreterException;
import org.onosproject.net.pi.model.PiTableId;
import org.onosproject.net.pi.runtime.PiAction;
import org.onosproject.net.pi.runtime.PiActionParam;
import org.slf4j.Logger;
import org.stratumproject.basic.tna.behaviour.pipeliner.BasicPipeliner;

import static java.lang.String.format;
import static org.onosproject.net.flow.instructions.Instruction.Type.OUTPUT;
import static org.slf4j.LoggerFactory.getLogger;
import static org.stratumproject.basic.tna.behaviour.BasicUtils.treatmentException;
import static org.stratumproject.basic.tna.behaviour.P4InfoConstants.PORT_NUM;

/**
 * Treatment translation logic.
 */
final class BasicTreatmentInterpreter {

    private final BasicCapabilities capabilities;

    private static final Logger log = getLogger(BasicPipeliner.class);

    private static final ImmutableMap<PiTableId, PiActionId> SET_OUTPUT_ACTIONS =
            ImmutableMap.<PiTableId, PiActionId>builder()
                    .put(P4InfoConstants.BASIC_INGRESS_TABLE0_TABLE0,
                            P4InfoConstants.BASIC_INGRESS_TABLE0_SET_OUTPUT)
                    .build();
    private static final ImmutableMap<PiTableId, PiActionId> DROP_ACTIONS =
            ImmutableMap.<PiTableId, PiActionId>builder()
                    .put(P4InfoConstants.BASIC_INGRESS_TABLE0_TABLE0,
                            P4InfoConstants.BASIC_INGRESS_TABLE0_DROP)
                    .build();

    BasicTreatmentInterpreter(BasicCapabilities capabilities) {
        this.capabilities = capabilities;
    }

    static PiAction mapTable0Treatment(TrafficTreatment treatment, PiTableId tableId)
            throws PiInterpreterException {
        if (isDrop(treatment)) {
            return drop(tableId);
        }
        if (isOutput(treatment)) {
            Instruction instruction = treatment.allInstructions().get(0);
            return setOutput(tableId, (OutputInstruction) instruction);
        }
        treatmentException(
                tableId, treatment,
                "unsupported treatment");
        // This function will never return null
        return null;
    }

    private static PiAction setOutput(PiTableId tableId, OutputInstruction instruction)
            throws PiInterpreterException {
        if (!SET_OUTPUT_ACTIONS.containsKey(tableId)) {
            throw new PiInterpreterException(format("table '%s' doe not specify a nop action", tableId));
        }
        return PiAction.builder()
                .withId(SET_OUTPUT_ACTIONS.get(tableId))
                .withParameter(new PiActionParam(PORT_NUM, instruction.port().toLong()))
                .build();
    }

    private static PiAction drop(PiTableId tableId) throws PiInterpreterException {
        if (!DROP_ACTIONS.containsKey(tableId)) {
            throw new PiInterpreterException(format("table '%s' doe not specify a drop action", tableId));
        }
        return PiAction.builder().withId(DROP_ACTIONS.get(tableId)).build();
    }

    private static boolean isDrop(TrafficTreatment treatment) {
        return treatment.allInstructions().isEmpty() && treatment.clearedDeferred();
    }

    private static boolean isOutput(TrafficTreatment treatment) {
        return treatment.allInstructions().get(0).type().equals(OUTPUT);
    }
}
