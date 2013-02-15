import java.lang.*;
import java.util.*;
import java.io.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;


public class TextPrompt {

	JFrame mwindow;
	JTextArea textwindow;
	JScrollPane scroller;
	private int pause;
	private int feed_count;

	public TextPrompt() {

		mwindow = new JFrame("Output Window");
		textwindow = new JTextArea();
		textwindow.setWrapStyleWord(true);
		textwindow.setLineWrap(true);
		textwindow.setEditable(false);
		scroller = new JScrollPane(textwindow);
		scroller.setPreferredSize(new Dimension(300,200));
		scroller.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
		mwindow.getContentPane().add(scroller, BorderLayout.CENTER);
		mwindow.pack();
		mwindow.addWindowListener(new java.awt.event.WindowAdapter() {

			public void windowClosing(java.awt.event.WindowEvent e) {
                		hide();
            		}
        	});
		printLine("Prompt open");
		feed_count = 0;
	}
	public void printLine(String in_string) {

		textwindow.append(in_string);
		textwindow.append("\n");
                textwindow.setCaretPosition(textwindow.getDocument().getLength());
	}
	public void show() {

		mwindow.setVisible(true);
	}
	public void hide() {

		mwindow.setVisible(false);
	}
	public void pauseToggle() {

		if(pause == 1) {

			pause = 0;
		} else {

			pause = 1;
		}
	}
	public int Pause() {

		return pause;
	}
	public void Feed() {

		feed_count = feed_count+1;
	}
	public int Feedings() {

		return feed_count;
	}		
}