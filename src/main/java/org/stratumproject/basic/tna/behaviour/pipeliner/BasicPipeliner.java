// Copyright 2018-present Open Networking Foundation
// SPDX-License-Identifier: Apache-2.0

package org.stratumproject.basic.tna.behaviour.pipeliner;

import com.google.common.collect.ImmutableList;
import org.onlab.util.SharedExecutors;
import org.onosproject.core.ApplicationId;
import org.onosproject.core.CoreService;
import org.onosproject.net.DeviceId;
import org.onosproject.net.PortNumber;
import org.onosproject.net.behaviour.NextGroup;
import org.onosproject.net.behaviour.Pipeliner;
import org.onosproject.net.behaviour.PipelinerContext;
import org.onosproject.net.flow.FlowRule;
import org.onosproject.net.flow.FlowRuleOperations;
import org.onosproject.net.flow.FlowRuleService;
import org.onosproject.net.flowobjective.FilteringObjective;
import org.onosproject.net.flowobjective.FlowObjectiveStore;
import org.onosproject.net.flowobjective.ForwardingObjective;
import org.onosproject.net.flowobjective.IdNextTreatment;
import org.onosproject.net.flowobjective.NextObjective;
import org.onosproject.net.flowobjective.NextTreatment;
import org.onosproject.net.flowobjective.Objective;
import org.onosproject.net.flowobjective.ObjectiveError;
import org.onosproject.net.group.GroupDescription;
import org.onosproject.net.group.GroupService;
import org.slf4j.Logger;
import org.stratumproject.basic.tna.Constants;
import org.stratumproject.basic.tna.behaviour.AbstractBasicHandlerBehavior;
import org.stratumproject.basic.tna.behaviour.BasicCapabilities;

import java.util.Collections;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.stream.Collectors;

import static java.lang.String.format;
import static org.slf4j.LoggerFactory.getLogger;
import static org.stratumproject.basic.tna.behaviour.BasicUtils.KRYO;

import static org.stratumproject.basic.tna.behaviour.BasicUtils.outputPort;

/**
 * Pipeliner implementation for fabric-tna pipeline which uses ObjectiveTranslator
 * implementations to translate flow objectives for the different blocks,
 * filtering, forwarding and next.
 */
public class BasicPipeliner extends AbstractBasicHandlerBehavior
        implements Pipeliner {

    private static final Logger log = getLogger(BasicPipeliner.class);
    private static final int DEFAULT_FLOW_PRIORITY = 100;

    protected DeviceId deviceId;
    protected ApplicationId appId;
    protected FlowRuleService flowRuleService;
    protected GroupService groupService;
    protected FlowObjectiveStore flowObjectiveStore;
    protected CoreService coreService;
    private ForwardingObjectiveTranslator forwardingTranslator;
    private final ExecutorService callbackExecutor = SharedExecutors.getPoolThreadExecutor();

    /**
     * Creates a new instance of this behavior with the given capabilities.
     *
     * @param capabilities capabilities
     */
    public BasicPipeliner(BasicCapabilities capabilities) {
        super(capabilities);
    }

    /**
     * Create a new instance of this behaviour. Used by the abstract projectable
     * model (i.e., {@link org.onosproject.net.Device#as(Class)}.
     */
    public BasicPipeliner() {
        super();
    }

    @Override
    public void init(DeviceId deviceId, PipelinerContext context) {
        this.deviceId = deviceId;
        this.flowRuleService = context.directory().get(FlowRuleService.class);
        this.groupService = context.directory().get(GroupService.class);
        this.flowObjectiveStore = context.directory().get(FlowObjectiveStore.class);
        this.forwardingTranslator = new ForwardingObjectiveTranslator(deviceId, capabilities);
        this.coreService = context.directory().get(CoreService.class);
        this.appId = coreService.getAppId(Constants.APP_NAME);
    }

    @Override
    public void filter(FilteringObjective obj) {
    }

    @Override
    public void forward(ForwardingObjective obj) {
        final ObjectiveTranslation result = forwardingTranslator.translate(obj);
        handleResult(obj, result);
    }

    @Override
    public void next(NextObjective obj) {}

    @Override
    public void purgeAll(ApplicationId appId) {
        flowRuleService.purgeFlowRules(deviceId, appId);
        groupService.purgeGroupEntries(deviceId, appId);
        //FIXME: purge flowObjectiveStore as well when addressing SDFAB-250.
        // Currently we don't have enough information in the store to purge by app and device ID
    }

    @Override
    public List<String> getNextMappings(NextGroup nextGroup) {
        return Collections.emptyList();
    }

    private void handleResult(Objective obj, ObjectiveTranslation result) {
        if (result.error().isPresent()) {
            fail(obj, result.error().get());
            return;
        }
        processFlows(obj, result.flowRules());
        success(obj);
    }

    private void processFlows(Objective objective, Collection<FlowRule> flowRules) {
        if (flowRules.isEmpty()) {
            return;
        }

        if (log.isTraceEnabled()) {
            log.trace("Objective {} -> Flows {}", objective, flowRules);
        }

        final FlowRuleOperations.Builder ops = FlowRuleOperations.builder();
        switch (objective.op()) {
            case ADD:
            case ADD_TO_EXISTING:
            case MODIFY:
                flowRules.forEach(ops::add);
                break;
            case REMOVE:
            case REMOVE_FROM_EXISTING:
                flowRules.forEach(ops::remove);
                break;
            default:
                log.warn("Unsupported Objective operation {}", objective.op());
                return;
        }
        flowRuleService.apply(ops.build());
    }

    private void fail(Objective objective, ObjectiveError error) {
        CompletableFuture.runAsync(
                () -> objective.context().ifPresent(
                        ctx -> ctx.onError(objective, error)), callbackExecutor);

    }

    private void success(Objective objective) {
        CompletableFuture.runAsync(
                () -> objective.context().ifPresent(
                        ctx -> ctx.onSuccess(objective)), callbackExecutor);
    }
}
