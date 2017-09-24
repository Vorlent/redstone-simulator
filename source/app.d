import gtk.MainWindow;
import gtk.Label;
import gtk.Main;
import gtk.DrawingArea;
import gtk.Toolbar;
import gtk.ToolButton;
import gtk.Box;
import gtk.Widget;
import gtkc.gtktypes : GtkOrientation;
import cairo.Context;

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

		double[][] colors = [
			[0.3, 0.6, 0.3],
			[0.0, 0.0, 0.0],
			[0.3, 0.3, 0.6],
			[0.6, 0.6, 0.3],
			[0.3, 0.6, 0.6],
			[0.6, 0.6, 0.6],
			[0.3, 0.3, 0.3],
			[0.8, 0.6, 0.3],
			[0.8, 0.8, 0.3],
			[0.3, 0.8, 0.8],
			[0.2, 0.5, 0.8],
			[0.9, 0.6, 0.3],
			[0.3, 0.9, 0.7],
			[0.1, 0.1, 0.5],
			[0.7, 0.7, 0.7],
			[0.6, 0.0, 0.6]
		];

		int width = 16;
		int height = 16;

		byte[] grid = new byte[width * height];

		byte lastColor = 0;
		foreach(x; 0..width) {
				foreach(y; 0..height) {
						grid[y * width + x] = lastColor;
						lastColor++;
						if(lastColor >= 16) {
								lastColor = 0;
						}
				}
		}

		DrawingArea drawingArea = new DrawingArea(800, 600);
		drawingArea.addOnDraw((Scoped!Context cr, Widget widget) {
			foreach(x; 0..width) {
					foreach(y; 0..height) {
						cr.save();
								byte color = grid[y * width + x];
								cr.setSourceRgba(colors[color][0], colors[color][1], colors[color][2], 1.0);
								cr.translate(2 + x * 17, 2 + y * 17);
								cr.rectangle(0.0, 0.0, 16.0, 16.0);
								cr.fill();
						cr.restore();
					}
			}
			return false;
		});
		box.add(drawingArea);
		win.add(box);

		win.showAll();
		Main.run();
}
