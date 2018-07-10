module redsim.Grid;

import redsim.Block;
import redsim.Vec3;
import redsim.Direction;

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

	Block get(Vec3 position) {
		return grid[width * height * position.z + position.y * width + position.x];
	}

	void set(Vec3 position, Block value) {
		grid[width * height * position.z + position.y * width + position.x] = value;
	}

	bool validBounds(Vec3 position) {
		long index = width * height * position.z + position.y * width + position.x;
		return index < grid.length && index >= 0;
	}
}

void populateGrid(Grid grid, long selectedDepth) {
	foreach(x; 0..grid.width) {
		foreach(y; 0..grid.height) {
			grid.set(Vec3(x, y, selectedDepth), Block(BlockType.none, Direction.up));
		}
	}
}
