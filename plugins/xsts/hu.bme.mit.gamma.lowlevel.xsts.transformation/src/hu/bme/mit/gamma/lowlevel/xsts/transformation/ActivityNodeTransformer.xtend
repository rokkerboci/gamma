package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.activity.model.ActionDefinition
import hu.bme.mit.gamma.activity.model.ActionNode
import hu.bme.mit.gamma.activity.model.ActivityDefinition
import hu.bme.mit.gamma.activity.model.ActivityNode
import hu.bme.mit.gamma.activity.model.DecisionNode
import hu.bme.mit.gamma.activity.model.Flow
import hu.bme.mit.gamma.activity.model.MergeNode
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InputFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutputFlows
import hu.bme.mit.gamma.statechart.lowlevel.model.TriggerNode
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static extension hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.activity.model.InitialNode
import hu.bme.mit.gamma.activity.model.FinalNode

class ActivityNodeTransformer extends LowlevelTransitionToXTransitionTransformer {
	
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	protected final extension ActivityFlowTransformer activityFlowTransformer
	
	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE 
		
	new(ViatraQueryEngine engine, Trace trace) {
		super(engine, trace)
		
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
		this.activityFlowTransformer = new ActivityFlowTransformer(this.trace)
	}
	
	protected def runningPrecondition(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)

		val expression = createAndExpression => [
			it.operands += node.activityInstance.state.createSingleXStsStateAssumption
			it.operands += createEqualityExpression(
				nodeVariable, 
				createEnumerationLiteralExpression => [
					reference = runningNodeStateEnumLiteral
				]
			)
		]
		
		return expression
	}
	
	protected def createDoneAssignmentAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)
	
		return createAssignmentAction(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = doneNodeStateEnumLiteral
			]
		)
	}
	
	protected def createRunningAssignmentAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)

		return createAssignmentAction(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = runningNodeStateEnumLiteral
			]
		)
	}
	
	protected def dispatch createNodeTransitionAction(ActionNode node) {
		if (node.activityDeclarationReference !== null) {	
			val definition = node.activityDeclarationReference.definition
			if (definition instanceof ActionDefinition) {
				// action definition, running -> execute action -> done
				return createSequentialAction => [
					it.actions += node.runningPrecondition.createAssumeAction
					it.actions += definition.action.transformAction
					it.actions += node.createDoneAssignmentAction
				]
			}				
			if (definition instanceof ActivityDefinition) {
				// TODO: activity definition, running -> execute inner activity (set inner initial, wait for final done) -> done
				return createSequentialAction => [
					it.actions += node.runningPrecondition.createAssumeAction
					it.actions += node.createDoneAssignmentAction
				]
			}
		} else {
			// Has no definition, simple running -> done
			return createSequentialAction => [
				it.actions += node.runningPrecondition.createAssumeAction
				it.actions += node.createDoneAssignmentAction
			]
		}
	}
	
	protected def dispatch createNodeTransitionAction(TriggerNode node) {
		return createSequentialAction => [
			val precondition = node.runningPrecondition
			precondition.operands += node.triggerExpression.transformExpression
			
			it.actions += precondition.createAssumeAction
			it.actions += node.createDoneAssignmentAction
		]
	}
	
	protected def dispatch createNodeTransitionAction(ActivityNode node) {
		return createSequentialAction => [
			it.actions += node.runningPrecondition.createAssumeAction
			it.actions += node.createDoneAssignmentAction
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(ActivityNode node, Iterable<Flow> inputFlows, Iterable<Flow> outputFlows) {
		return createNonDeterministicAction => [
			it.actions += createParallelAction => [
				for (flow : inputFlows) {
					it.actions += flow.transformInwards
				}
			]
			it.actions += createParallelAction => [
				for (flow : outputFlows) {
					it.actions += flow.transformOutwards
				}
			]
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(DecisionNode node, Iterable<Flow> inputFlows, Iterable<Flow> outputFlows) {
		return createRapidFireActivityNodeFlowAction(node, inputFlows, outputFlows)
	}
	
	protected dispatch def createActivityNodeFlowAction(MergeNode node, Iterable<Flow> inputFlows, Iterable<Flow> outputFlows) {
		return createRapidFireActivityNodeFlowAction(node, inputFlows, outputFlows)
	}
	
	private def createRapidFireActivityNodeFlowAction(ActivityNode node, Iterable<Flow> inputFlows, Iterable<Flow> outputFlows) {
		return createNonDeterministicAction => [
			it.actions += createNonDeterministicAction => [
				for (flow : inputFlows) {
					it.actions += flow.transformInwards
				}
			]
			it.actions += createNonDeterministicAction => [
				for (flow : outputFlows) {
					it.actions += flow.transformOutwards
				}
			]
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(InitialNode node, Iterable<Flow> inputFlows, Iterable<Flow> outputFlows) {
		return createParallelAction => [
			for (flow : outputFlows) {
				it.actions += flow.transformOutwards
			}
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(FinalNode node, Iterable<Flow> inputFlows, Iterable<Flow> outputFlows) {
		return createParallelAction => [
			for (flow : inputFlows) {
				it.actions += flow.transformInwards
			}
		]
	}
	
	def transform(ActivityNode node) {
		val inputFlows = InputFlows.Matcher.on(engine).getAllValuesOfflow(node)
		val outputFlows = OutputFlows.Matcher.on(engine).getAllValuesOfflow(node)
	
		val action = createNonDeterministicAction => [
			it.actions += node.createActivityNodeFlowAction(inputFlows, outputFlows)
			it.actions += node.createNodeTransitionAction
		]
		
		trace.put(node, action)
		
		return action.createXStsTransition		
	}
	
}