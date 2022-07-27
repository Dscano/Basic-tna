// Copyright 2018-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

package org.stratumproject.basic.tna.behaviour;

import org.onlab.util.KryoNamespace;
import org.onosproject.net.PortNumber;
import org.onosproject.net.flow.TrafficTreatment;
import org.onosproject.net.flow.instructions.Instruction;
import org.onosproject.net.flow.instructions.Instructions;
import org.onosproject.net.flowobjective.DefaultNextTreatment;
import org.onosproject.net.flowobjective.NextTreatment;
import org.onosproject.net.pi.model.PiPipelineInterpreter;
import org.onosproject.net.pi.model.PiTableId;
import org.onosproject.store.serializers.KryoNamespaces;

import static java.lang.String.format;

/**
 * Utility class with methods common to basic-tna pipeconf operations.
 */
public final class BasicUtils {

    public static final KryoNamespace KRYO = new KryoNamespace.Builder()
            .register(KryoNamespaces.API)
            .build("BasicTnaPipeconf");

    private BasicUtils() {
        // Hides constructor.
    }

    public static Instruction instruction(TrafficTreatment treatment, Instruction.Type type) {
        return treatment.allInstructions()
                .stream()
                .filter(inst -> inst.type() == type)
                .findFirst().orElse(null);
    }

    public static Instructions.OutputInstruction outputInstruction(TrafficTreatment treatment) {
        return (Instructions.OutputInstruction) instruction(treatment, Instruction.Type.OUTPUT);
    }

    public static PortNumber outputPort(TrafficTreatment treatment) {
        final Instructions.OutputInstruction inst = outputInstruction(treatment);
        return inst == null ? null : inst.port();
    }

    public static PortNumber outputPort(NextTreatment treatment) {
        if (treatment.type() == NextTreatment.Type.TREATMENT) {
            final DefaultNextTreatment t = (DefaultNextTreatment) treatment;
            return outputPort(t.treatment());
        }
        return null;
    }

    public static void treatmentException(
            PiTableId tableId, TrafficTreatment treatment, String explanation)
            throws PiPipelineInterpreter.PiInterpreterException {
        throw new PiPipelineInterpreter.PiInterpreterException(format(
                "Invalid treatment for table '%s', %s: %s", tableId, explanation, treatment));
    }
}
