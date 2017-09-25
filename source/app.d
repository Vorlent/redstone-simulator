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
import std.stdio : writeln;
import gdk.Event;

enum tileWidth = 16 + 1;
enum mouseLeftButton = 1;
enum mouseMiddleButton = 2;

void main(string[] args)
{
		Main.init(args);
		MainWindow win = new MainWindow("Redstone Simulator");
		win.setDefaultSize(800, 600);
		Toolbar toolbar = new Toolbar();

		Box box = new Box(GtkOrientation.VERTICAL, 10);

		double[][] colors = [
			[1.0, 1.0, 1.0],
			[1.0, 0.0, 0.0],
			[1.0, 0.5, 0.0],
			[0.6, 0.6, 0.6],
			[0.4, 0.4, 0.4],
			[0.0, 0.0, 0.0]
		];

		int width = 16;
		int height = 16;

		long dragX = 0;
		long dragY = 0;
		bool dragged = false;

		long cameraX = 0;
		long cameraY = 0;

		byte[] grid = new byte[width * height];

		byte pickedColor = 0;

		byte lastColor = 0;
		foreach(x; 0..width) {
				foreach(y; 0..height) {
						grid[y * width + x] = lastColor;
						lastColor++;
						if(lastColor >= 6) {
								lastColor = 0;
						}
				}
		}

		DrawingArea drawingArea = new DrawingArea(800, 600);
		drawingArea.addOnDraw((Scoped!Context cr, Widget widget) {
			cr.translate(-cameraX, -cameraY);

			foreach(x; 0..width) {
					foreach(y; 0..height) {
						cr.save();
								byte color = grid[y * width + x];
								cr.setSourceRgba(colors[color][0], colors[color][1], colors[color][2], 1.0);
								cr.translate(2 + x * tileWidth, 2 + y * tileWidth);
								cr.rectangle(0.0, 0.0, 16.0, 16.0);
								cr.fill();
						cr.restore();
					}
			}
			return false;
		});
		drawingArea.addOnButtonPress((Event event, Widget widget) {
				uint button;
				double xWin;
				double yWin;
				if(event.getButton(button) && event.getCoords(xWin, yWin)) {
						if(button == mouseLeftButton) {
								ulong index = width * cast(ulong)((yWin + cameraY) / tileWidth) + cast(ulong)((xWin + cameraX) / tileWidth);
								if(index < grid.length) {
										grid[index] = pickedColor;
										widget.queueDraw();
								}
						}
						if(button == mouseMiddleButton) {
								dragX = cast(ulong)xWin;
								dragY = cast(ulong)yWin;
								dragged = true;
						}
				}
				return false;
		});
		drawingArea.addOnButtonRelease ((Event event, Widget widget) {
				uint button;
				double xWin;
				double yWin;
				if(event.getButton(button) && event.getCoords(xWin, yWin)) {
						if(button == mouseMiddleButton) {
								dragged = false;
						}
				}
				return false;
		});
		drawingArea.addOnMotionNotify((Event event, Widget widget) {
				double xWin;
				double yWin;
				if(event.getCoords(xWin, yWin)) {
						if(dragged) {
								cameraX += dragX - cast(long)xWin;
								cameraY += dragY - cast(long)yWin;
								dragX = cast(ulong)xWin;
								dragY = cast(ulong)yWin;
								widget.queueDraw();
						}
				}
				return false;
		});

		ToolButton runButton = new ToolButton(null, "Run");
		toolbar.insert(runButton);
		runButton.addOnClicked ((ToolButton tb) {
				writeln("Run");
		});

		ToolButton stopButton = new ToolButton(null, "Stop");
		toolbar.insert(stopButton);
		stopButton.addOnClicked ((ToolButton tb) {
				writeln("Stop");
		});

		ToolButton blankButton = new ToolButton(null, "Blank");
		toolbar.insert(blankButton);
		blankButton.addOnClicked ((ToolButton tb) {
				pickedColor = 0;
		});

		ToolButton redstoneDustButton = new ToolButton(null, "Redstone Dust");
		toolbar.insert(redstoneDustButton);
		redstoneDustButton.addOnClicked ((ToolButton tb) {
				pickedColor = 1;
		});

		ToolButton redstoneTorchButton = new ToolButton(null, "Redstone Torch");
		toolbar.insert(redstoneTorchButton);
		redstoneTorchButton.addOnClicked ((ToolButton tb) {
				pickedColor = 2;
		});
		ToolButton repeaterButton = new ToolButton(null, "Repeater");
		toolbar.insert(repeaterButton);
		repeaterButton.addOnClicked ((ToolButton tb) {
				pickedColor = 3;
		});

		ToolButton comparatorButton = new ToolButton(null, "Comparator");
		toolbar.insert(comparatorButton);
		comparatorButton.addOnClicked ((ToolButton tb) {
				pickedColor = 4;
		});

		ToolButton blockButton = new ToolButton(null, "Block");
		toolbar.insert(blockButton);
		blockButton.addOnClicked ((ToolButton tb) {
				pickedColor = 5;
		});
		box.add(toolbar);
		box.add(drawingArea);
		win.add(box);

		win.showAll();
		Main.run();
}
