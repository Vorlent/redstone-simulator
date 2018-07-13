module redsim.Images;

import cairo.ImageSurface;
import redsim.Grid;
import redsim.Block;
import redsim.Direction;

struct Images {
	ImageSurface[] defaultImages = [
		null,
		null,
		null,
		null,
		null,
		null
	];

	ImageSurface[] imageRepeater = [
		null,
		null,
		null,
		null
	];

	ImageSurface getImage(Grid* grid, Block block, long x, long y, long z) {
		return defaultImages[block.type];
	}

	void loadImages() {
		defaultImages[BlockType.redstoneWire] = ImageSurface.createFromPng("icons/redstone_cross.png");
		defaultImages[BlockType.redstoneRepeater] = ImageSurface.createFromPng("icons/repeater_1_down.png");
		defaultImages[BlockType.redstoneComparator] = ImageSurface.createFromPng("icons/comparator_comp_down.png");
		defaultImages[BlockType.redstoneTorch] = ImageSurface.createFromPng("icons/redstone_torch_down.png");

		/*imageRedstoneUnconnected = ImageSurface.createFromPng("icons/redstone_unconnected.png");
		imageRedstoneCross = ImageSurface.createFromPng("icons/redstone_cross.png");
		imageRedstoneHorizontal = ImageSurface.createFromPng("icons/redstone_horizontal.png");
		imageRedstoneVertical = ImageSurface.createFromPng("icons/redstone_vertical.png");
		imageRedstoneTRight = ImageSurface.createFromPng("icons/redstone_t_right.png");
		imageRedstoneTLeft = ImageSurface.createFromPng("icons/redstone_t_left.png");
		imageRedstoneTDown = ImageSurface.createFromPng("icons/redstone_t_down.png");
		imageRedstoneTUp = ImageSurface.createFromPng("icons/redstone_t_up.png");*/

		imageRepeater[0] = ImageSurface.createFromPng("icons/repeater_1_down.png");
		imageRepeater[1] = ImageSurface.createFromPng("icons/repeater_2_down.png");
		imageRepeater[2] = ImageSurface.createFromPng("icons/repeater_3_down.png");
		imageRepeater[3] = ImageSurface.createFromPng("icons/repeater_4_down.png");
	}
}
