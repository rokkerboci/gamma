package hu.bme.mit.gamma.trace.model;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper;

public class TraceUtil {

	public boolean isOverWritten(RaiseEventAct lhs, RaiseEventAct rhs) {
		return lhs.getPort() == rhs.getPort() && lhs.getEvent() == rhs.getEvent();
	}
	
	public void removeCoveredExecutionTraces(List<ExecutionTrace> traces) {
		for (int i = 0; i < traces.size() - 1; ++i) {
			ExecutionTrace lhs = traces.get(i);
			boolean isLhsDeleted = false;
			for (int j = i + 1; j < traces.size() && !isLhsDeleted; ++j) {
				ExecutionTrace rhs = traces.get(j);
				if (isCovered(rhs, lhs)) {
					traces.remove(j);
					--j;
				}
				else if (isCovered(lhs, rhs)) {
					// Else is important, as it is possible that both cover the other one
					isLhsDeleted = true;
					traces.remove(i);
					--i;
				}
			}
		}
	}
	
	public void removeCoveredSteps(ExecutionTrace trace) {
		List<List<Step>> separateTracesByReset = identifySeparateTracesByReset(trace);
		removeCoveredStepLists(separateTracesByReset);
	}
	
	public List<List<Step>> identifySeparateTracesByReset(ExecutionTrace trace) {
		List<List<Step>> stepsList = new ArrayList<List<Step>>();
		List<Step> actualSteps = null;
		for (Step step : trace.getSteps()) {
			if (step.getActions().stream().anyMatch(it -> it instanceof Reset)) {
				if (actualSteps != null) {
					stepsList.add(actualSteps);
				}
				actualSteps = new ArrayList<Step>();
			}
			actualSteps.add(step);
		}
		return stepsList;
	}
	
	public void removeCoveredStepLists(List<List<Step>> traces) {
		for (int i = 0; i < traces.size() - 1; ++i) {
			List<Step> lhs = traces.get(i);
			boolean isLhsDeleted = false;
			for (int j = i + 1; j < traces.size() && !isLhsDeleted; ++j) {
				List<Step> rhs = traces.get(j);
				if (isCovered(rhs, lhs)) {
					traces.remove(j);
					EcoreUtil.removeAll(rhs);
					--j;
				}
				else if (isCovered(lhs, rhs)) {
					// Else is important, as it is possible that both cover the other one
					isLhsDeleted = true;
					traces.remove(i);
					EcoreUtil.removeAll(lhs);
					--i;
				}
			}
		}
	}
	
	public boolean isCovered(ExecutionTrace covered, ExecutionTrace covering) {
		return isCovered(covered.getSteps(), covering.getSteps());
	}
	
	public boolean isCovered(List<Step> covered, List<Step> covering) {
		if (covering.size() < covered.size()) {
			return false;
		}
		for (int i = 0; i < covered.size(); i++) {
			if (!isCovered(covered.get(i), covering.get(i))) {
				return false;
			}
		}
		return true;
	}
	
	public boolean isCovered(Step covered, Step covering) {
		// Only input actions are covered
		EList<Act> coveredActions = covered.getActions();
		EList<Act> coveringActions = covering.getActions();
		if (coveredActions.size() == coveringActions.size()) {
			for (Act act : coveredActions) {
				boolean isEqual = coveringActions.stream().anyMatch(it -> equalsTo(act, it));
				if (!isEqual) {
					return false;
				}
			}
		}
		return true;
	}
	
	public boolean equalsTo(EObject lhs, EObject rhs) {
		EqualityHelper helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}
	
}
