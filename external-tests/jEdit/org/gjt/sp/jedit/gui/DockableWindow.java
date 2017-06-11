package org.gjt.sp.jedit.gui;

/** An interface for notifying MOVABLE dockable windows before their docking position is changed.
 *
 * @author Shlomy Reinstein
 * @version $Id: DockableWindow.java 21502 2012-03-29 17:19:44Z ezust $
 * @since jEdit 4.3pre11
 */

public interface DockableWindow {
	//{{{ Move notification
	/**
	 * Notifies a dockable window before its docking position is changed.
	 * @param newPosition The docking position to which the window is moving.
	 * @since jEdit 4.3pre11
	 */
	void move(String newPosition);
	//}}}
}
