// Copyright 2020-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

package org.stratumproject.basic.tna;

/**
 * Constant values.
 */
public final class Constants {

    // TODO: use consistent naming, and potentially just one app name
    //  After all, the actual app in the ONOS sense is just one.
    public static final String APP_NAME = "org.stratumproject.basic-tna";

    // Architectures
    public static final String V1MODEL = "v1model";
    public static final String TNA = "tna";

    public static final long PORT_CPU = 0xFFFFFFFDL;
    public static final long PORT_CPU_BMV2 = 255;

    // hide default constructor
    private Constants() {
    }
}
