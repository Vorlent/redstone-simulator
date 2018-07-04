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
import std.bitmanip : bitfields;
import cairo.ImageSurface;

enum tileWidth = 16 + 1;
enum mouseLeftButton = 1;
enum mouseMiddleButton = 2;
enum mouseRightButton = 3;

struct Grid {
	Block[] grid;

	int width;
	int height;
	int depth;

	this(int width, int height, int depth)
	{
		this.width = width;
		this.height = height;
		this.depth = depth;
		this.grid = new Block[width * height * depth];
	}

	Block get(long x, long y, long z) {
		return grid[width * height * z + y * width + x];
	}

	void set(long x, long y, long z, Block value) {
		grid[width * height * z + y * width + x] = value;
	}

	bool validBounds(long x, long y, long z) {
		long index = width * height * z + y * width + x;
		return index < grid.length && index >= 0;
	}
}

void populateGrid(Grid grid, long selectedDepth) {
	foreach(x; 0..grid.width) {
		foreach(y; 0..grid.height) {
			grid.set(x, y, selectedDepth, Block(BlockType.none, Direction.up));
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

	BlockType pickedColor = BlockType.none;
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

	ImageSurface[] images = [
		null,
		null,
		null,
		null,
		null,
		null
	];

	ImageSurface getImage(BlockType blocktype) {
		return images[blocktype];
	}

	void loadImages() {
		images[BlockType.redstoneWire] = ImageSurface.createFromPng("icons/redstone_cross.png");
		images[BlockType.redstoneRepeater] = ImageSurface.createFromPng("icons/repeater_1_right.png");
		images[BlockType.redstoneComparator] = ImageSurface.createFromPng("icons/comparator_comp_left.png");
		images[BlockType.redstoneTorch] = ImageSurface.createFromPng("icons/redstone_torch.png");

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
	}
}

struct Vec3 {
	long x;
	long y;
	long z;

	Vec3 plus(Vec3 vec) {
		return Vec3(vec.x + this.x, vec.y + this.y, vec.z + this.z);
	}
}

struct Connection {
	Vec3 output;
	Vec3 input;
	byte distance;
	Direction direction;

	this(Vec3 output, Vec3 input, byte distance, Direction direction) {
		this.output = output;
		this.input = input;
		this.distance = distance;
		this.direction = direction;
	}
}

struct GridMetadata {
	bool closed;
	byte distance;
	Vec3 parent;
}

struct Block {
	byte value;

	static Block fromByte(byte value) {
		Block block = Block();
		block.value = value;
		return block;
	}

	this(BlockType type, Direction direction) {
		this.type = type;
		this.direction = direction;
	}

mixin(bitfields!(
    BlockType, "type", 6,
    Direction, "direction", 2));
}

enum Direction
{
	up = 0,
	down = 1,
	left = 2,
	right = 3
}

Direction opposite(Direction direction) {
	final switch(direction) {
		case Direction.up:
			return Direction.down;
		case Direction.down:
			return Direction.up;
		case Direction.left:
			return Direction.right;
		case Direction.right:
			return Direction.left;
	}
}

Vec3 offset(Direction direction) {
	final switch(direction) {
		case Direction.up:
			return Vec3(0, -1, 0);
		case Direction.down:
			return Vec3(0, +1, 0);
		case Direction.left:
			return Vec3(-1, 0, 0);
		case Direction.right:
			return Vec3(+1, 0, 0);
	}
}

enum BlockType
{
	none = 0,
	redstoneWire = 1,
	redstoneTorch = 2,
	redstoneRepeater = 3,
	redstoneComparator = 4,
	regularBlock = 5
}

bool isRedstoneComponent(Block block) {
	return block.value == BlockType.redstoneWire
		|| block.value == BlockType.redstoneTorch
		|| block.value == BlockType.redstoneRepeater
		|| block.value == BlockType.redstoneComparator;
}

bool isInputComponent(Block block) {
	return block.value == BlockType.redstoneTorch
	|| block.value == BlockType.redstoneRepeater
	|| block.value == BlockType.redstoneComparator;
}

bool isOutputComponent(Block block) {
	return block.value == BlockType.redstoneTorch
	|| block.value == BlockType.redstoneRepeater
	|| block.value == BlockType.redstoneComparator;
}

Array!Vec3 findOutputComponents(Grid* grid) {
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

Array!Connection generateNet(Grid* grid, Vec3 start) {

	// TODO reuse datastructures
	Array!Vec3 open = Array!Vec3();
	Array!Connection connections = Array!Connection();
	// TODO make 32x32x32 grid centered on start point
	Array!GridMetadata metaGrid = Array!GridMetadata();

	GridMetadata gridMetadata = {
		closed: false,
		distance: -1,
		parent: Vec3(0, 0, 0)
	};

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

		void processNeighbour(Vec3 neighbour, Direction direction) {
			if(!grid.validBounds(neighbour.x, neighbour.y, neighbour.z)) {
				return;
			}

			Block componentType = grid.get(neighbour.x, neighbour.y, neighbour.z);

			GridMetadata* metaNeighbour = &metaGrid[grid.width * grid.height * neighbour.z + neighbour.y * grid.width + neighbour.x];

			if(!isRedstoneComponent(componentType) || metaNeighbour.closed) {
				return;
			}

			byte currentDistance = metaCurrent.distance;

			if(componentType.type == BlockType.regularBlock) {
				void indirectlyPowered(Direction direction) {
					Vec3 position = neighbour.plus(direction.offset());
					Block block = grid.get(position.x, position.y, position.z);
					if(block.direction == direction && block.isInputComponent()) {
						connections.insert(Connection(start, Vec3(position.x, position.y, position.z), currentDistance, direction.opposite()));
					}
				}
				indirectlyPowered(Direction.left);
				indirectlyPowered(Direction.right);
				indirectlyPowered(Direction.up);
				indirectlyPowered(Direction.down);
				return;
			}

			if(componentType.isInputComponent()) {
				connections.insert(Connection(start, neighbour, currentDistance, direction));
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

		processNeighbour(Vec3(current.x + 1, current.y, current.z), Direction.right);
		processNeighbour(Vec3(current.x - 1, current.y, current.z), Direction.left);
		processNeighbour(Vec3(current.x, current.y + 1, current.z), Direction.up);
		processNeighbour(Vec3(current.x, current.y - 1, current.z), Direction.down);

		bool blockedUpwards = grid.validBounds(current.x, current.z, current.y + 1)
			&& grid.get(current.x, current.z, current.y + 1).type == BlockType.regularBlock;

		if(!blockedUpwards) {
			processNeighbour(Vec3(current.x + 1, current.y, current.z + 1), Direction.right);
			processNeighbour(Vec3(current.x - 1, current.y, current.z + 1), Direction.left);
			processNeighbour(Vec3(current.x, current.y + 1, current.z + 1), Direction.up);
			processNeighbour(Vec3(current.x, current.y - 1, current.z + 1), Direction.down);
		}

		void checkDownwardsConnections(Vec3 current, Direction direction) {
			Vec3 position = current.plus(direction.offset());
			bool blockedDownwards = grid.validBounds(position.x, position.y, position.z)
				&& grid.get(position.x, position.y, position.z).type == BlockType.regularBlock;
			if(!blockedDownwards) {
				processNeighbour(position.plus(Vec3(0,0,-1)), direction);
			}
		}

		checkDownwardsConnections(current, Direction.right);
		checkDownwardsConnections(current, Direction.left);
		checkDownwardsConnections(current, Direction.up);
		checkDownwardsConnections(current, Direction.down);
	}
	return connections;
}

void loadRedstoneImage() {
	ImageSurface.createFromPng("redstone.png");
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

void drawGrid(Application* app, Grid* grid, Scoped!Context* cr) {
	cr.translate(-app.cameraX, -app.cameraY);
	foreach(x; 0..grid.width) {
		foreach(y; 0..grid.height) {
			cr.save();
				Block color = grid.get(x, y, app.selectedDepth);
				ImageSurface surface = app.getImage(color.type);
				cr.translate(2 + x * tileWidth, 2 + y * tileWidth);
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

bool onMouseButtonPress(Application* app, Grid* grid, uint button, double xWin, double yWin) {
	if(button == mouseLeftButton || button == mouseRightButton) {
		long posX = cast(ulong)((xWin + app.cameraX) / tileWidth);
		long posY = cast(ulong)((yWin + app.cameraY) / tileWidth);
		if(grid.validBounds(posX, posY, app.selectedDepth)) {
			BlockType type = app.pickedColor;
			if(button == mouseRightButton) {
				type = BlockType.none;
			}
			grid.set(posX, posY, app.selectedDepth, Block(type, Direction.up));
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
	app.loadImages();
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
			generateNet(&grid, output);
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
