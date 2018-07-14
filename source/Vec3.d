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
