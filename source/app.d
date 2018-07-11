module redsim.app;

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
import cairo.ImageSurface;
import std.math : PI;
import redsim.Direction;
import redsim.Vec3;
import redsim.Grid;
import redsim.Block;
import redsim.Generator;
import redsim.Images;

enum tileWidth = 16 + 1;
enum mouseLeftButton = 1;
enum mouseMiddleButton = 2;
enum mouseRightButton = 3;

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

	BlockType pickedColor = BlockType.none;
	long selectedDepth = 0;
	Images images;

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

/*
//TODO support incremental simuation to only simulate changes
function simulateTick(Array!Connection netlist) {
	foreach(connection; netlist) {
		if(grid[connection.output] == BlockType.redstoneTorch) {
			powerGrid[connection.input] = powerGrid[connection.output] > 0 ? 0 : 15;
		}
		if(grid[connection.output] == BlockType.repeater_delay_1) {
			powerGrid[connection.input] = powerGrid[connection.output];
		}
		if(grid[connection.output] == BlockType.repeater_delay_2..4) { ???
			powerGrid[connection.input] = delay by 2,3,4 powerGrid[connection.output];
		}
		//I could add a metadata section but not every connection needs metadata so it's a waste of bandwidth
		//I'd need to store 4 bytes to support the repeater for every block
		//imagine a large design of 16000x16000 blocks with 3 million netlist entries
		//it would waste 1GB of memory just on repeater metadata
		if(grid[connection.output] == BlockType.comparator) {
			Compare signal strength
			A redstone comparator in comparison mode (front torch down and unpowered) will compare its rear input to its two side inputs.
			If either side input is greater than the rear input, the comparator output turns off.
			If neither side input is greater than the rear input, the comparator simply outputs the same signal strength as its rear input.

			Subtract signal strength
			A redstone comparator in subtraction mode (front torch up and powered) will subtract the signal strength of the
			highest side input from the signal strength of the rear input (minimum 0 signal strength).
			For example, if the rear input signal strength is 7, the left side is 2, and the right side is 4,
			then the output will be a signal strength of 3, because 7 - MAX(2,4) = 3.
		}
		//TODO buttons/levers
	}
}
*/

double degreesToRadians(double degrees)
{
    return degrees * (PI/180.0);
}

void fixDirection(Scoped!Context* cr, Block block) {
	if(block.type == BlockType.redstoneComparator) {
		// ???
		return;
	}
	final switch(block.direction) {
		case Direction.up:
		case Direction.down:
			cr.rotate(degreesToRadians(180));
			cr.translate(-tileWidth + 1, -tileWidth + 1);
			break;
		case Direction.right:
		case Direction.left:
		//no rotation
			break;
	}
}

void drawGrid(Application* app, Grid* grid, Scoped!Context* cr) {
	cr.translate(-app.cameraX, -app.cameraY);
	foreach(x; 0..grid.width) {
		foreach(y; 0..grid.height) {
			cr.save();
				Block color = grid.get(Vec3(x, y, app.selectedDepth));
				ImageSurface surface = app.images.getImage(grid, color, x, y, app.selectedDepth);
				cr.translate(2 + x * tileWidth, 2 + y * tileWidth);
				fixDirection(cr, color);
				if(surface !is null) {
					cr.setSourceSurface(surface, 0, 0);
				} else {
					cr.setSourceRgba(colors[color.type][0], colors[color.type][1], colors[color.type][2], 1.0);
				}
				cr.rectangle(0.0, 0.0, 16.0, 16.0);
				cr.fill();
			cr.restore();
		}
	}
}

Direction rotateOnClick(Block old, BlockType type, Direction direction) {
	if(old.type == type) {
		return clockwise(old.direction);
	}
	return direction;
}

bool onMouseButtonPress(Application* app, Grid* grid, uint button, double xWin, double yWin) {
	if(button == mouseLeftButton || button == mouseRightButton) {
		long posX = cast(ulong)((xWin + app.cameraX) / tileWidth);
		long posY = cast(ulong)((yWin + app.cameraY) / tileWidth);
		Vec3 mouseSelection = Vec3(posX, posY, app.selectedDepth);
		if(grid.validBounds(mouseSelection)) {
			BlockType type = app.pickedColor;
			if(button == mouseRightButton) {
				type = BlockType.none;
			}
			Direction direction = Direction.up;
			if(type == BlockType.redstoneTorch) {
				if(grid.validBounds(mouseSelection.plus(Vec3(0,-1,0)))
					&& grid.get(mouseSelection.plus(Vec3(0,-1,0))).type == BlockType.regularBlock) { //check if block is up
					direction = Direction.down;
				}
				if(grid.validBounds(mouseSelection.plus(Vec3(1,0,0)))
					&& grid.get(mouseSelection.plus(Vec3(1,0,0))).type == BlockType.regularBlock) { //check if block is right
					direction = Direction.right;
				}
				if(grid.validBounds(mouseSelection.plus(Vec3(0,1,0)))
					&& grid.get(mouseSelection.plus(Vec3(0,1,0))).type == BlockType.regularBlock) { //check if block is down
					direction = Direction.up;
				}
				if(grid.validBounds(mouseSelection.plus(Vec3(-1,0,0)))
					&& grid.get(mouseSelection.plus(Vec3(-1,0,0))).type == BlockType.regularBlock) { //check if block is left
					direction = Direction.left;
				}
			}
			direction = rotateOnClick(grid.get(mouseSelection), BlockType.redstoneRepeater, direction);
			direction = rotateOnClick(grid.get(mouseSelection), BlockType.redstoneComparator, direction);
			grid.set(mouseSelection, Block(type, direction));
			return true;
		}
	}
	if(button == mouseMiddleButton) {
		app.dragX = cast(ulong)xWin;
		app.dragY = cast(ulong)yWin;
		app.dragged = true;
		return true;
	}
	return false;
}

void onMouseButtonRelease(Application* app, uint button) {
	if(button == mouseMiddleButton) {
		app.dragged = false;
	}
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
	app.images.loadImages();
	populateGrid(grid, app.selectedDepth);

	DrawingArea drawingArea = new DrawingArea(800, 600);
	drawingArea.addOnDraw((Scoped!Context cr, Widget widget) {
		drawGrid(&app, &grid, &cr);
		return false;
	});
	drawingArea.addOnButtonPress((Event event, Widget widget) {
		uint button;
		double xWin;
		double yWin;
		if(event.getButton(button) && event.getCoords(xWin, yWin)) {
			if(onMouseButtonPress(&app, &grid, button, xWin, yWin)) {
				widget.queueDraw();
			}
		}
		return false;
	});

	drawingArea.addOnButtonRelease ((Event event, Widget widget) {
		uint button;
		if(event.getButton(button)) {
			onMouseButtonRelease(&app, button);
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
		foreach(output; findOutputComponents(&grid)) {
			Array!Connection connections = generateNet(&grid, output);
			writeln(connections.length());
			foreach(con; connections) {
				writeln(con);
			}
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
		app.pickedColor = BlockType.none;
	});

	ToolButton redstoneDustButton = new ToolButton(null, "Redstone Dust");
	toolbar.insert(redstoneDustButton);
	redstoneDustButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = BlockType.redstoneWire;
	});

	ToolButton redstoneTorchButton = new ToolButton(null, "Redstone Torch");
	toolbar.insert(redstoneTorchButton);
	redstoneTorchButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = BlockType.redstoneTorch;
	});
	ToolButton repeaterButton = new ToolButton(null, "Repeater");
	toolbar.insert(repeaterButton);
	repeaterButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = BlockType.redstoneRepeater;
	});

	ToolButton comparatorButton = new ToolButton(null, "Comparator");
	toolbar.insert(comparatorButton);
	comparatorButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = BlockType.redstoneComparator;
	});
	ToolButton blockButton = new ToolButton(null, "Block");
	toolbar.insert(blockButton);
	blockButton.addOnClicked ((ToolButton tb) {
		app.pickedColor = BlockType.regularBlock;
	});
	box.add(toolbar);
	box.add(drawingArea);
	win.add(box);

	win.showAll();
	Main.run();
}
