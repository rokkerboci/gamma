/*
 * generated by Xtext 2.23.0
 */
package hu.bme.mit.gamma.theta.trace.language.parser.antlr;

import com.google.inject.Inject;
import hu.bme.mit.gamma.theta.trace.language.parser.antlr.internal.InternalTraceLanguageParser;
import hu.bme.mit.gamma.theta.trace.language.services.TraceLanguageGrammarAccess;
import org.eclipse.xtext.parser.antlr.AbstractAntlrParser;
import org.eclipse.xtext.parser.antlr.XtextTokenStream;

public class TraceLanguageParser extends AbstractAntlrParser {

	@Inject
	private TraceLanguageGrammarAccess grammarAccess;

	@Override
	protected void setInitialHiddenTokens(XtextTokenStream tokenStream) {
		tokenStream.setInitialHiddenTokens("RULE_WS", "RULE_ML_COMMENT", "RULE_SL_COMMENT");
	}
	

	@Override
	protected InternalTraceLanguageParser createParser(XtextTokenStream stream) {
		return new InternalTraceLanguageParser(stream, getGrammarAccess());
	}

	@Override 
	protected String getDefaultRuleName() {
		return "XstsStateSequence";
	}

	public TraceLanguageGrammarAccess getGrammarAccess() {
		return this.grammarAccess;
	}

	public void setGrammarAccess(TraceLanguageGrammarAccess grammarAccess) {
		this.grammarAccess = grammarAccess;
	}
}
