// Copyright 2018-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

package org.stratumproject.basic.tna.behaviour;

import org.onosproject.net.pi.model.PiPipeconf;
import org.slf4j.Logger;
import java.util.Optional;

import static com.google.common.base.Preconditions.checkNotNull;
import static org.slf4j.LoggerFactory.getLogger;
import static org.stratumproject.basic.tna.Constants.PORT_CPU_BMV2;
import static org.stratumproject.basic.tna.Constants.TNA;
import static org.stratumproject.basic.tna.Constants.V1MODEL;
import static org.stratumproject.basic.tna.Constants.PORT_CPU;

/**
 * Representation of the capabilities of a given fabric-tna pipeconf.
 */
public class BasicCapabilities {

    private static final String MAVERICKS = "mavericks";
    private static final String MONTARA = "montara";

    private final Logger log = getLogger(getClass());

    private final PiPipeconf pipeconf;

    public BasicCapabilities(PiPipeconf pipeconf) {
        this.pipeconf = checkNotNull(pipeconf);
    }

    public int hwPipeCount() {
        // FIXME: use chip type (or platform name) when Stratum will support
        //  reading that via gNMI. Until then, we need to rely on the
        //  pipeconf name (which prevents us from using chip-independent
        //  pipeconfs).
        final var id = pipeconf.id().toString();
        if (id.contains(MONTARA)) {
            return 2;
        } else if (id.contains(MAVERICKS)) {
            return 4;
        } else {
            log.error("Unable to derive HW pipe count from pipeconf ID: {}", id);
            return 0;
        }
    }

    public boolean isArchV1model() {
        return pipeconf.pipelineModel().architecture()
                .map(a -> a.equals(V1MODEL))
                .orElse(false);
    }

    public boolean isArchTna() {
        return pipeconf.pipelineModel().architecture()
                .map(a -> a.equals(TNA))
                .orElse(false);
    }

    public Optional<Long> cpuPort() {
        return isArchTna() ? Optional.of(PORT_CPU) : Optional.of(PORT_CPU_BMV2);
    }

}
