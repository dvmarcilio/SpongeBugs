package org.jedit.keymap;

import java.lang.Character;
import java.lang.StringBuffer;

import org.gjt.sp.jedit.Buffer;
import org.gjt.sp.jedit.EditAction;
import org.gjt.sp.jedit.Registers;
import org.gjt.sp.jedit.gui.HistoryModel;
import org.gjt.sp.jedit.gui.InputHandler;
import org.gjt.sp.jedit.jEdit;
import org.gjt.sp.jedit.textarea.Selection;
import org.gjt.sp.jedit.textarea.TextArea;

/** Emacs Macro utility functions. 

	These functions are based on EmacsUtil.bsh from the Emacs macros 
	by Brian M. Clapper.
	Rewritten in Java by Alan Ezust in 2013.
*/

public class EmacsUtil {

	Buffer buffer; 
	TextArea textArea;
	
	public EmacsUtil() {
		buffer =  jEdit.getActiveView().getBuffer();
		textArea = jEdit.getActiveView().getTextArea();
	}
	
	public void emacsKillLine()
	{
	//	boolean lastActionWasThis = repeatingSameMacro ("Emacs/Emacs_Kill_Line");
	
		int caret = textArea.getCaretPosition();		
		int caretLine = textArea.getCaretLine();
		int lineStart = textArea.getLineStartOffset (caretLine);
		int lineEnd = textArea.getLineEndOffset (caretLine);			
		
		// If we're at the end of line (ignoring any trailing white space),
		// then kill the newline, too.
		int caret2 = caret + 1;		
		while (caret2 < lineEnd)
		{
			char ch = charAt (caret2);
			
			if (! Character.isWhitespace (ch))
				break;
	
			caret2++;
		}
	
		String deletedText = null;
		Selection selection = null;
	
		if (caret2 == lineEnd)
		{
			// We're at the end of the line. Join this line and the next line--but
			// do it with a true delete, not with textArea.joinLines(), to
			// emulate emacs better.
	
//			if (caretLine == textArea.getLastPhysicalLine()) {
//				selection = new Selection.Range (caret, caret2);
//			}
		}
	
//		else
//		{
//			// Simple delete to end of line.
//	
//			selection = new Selection.Range (caret, lineEnd - 1);
//			//textArea.deleteToEndOfLine();
//		}
	
			
	}
	
}