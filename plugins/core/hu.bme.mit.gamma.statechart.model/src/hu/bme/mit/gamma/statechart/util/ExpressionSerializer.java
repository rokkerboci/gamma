package hu.bme.mit.gamma.statechart.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.statechart.model.interface_.EventParameterReferenceExpression;

public class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {

	private static ExpressionSerializer instance = null;
	
	public static ExpressionSerializer getInstance() {
		if (instance == null) {
			instance = new ExpressionSerializer();
		}
		return instance;
	}
	
	protected ExpressionSerializer() {}
	
	// Singleton
	
	protected String _serialize(EventParameterReferenceExpression expression) {
		return expression.getPort().getName() + "." + expression.getEvent().getName() + "::"
				+ expression.getParameter().getName();
	}

	public String serialize(Expression expression) {
		try {
			return super.serialize(expression);
		} catch (IllegalArgumentException e) {
			if (expression instanceof EventParameterReferenceExpression) {
				return _serialize((EventParameterReferenceExpression) expression);
			}
		}
		throw new IllegalArgumentException("Unhandled parameter types: " + expression);
	}

}
