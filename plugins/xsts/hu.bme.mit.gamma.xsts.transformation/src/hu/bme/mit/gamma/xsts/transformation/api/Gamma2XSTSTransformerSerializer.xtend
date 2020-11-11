package hu.bme.mit.gamma.xsts.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.AnalysisModelPreprocessor
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.ModelSlicerModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceAndPortReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceReferences
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.GammaToXSTSTransformer
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer
import java.io.File
import java.util.List

class Gamma2XSTSTransformerSerializer {
	
	protected final Component component
	protected final List<Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	protected final Integer schedulingConstraint
	// Slicing
	protected final PropertyPackage propertyPackage
	// Annotation
	protected final ComponentInstanceReferences testedComponentsForStates
	protected final ComponentInstanceReferences testedComponentsForTransitions
	protected final ComponentInstanceReferences testedComponentsForTransitionPairs
	protected final ComponentInstanceReferences testedComponentsForOutEvents
	protected final ComponentInstanceAndPortReferences testedPortsForInteractions
	
	protected final AnalysisModelPreprocessor preprocessor = AnalysisModelPreprocessor.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName) {
		this(component, arguments, targetFolderUri, fileName, null)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint) {
		this(component, arguments, targetFolderUri, fileName, schedulingConstraint,
			null, null, null, null, null, null)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint,
			PropertyPackage propertyPackage,
			ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstanceReferences testedComponentsForOutEvents,
			ComponentInstanceAndPortReferences testedPortsForInteractions) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.schedulingConstraint = schedulingConstraint
		//
		this.propertyPackage = propertyPackage
		//
		this.testedComponentsForStates = testedComponentsForStates
		this.testedComponentsForTransitions = testedComponentsForTransitions
		this.testedComponentsForTransitionPairs = testedComponentsForTransitionPairs
		this.testedComponentsForOutEvents = testedComponentsForOutEvents
		this.testedPortsForInteractions = testedPortsForInteractions
	}
	
	def void execute() {
		val gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component)
		// Preprocessing
		val newTopComponent = preprocessor.preprocess(gammaPackage, arguments, targetFolderUri, fileName)
		val newGammaPackage = StatechartModelDerivedFeatures.getContainingPackage(newTopComponent)
		// Slicing and Property generation
		val slicerAnnotatorAndPropertyGenerator = new ModelSlicerModelAnnotatorPropertyGenerator(
				newTopComponent,
				propertyPackage,
				testedComponentsForStates, testedComponentsForTransitions,
				testedComponentsForTransitionPairs, testedComponentsForOutEvents,
				testedPortsForInteractions,
				targetFolderUri, fileName)
		slicerAnnotatorAndPropertyGenerator.execute
		val gammaToXSTSTransformer = new GammaToXSTSTransformer(schedulingConstraint, true, true)
		// Normal transformation
		val xSts = gammaToXSTSTransformer.execute(newGammaPackage)
		// EMF
		xSts.normalSave(targetFolderUri, fileName.emfXStsFileName)
		// String
		val xStsFile = new File(targetFolderUri + File.separator + fileName.xtextXStsFileName)
		val xStsString = xSts.serializeXSTS
		xStsFile.saveString(xStsString)
	}
	
}