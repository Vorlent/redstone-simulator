module redsim.Vec3;
import std.conv;

struct Vec3 {
	long x;
	long y;
	long z;

	Vec3 plus(Vec3 vec) {
		return Vec3(vec.x + this.x, vec.y + this.y, vec.z + this.z);
	}

	Vec3 minus(Vec3 vec) {
		return Vec3(vec.x - this.x, vec.y - this.y, vec.z - this.z);
	}

	int opCmp(ref const Vec3 v) const {
		// WHY CANT I JUST DO [z,y,x] <=> [v.z,v.y,v.x]
		// AND THE COMPILER TURNS IT INTO THIS
		if(z < v.z) {
			return -1;
		} else if(z > v.z) {
			return 1;
		} else {
			if(y < v.y) {
				return -1;
			} else if(y > v.y) {
				return 1;
			} else {
				if(x < v.x) {
					return -1;
				} else if(x > v.x) {
					return 1;
				} else {
					return 0;
				}
			}
		}
	}

	bool opEquals(ref const Vec3 v) const {
		return x == v.x && y == v.y && z == v.z;
	}

	void toString(scope void delegate(const(char)[]) sink) const
	{
		sink("Vec3[ x: ");
		sink(to!string(x));
		sink(", y: ");
		sink(to!string(y));
		sink(", z: ");
		sink(to!string(z));
		sink(" ]");
	}
}
