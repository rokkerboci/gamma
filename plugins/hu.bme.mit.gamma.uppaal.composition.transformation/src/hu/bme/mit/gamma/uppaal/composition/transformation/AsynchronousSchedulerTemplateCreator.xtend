package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.SimpleWrapperInstances
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopAsyncCompositeComponents
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopWrapperComponents
import java.util.Optional
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import uppaal.NTA
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DeclarationsPackage
import uppaal.declarations.Variable
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.LogicalOperator
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind
import uppaal.templates.SynchronizationKind
import uppaal.templates.TemplatesPackage

import static hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

class AsynchronousSchedulerTemplateCreator {
	// NTA
	final NTA nta
	// Transformation rule-related extensions
	protected extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	protected final extension IModelManipulations manipulation
	// Trace
	protected final extension Trace modelTrace
	// Engine
	protected final extension ViatraQueryEngine engine
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Async scheduler
	protected Scheduler asyncScheduler = Scheduler.RANDOM
	// Orchestrating period for top sync components
	protected final TimeSpecification minimalOrchestratingPeriod
	protected final TimeSpecification maximalOrchestratingPeriod
	// Id
	var id = 0
	protected final DataVariableDeclaration isStableVar
	// Auxiliary objects
    protected final extension InPlaceExpressionTransformer inPlaceExpressionTransformer = new InPlaceExpressionTransformer
	protected final extension NtaBuilder ntaBuilder
	protected final extension CompareExpressionCreator compareExpressionCreator
	protected final extension AsynchronousComponentHelper asynchronousComponentHelper
	protected final extension ExpressionEvaluator expressionEvaluator
	protected final extension AssignmentExpressionCreator assignmentExpressionCreator
	// Rules
	protected BatchTransformationRule<TopWrapperComponents.Match, TopWrapperComponents.Matcher> topWrapperSchedulerRule
	protected BatchTransformationRule<TopAsyncCompositeComponents.Match, TopAsyncCompositeComponents.Matcher> instanceWrapperSchedulerRule
	
	new(NtaBuilder ntaBuilder, ViatraQueryEngine engine, IModelManipulations manipulation,
			CompareExpressionCreator compareExpressionCreator, Trace modelTrace,
			DataVariableDeclaration isStableVar, AsynchronousComponentHelper asynchronousComponentHelper,
			ExpressionEvaluator expressionEvaluator, AssignmentExpressionCreator assignmentExpressionCreator,
			TimeSpecification minimalOrchestratingPeriod, TimeSpecification maximalOrchestratingPeriod,
			Scheduler asyncScheduler) {
		this.ntaBuilder = ntaBuilder
		this.nta = ntaBuilder.nta
		this.manipulation = manipulation
		this.engine = engine
		this.modelTrace = modelTrace
		this.isStableVar = isStableVar
		this.compareExpressionCreator = compareExpressionCreator
		this.asynchronousComponentHelper = asynchronousComponentHelper
		this.expressionEvaluator = expressionEvaluator
		this.assignmentExpressionCreator = assignmentExpressionCreator
		this.minimalOrchestratingPeriod = minimalOrchestratingPeriod
		this.maximalOrchestratingPeriod = maximalOrchestratingPeriod
		this.asyncScheduler = asyncScheduler
	}
	
	def getTopWrapperSchedulerRule() {
		if (topWrapperSchedulerRule === null) {
			topWrapperSchedulerRule = createRule(TopWrapperComponents.instance).action [
				val initLoc = createTemplateWithInitLoc(it.wrapper.name + "Scheduler" + id++, "InitLoc")
				val asyncSchedulerChannelVariable = wrapper.asyncSchedulerChannel.variable.head
				initLoc.createRandomScheduler(asyncSchedulerChannelVariable)
			].build
		}
	}
	
	def getInstanceWrapperSchedulerRule() {
		if (instanceWrapperSchedulerRule === null) {
			instanceWrapperSchedulerRule = createRule(TopAsyncCompositeComponents.instance).action [
				val initLoc = createTemplateWithInitLoc(it.asyncComposite.name + "Scheduler" + id++, "InitLoc")
				var Edge lastEdge = null
				for (instance : SimpleWrapperInstances.Matcher.on(engine).allValuesOfinstance) {
					switch (asyncScheduler) {
						case FAIR: {
							lastEdge = lastEdge.createFairScheduler(initLoc, instance)
						}
						default: {
							val asyncSchedulerChannelVariable = instance.asyncSchedulerChannel.variable.head
							lastEdge = initLoc.createRandomScheduler(asyncSchedulerChannelVariable)
						}
					}
				}
			].build
		}
	}
	
	private def createFairScheduler(Edge edge, Location initLoc, AsynchronousComponentInstance instance) {
   		var lastEdge = edge
   		val syncVariable = instance.asyncSchedulerChannel.variable.head
		if (lastEdge === null) {
			// Creating first edge
			lastEdge = initLoc.createEdge(initLoc)
			lastEdge.setSynchronization(syncVariable, SynchronizationKind.SEND)
			lastEdge.addInitializedGuards // Only if the instance is initialized
		}
		else {
			// Creating scheduling edges for all instances
			val schedulingEdge = createCommittedSyncTarget(lastEdge.target, syncVariable, "schedule" + instance.name)
			schedulingEdge.source.locationTimeKind = LocationKind.URGENT
			lastEdge.target = schedulingEdge.source
			lastEdge = schedulingEdge
		}
		return lastEdge
	}

	private def createRandomScheduler(Location initLoc, Variable asyncSchedulerChannelVariable) {
		// Creating the loop edge
		val loopEdge = initLoc.createEdge(initLoc)
		loopEdge.setSynchronization(asyncSchedulerChannelVariable, SynchronizationKind.SEND)
		// Adding isStable guard
		loopEdge.addGuard(isStableVar, LogicalOperator.AND)
		loopEdge.addInitializedGuards // Only if the instance is initialized
		// Checking scheduler constraints
		val minTimeoutValue = if (minimalOrchestratingPeriod === null) {
			Optional.ofNullable(null)
		} else {
			Optional.ofNullable(minimalOrchestratingPeriod.convertToMs.evaluate)
		}
		val maxTimeoutValue = if (maximalOrchestratingPeriod === null) {
			Optional.ofNullable(null)
		} else {
			Optional.ofNullable(maximalOrchestratingPeriod.convertToMs.evaluate)
		}
		if (minTimeoutValue.present || maxTimeoutValue.present) {
			val parentTemplate = initLoc.parentTemplate
			// Creating an Uppaal clock var
			val clockVar = parentTemplate.declarations.createChild(declarations_Declaration, clockVariableDeclaration) as ClockVariableDeclaration
			clockVar.createTypeAndVariable(nta.clock, clockNamePrefix + asyncSchedulerChannelVariable.name + id++)
			// Creating the guard
			if (minTimeoutValue.present) {
				loopEdge.createMinTimeGuard(clockVar, minTimeoutValue.get)
			}
			// Creating the location invariant
			if (maxTimeoutValue.present) {
				initLoc.createMaxTimeInvariant(clockVar, maxTimeoutValue.get)
			}
			// Creating the clock reset
			loopEdge.createAssignmentExpression(edge_Update, clockVar, createLiteralExpression => [it.text = "0"])
		}
		return loopEdge
	}
	
	enum Scheduler {FAIR, RANDOM}
	
}