module redsim.Block;
import redsim.Direction;
import std.bitmanip : bitfields;

enum BlockType
{
	none = 0,
	redstoneWire = 1,
	redstoneTorch = 2,
	redstoneRepeater = 3,
	redstoneComparator = 4,
	regularBlock = 5
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

bool isRedstoneComponent(Block block) {
	return block.type == BlockType.redstoneWire
	|| block.type == BlockType.redstoneTorch
	|| block.type == BlockType.redstoneRepeater
	|| block.type == BlockType.redstoneComparator;
}

bool isInputComponent(Block block) {
	return block.type == BlockType.redstoneTorch
	|| block.type == BlockType.redstoneRepeater
	|| block.type == BlockType.redstoneComparator;
}

bool isOutputComponent(Block block) {
	return block.type == BlockType.redstoneTorch
	|| block.type == BlockType.redstoneRepeater
	|| block.type == BlockType.redstoneComparator;
}

bool isOutputDirection(Block block, Direction direction) {
	final switch(block.type) {
		case BlockType.none:
			return false;
		case BlockType.redstoneWire:
			return true;
		case BlockType.redstoneTorch:
			return opposite(block.direction) != direction;
		case BlockType.redstoneRepeater:
			return block.direction == direction;
		case BlockType.redstoneComparator:
			return block.direction == direction;
		case BlockType.regularBlock:
			return false;
	}
}

bool isInputDirection(Block block, Direction direction) {
	final switch(block.type) {
		case BlockType.none:
			return false;
		case BlockType.redstoneWire:
			return true;
		case BlockType.redstoneTorch:
			return opposite(block.direction) == direction;
		case BlockType.redstoneRepeater:
			return opposite(block.direction) == direction;
		case BlockType.redstoneComparator:
			return opposite(block.direction) == direction;
		case BlockType.regularBlock:
			return false;
	}
}
