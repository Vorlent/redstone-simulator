import gtk.MainWindow;
import gtk.Label;
import gtk.Main;
import gtk.DrawingArea;
import gtk.Toolbar;
import gtk.ToolButton;
import gtk.Box;
import gtkc.gtktypes : GtkOrientation;

void main(string[] args)
{
		Main.init(args);
		MainWindow win = new MainWindow("Redstone Simulator");
		win.setDefaultSize(800, 600);
		Toolbar toolbar = new Toolbar();
		toolbar.insert(new ToolButton(null, "Run"));
		toolbar.insert(new ToolButton(null, "Stop"));
		Box box = new Box(GtkOrientation.VERTICAL, 10);
		box.add(toolbar);
		box.add(new DrawingArea(800, 600));
		win.add(box);

		win.showAll();
		Main.run();
}
