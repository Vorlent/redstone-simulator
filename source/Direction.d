module redsim.Direction;
import redsim.Vec3;

enum Direction
{
	up = 0,
	down = 1,
	left = 2,
	right = 3
}

Direction clockwise(Direction direction) {
	final switch(direction) {
		case Direction.up:
			return Direction.right;
		case Direction.right:
			return Direction.down;
		case Direction.down:
			return Direction.left;
		case Direction.left:
			return Direction.up;
	}
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
