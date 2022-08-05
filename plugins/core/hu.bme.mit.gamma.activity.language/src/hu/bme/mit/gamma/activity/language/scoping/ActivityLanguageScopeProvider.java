/*
 * generated by Xtext 2.23.0
 */
package hu.bme.mit.gamma.activity.language.scoping;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures;
import hu.bme.mit.gamma.activity.model.ActivityModelPackage;
import hu.bme.mit.gamma.activity.model.CompositeNode;
import hu.bme.mit.gamma.activity.model.InputPin;
import hu.bme.mit.gamma.activity.model.InsidePinReference;
import hu.bme.mit.gamma.activity.model.OutputPin;
import hu.bme.mit.gamma.activity.model.OutsidePinReference;
import hu.bme.mit.gamma.activity.model.PinReference;
import hu.bme.mit.gamma.activity.model.PinnedNode;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class ActivityLanguageScopeProvider extends AbstractActivityLanguageScopeProvider {
	
	@Override
	public IScope getScope(final EObject context, final EReference reference) {

		try {			
			if (context instanceof PinReference) {
				
				if (context instanceof InsidePinReference) {
					InsidePinReference pinReference = (InsidePinReference) context;
					
					PinnedNode node = ActivityModelDerivedFeatures.getContainingPinnedNode(pinReference);
					
					if (reference == ActivityModelPackage.Literals.OUTPUT_PIN_REFERENCE__OUTPUT_PIN) {						
						return Scopes.scopeFor(node.getPins().stream().filter(pin -> pin instanceof OutputPin).toList());
					}
					if (reference == ActivityModelPackage.Literals.INPUT_PIN_REFERENCE__INPUT_PIN) {
						return Scopes.scopeFor(node.getPins().stream().filter(pin -> pin instanceof InputPin).toList());
					}
				}
				else { // instanceof OutsidePinReference
					OutsidePinReference pinReference = (OutsidePinReference) context;
					
					if (reference == ActivityModelPackage.Literals.OUTSIDE_PIN_REFERENCE__ACTION_NODE) {
						CompositeNode node = ActivityModelDerivedFeatures.getContainingCompositeNode(pinReference);
						
						return Scopes.scopeFor(node.getActivityNodes());
					}

					PinnedNode node = pinReference.getActionNode();
					
					if (reference == ActivityModelPackage.Literals.OUTPUT_PIN_REFERENCE__OUTPUT_PIN) {						
						return Scopes.scopeFor(node.getPins().stream().filter(pin -> pin instanceof OutputPin).toList());
					}
					if (reference == ActivityModelPackage.Literals.INPUT_PIN_REFERENCE__INPUT_PIN) {						
						return Scopes.scopeFor(node.getPins().stream().filter(pin -> pin instanceof InputPin).toList());
					}
					
				} 
				
			}
		} catch (Exception e) {
			e.printStackTrace();
		} 
		
		return super.getScope(context, reference);
	}
	
}
