package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.List

class WaitingAllowedHandler extends AbstractAssertionHandler {

	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
		if (min == -1 && max == -1) {
			throw (new IllegalArgumentException(
				'''ExecutionTrace «trace.name» is not equiped with an AllowedWaiting annotation'''))
		}
	}

	override generateAssertBlock(List<Assert> asserts) {
		if (asserts.nullOrEmpty) {
			return ''''''
		}
		return '''
			boolean done = false;
			boolean wasPresent = true;
			int idx = 0;
			
			while (!done) {
				wasPresent = true;
				try {
					«FOR _assert : asserts»
						assertTrue(«serializer.serializeAssert(_assert)»);
					«ENDFOR»
					} catch (AssertionError error) {
					wasPresent = false;
					if (idx > «max») {
						throw(error);
					}
				}
				if (wasPresent && idx >= «min») {
					done = true;
				}
				else {
					«schedule»
				}
				idx++;
			}
		'''
	}

}