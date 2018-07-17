module redsim.Generator;

import redsim.Block;
import redsim.Vec3;
import redsim.Direction;
import redsim.Grid;
import std.container : Array;
import std.array;
import std.conv;
import std.stdio : writeln, stdout;
import std.algorithm.sorting : sort;
import std.algorithm.mutation : SwapStrategy;

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

	void toString(scope void delegate(const(char)[]) sink) const
	{
		sink("Connection[ output: ");
		output.toString(sink);
		sink(", input: ");
		input.toString(sink);
		sink(", distance: ");
		sink(to!string(distance));
		sink(", direction: ");
		sink(to!string(direction));
		sink(" ]");
	}

	int opCmp(ref const Connection v) const {
		int cmp = output.opCmp(v.output);
		if(cmp == 0) {
			return input.opCmp(v.input);
		} else {
			return cmp;
		}
	}
}

struct GridMetadata {
	bool closed;
	byte distance;
	Vec3 parent;
}

struct Generator {
	Grid* grid;

	this(Grid* grid) {
		this.grid = grid;
	}

	void generateNet(Array!Connection* connections) {
		foreach(x; 0..grid.width) {
			foreach(y; 0..grid.height) {
				foreach(z; 0..grid.depth) {
					Vec3 pos = Vec3(x,y,z);
					if(isOutputComponent(grid.get(pos))) {
						generateNetForComponent(connections, pos);
					}
				}
			}
		}
		long i = 0;
		foreach(con; sort(array(connections.opSlice()))) {
			(*connections)[i] = con;
			i++;
		}
	}

	GridMetadata* get(Array!GridMetadata* metaGrid, Vec3 position, Vec3 center) {
		Vec3 local = center.minus(position).plus(Vec3(15, 15, 15));
		long index = 33/*width*/ * 33/*height*/ * local.z + local.y * /*width*/ + local.x;
		return &((*metaGrid)[index]);
	}

  void generateNetForComponent(Array!Connection* connections, Vec3 start) {
  	Array!Vec3 open = Array!Vec3();
		Array!GridMetadata metaGrid = Array!GridMetadata();

  	GridMetadata gridMetadata = {
  		closed: false,
  		distance: -1,
  		parent: Vec3(0, 0, 0)
  	};
		metaGrid.reserve(33*33*33);
  	foreach(x; 0..(33*33*33)) {
  		metaGrid.insert(gridMetadata);
  	}

  	open.insert(start);

  	while(!open.empty) {
  		Vec3 current = open.back();
  		open.removeBack();

  		GridMetadata* metaCurrent = get(&metaGrid, current, start);
  		if(metaCurrent.closed) {
  			continue;
  		}

  		metaCurrent.closed = true;

  		void processNeighbour(Vec3 current, Direction direction) {
  			Vec3 neighbour = current.plus(direction.offset());

  			if(!grid.validBounds(current)) {
  				return;
  			}
  			if(!isOutputDirection(grid.get(current), direction)) {
  				return;
  			}

  			if(!grid.validBounds(neighbour)) {
  				return;
  			}

  			Block componentType = grid.get(neighbour);

  			GridMetadata* metaNeighbour = get(&metaGrid, neighbour, start);

  			if(!isRedstoneComponent(componentType) || metaNeighbour.closed) {
  				return;
  			}

  			byte currentDistance = metaCurrent.distance;

  			if(componentType.type == BlockType.regularBlock) {
  				void indirectlyPowered(Direction direction) {
  					if(!isOutputDirection(componentType, direction)) {
  						return;
  					}
  					Vec3 position = neighbour.plus(direction.offset());
  					Block block = grid.get(position);
  					if(isInputDirection(block, opposite(direction)) && block.isInputComponent()) {
  						connections.insert(Connection(position, start, currentDistance, direction.opposite()));
  					}
  				}
  				indirectlyPowered(Direction.left);
  				indirectlyPowered(Direction.right);
  				indirectlyPowered(Direction.up);
  				indirectlyPowered(Direction.down);
  				return;
  			}

  			if(isInputDirection(componentType, opposite(direction)) && componentType.isInputComponent()) {
  				connections.insert(Connection(neighbour, start, currentDistance, opposite(direction)));
  				return;
  			}

  			if(currentDistance >= 15) {
  				return;
  			}
				if(isInputDirection(componentType, opposite(direction))) {
					open.insert(neighbour);
				}

  			if(metaNeighbour.distance > currentDistance + 1 || metaNeighbour.distance == -1) {
					if(currentDistance == -1) {
						currentDistance = 0;
					}
  				metaNeighbour.distance = cast(byte)(currentDistance + 1);
  				metaNeighbour.parent = current;
  				stdout.flush();
  			}
  		}

  		processNeighbour(current, Direction.right);
  		processNeighbour(current, Direction.left);
  		processNeighbour(current, Direction.up);
  		processNeighbour(current, Direction.down);

  		bool blockedUpwards = grid.validBounds(current.plus(Vec3(0,0,1)))
  			&& grid.get(current.plus(Vec3(0,0,1))).type == BlockType.regularBlock;

  		if(!blockedUpwards) {
  			processNeighbour(current.plus(Vec3(0,0,1)), Direction.right);
  			processNeighbour(current.plus(Vec3(0,0,1)), Direction.left);
  			processNeighbour(current.plus(Vec3(0,0,1)), Direction.up);
  			processNeighbour(current.plus(Vec3(0,0,1)), Direction.down);
  		}

  		void checkDownwardsConnections(Vec3 current, Direction direction) {
  			Vec3 position = current.plus(direction.offset());
  			bool blockedDownwards = grid.validBounds(position)
  			&& grid.get(position).type == BlockType.regularBlock;
  			if(!blockedDownwards) {
  				processNeighbour(position.plus(Vec3(0,0,-1)), direction);
  			}
  		}

  		checkDownwardsConnections(current, Direction.right);
  		checkDownwardsConnections(current, Direction.left);
  		checkDownwardsConnections(current, Direction.up);
  		checkDownwardsConnections(current, Direction.down);
  	}
  }
}
