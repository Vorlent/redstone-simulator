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
import std.stdio : writeln, stdout;
import gdk.Event;
import std.container : Array;
import cairo.imagesurface;

enum tileWidth = 16 + 1;
enum mouseLeftButton = 1;
enum mouseMiddleButton = 2;

struct Grid {
	byte[] grid;

	int width;
	int height;
	int depth;

	this(int width, int height, int depth)
	{
		this.width = width;
		this.height = height;
		this.depth = depth;
		this.grid = new byte[width * height * depth];
	}

	byte get(long x, long y, long z) {
		return grid[width * height * z + y * width + x];
	}

	void set(long x, long y, long z, byte value) {
		grid[width * height * z + y * width + x] = value;
	}

	bool checkBounds(long x, long y, long z) {
		long index = width * height * z + y * width + x;
		return index < grid.length && index >= 0;
	}
}

void populateGrid(Grid grid, long selectedDepth) {
	foreach(x; 0..grid.width) {
		foreach(y; 0..grid.height) {
			grid.set(x, y, selectedDepth, 0);
		}
	}
}

double[][] colors = [
	[1.0, 1.0, 1.0],
	[1.0, 0.0, 0.0],
	[1.0, 0.5, 0.0],
	[0.6, 0.6, 0.6],
	[0.4, 0.4, 0.4],
	[0.0, 0.0, 0.0]
];

struct Application {
	long dragX = 0;
	long dragY = 0;
	bool dragged = false;

	long cameraX = 0;
	long cameraY = 0;

	byte pickedColor = 0;
	long selectedDepth = 0;

	bool onMouseMove(long xWin, long yWin) {
		if(dragged) {
			cameraX += dragX - xWin;
			cameraY += dragY - yWin;
			dragX = xWin;
			dragY = yWin;
			return true;
		}
		return false;
	}
}

struct Vec3 {
	long x;
	long y;
	long z;
}

struct Connection {
	Vec3 output;
	Vec3 input;
	byte distance;
}

struct GridMetadata {
	bool closed;
	byte distance;
	Vec3 parent;
}

enum redstoneWire = 1;
enum redstoneTorch = 2;
enum redstoneRepeater = 3;
enum redstoneComparator = 4;
enum regularBlock = 5;

bool isRedstoneComponent(byte value) {
	return value == redstoneWire
	|| value == redstoneTorch
	|| value == redstoneRepeater
	|| value == redstoneComparator;
}

bool isInputComponent(byte value) {
	return value == redstoneTorch
	|| value == redstoneRepeater
	|| value == redstoneComparator;
}

bool isOutputComponent(byte value) {
	return value == redstoneTorch
	|| value == redstoneRepeater
	|| value == redstoneComparator;
}

Array!Vec3 findOutputComponents(Grid grid) {
	Array!Vec3 outputComponents = Array!Vec3();
	foreach(x; 0..grid.width) {
		foreach(y; 0..grid.height) {
			foreach(z; 0..grid.depth) {
				if(isOutputComponent(grid.get(x,y,z))) {
					outputComponents.insert(Vec3(x,y,z));
				}
			}
		}
	}
	return outputComponents;
}

Array!Connection generateNet(Grid grid, Vec3 start) {

	// TODO reuse datastructures
	Array!Vec3 open = Array!Vec3();
	Array!Connection connections = Array!Connection();
	// TODO make 32x32x32 grid centered on start point
	Array!GridMetadata metaGrid = Array!GridMetadata();

	GridMetadata gridMetadata;
	gridMetadata.closed = false;
	gridMetadata.distance = -1;
	gridMetadata.parent = Vec3(0, 0, 0);

	foreach(x; 0..grid.grid.length) {
		metaGrid.insert(gridMetadata);
	}

	open.insert(start);

	while(!open.empty) {
		Vec3 current = open.back();
		open.removeBack();

		GridMetadata* metaCurrent = &metaGrid[grid.width * grid.height * current.z + current.y * grid.width + current.x];

		if(metaCurrent.closed) {
				continue;
		}

		metaCurrent.closed = true;

		void processNeighbour(Vec3 neighbour) {
			if(!grid.checkBounds(neighbour.x, neighbour.y, neighbour.z)) {
				return;
			}

			byte componentType = grid.get(neighbour.x, neighbour.y, neighbour.z);

			GridMetadata* metaNeighbour = &metaGrid[grid.width * grid.height * neighbour.z + neighbour.y * grid.width + neighbour.x];

			if(!isRedstoneComponent(componentType) || metaNeighbour.closed) {
				return;
			}

			byte currentDistance = metaCurrent.distance;

			if(isInputComponent(componentType)) {
				//TODO handle blocks that are indirectly powered through a block
				//if the connection is directed into a block check it's neighbours for
				//input devices where the input side faces the block
				connections.insert(Connection(start, neighbour, currentDistance));
				return;
			}

			if(currentDistance > 15) {
				return;
			}

			open.insert(neighbour);

			if(metaNeighbour.distance > currentDistance + 1 || metaNeighbour.distance == -1) {
				metaNeighbour.distance = cast(byte)(currentDistance + 1);
				metaNeighbour.parent = current;
				stdout.flush();
			}
		}

		processNeighbour(Vec3(current.x + 1, current.y, current.z));
		processNeighbour(Vec3(current.x - 1, current.y, current.z));
		processNeighbour(Vec3(current.x, current.y + 1, current.z));
		processNeighbour(Vec3(current.x, current.y - 1, current.z));

		bool blockedUpwards = grid.checkBounds(current.x, current.z, current.y + 1)
			&& grid.get(current.x, current.z, current.y + 1) == regularBlock;

		if(!blockedUpwards) {
			processNeighbour(Vec3(current.x + 1, current.y, current.z + 1));
			processNeighbour(Vec3(current.x - 1, current.y, current.z + 1));
			processNeighbour(Vec3(current.x, current.y + 1, current.z + 1));
			processNeighbour(Vec3(current.x, current.y - 1, current.z + 1));
		}

		void checkDownwardsConnections(Vec3 current, long offsetX, long offsetY) {
			bool blockedDownwards = grid.checkBounds(current.x + offsetX, current.y + offsetY, current.z)
				&& grid.get(current.x + offsetX, current.y + offsetY, current.z) == regularBlock;

			if(!blockedDownwards) {
				processNeighbour(Vec3(current.x + offsetX, current.y + offsetY, current.z - 1));
			}
		}

		checkDownwardsConnections(current,  1,  0);
		checkDownwardsConnections(current, -1,  0);
		checkDownwardsConnections(current,  0,  1);
		checkDownwardsConnections(current,  0, -1);
	}
	return connections;
}

void main(string[] args)
{
	Main.init(args);
	MainWindow win = new MainWindow("Redstone Simulator");
	win.setDefaultSize(800, 600);
	Toolbar toolbar = new Toolbar();

	Box box = new Box(GtkOrientation.VERTICAL, 10);

	Grid grid = Grid(128, 128, 4);

	Application app = Application();
	populateGrid(grid, app.selectedDepth);

	ImageSurface redstone = ImageSurface.createFromPng("icons/redstone_cross.png");
	/*
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_unconnected.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_cross.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_horizontal.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_vertical.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_t_right.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_t_left.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_t_down.png");
	ImageSurface image = ImageSurface.createFromPng("icon/redstone_t_up.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_1_right.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_1_left.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_1_up.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_1_down.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_2_right.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_2_left.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_2_up.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_2_down.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_3_right.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_3_left.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_3_up.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_3_down.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_4_right.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_4_left.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_4_up.png");
	ImageSurface image = ImageSurface.createFromPng("icon/repeater_4_down.png");
	*/
	DrawingArea drawingArea = new DrawingArea(800, 600);
	drawingArea.addOnDraw((Scoped!Context cr, Widget widget) {
		cr.translate(-app.cameraX, -app.cameraY);
		foreach(x; 0..grid.width) {
			foreach(y; 0..grid.height) {
				cr.save();
					byte color = grid.get(x, y, app.selectedDepth);
					cr.translate(2 + x * tileWidth, 2 + y * tileWidth);
					if(redstoneWire == color) {
						cr.setSourceSurface (redstone, 0, 0);
					} else {
						cr.setSourceRgba(colors[color][0], colors[color][1], colors[color][2], 1.0);
					}
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
				long index = grid.width * grid.height * app.selectedDepth + grid.width * cast(ulong)((yWin + app.cameraY) / tileWidth) + cast(ulong)((xWin + app.cameraX) / tileWidth);
				if(index < grid.grid.length) {
					grid.grid[index] = app.pickedColor;
					widget.queueDraw();
				}
			}
			if(button == mouseMiddleButton) {
				app.dragX = cast(ulong)xWin;
				app.dragY = cast(ulong)yWin;
				app.dragged = true;
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
				app.dragged = false;
			}
		}
		return false;
	});
	drawingArea.addOnMotionNotify((Event event, Widget widget) {
		double xWin;
		double yWin;
		if(event.getCoords(xWin, yWin)) {
			if(app.onMouseMove(cast(long)xWin, cast(long)yWin)) {
				widget.queueDraw();
			}
		}
		return false;
	});

	ToolButton runButton = new ToolButton(null, "Run");
	toolbar.insert(runButton);
	runButton.addOnClicked ((ToolButton tb) {
		writeln("Run");
		foreach(output; findOutputComponents(grid)) {
			generateNet(grid, output);
		}
	});

	ToolButton stopButton = new ToolButton(null, "Stop");
	toolbar.insert(stopButton);
	stopButton.addOnClicked ((ToolButton tb) {
		writeln("Stop");
	});

	ToolButton blankButton = new ToolButton(null, "Blank");
	toolbar.insert(blankButton);
	blankButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = 0;
	});

	ToolButton redstoneDustButton = new ToolButton(null, "Redstone Dust");
	toolbar.insert(redstoneDustButton);
	redstoneDustButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = redstoneWire;
	});

	ToolButton redstoneTorchButton = new ToolButton(null, "Redstone Torch");
	toolbar.insert(redstoneTorchButton);
	redstoneTorchButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = redstoneTorch;
	});
	ToolButton repeaterButton = new ToolButton(null, "Repeater");
	toolbar.insert(repeaterButton);
	repeaterButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = redstoneRepeater;
	});

	ToolButton comparatorButton = new ToolButton(null, "Comparator");
	toolbar.insert(comparatorButton);
	comparatorButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = redstoneComparator;
	});
	ToolButton blockButton = new ToolButton(null, "Block");
	toolbar.insert(blockButton);
	blockButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = regularBlock;
	});
	box.add(toolbar);
	box.add(drawingArea);
	win.add(box);

	win.showAll();
	Main.run();
}
