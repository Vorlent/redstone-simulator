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

  ImageSurface[] imageRedstoneTorch = [
		null,
		null,
		null,
		null
	];

	ImageSurface[] imageRepeaterOne = [
		null,
		null,
		null,
		null
	];

	ImageSurface[] imageRepeaterTwo = [
		null,
		null,
		null,
		null
	];

	ImageSurface[] imageRepeaterThree = [
		null,
		null,
		null,
		null
	];

	ImageSurface[] imageRepeaterFour = [
		null,
		null,
		null,
		null
	];

	ImageSurface[] imageComparator = [
		null,
		null,
		null,
		null
	];

	ImageSurface getImage(Grid* grid, Block block, long x, long y, long z) {
		if(block.type == BlockType.redstoneTorch) {
			return imageRedstoneTorch[block.direction];
		}
		if(block.type == BlockType.redstoneRepeater) {
			return imageRepeaterOne[block.direction];
		}
		if(block.type == BlockType.redstoneComparator) {
			return imageComparator[block.direction];
		}
		return defaultImages[block.type];
	}

	void loadImages() {
		defaultImages[BlockType.redstoneWire] = ImageSurface.createFromPng("icons/redstone_cross.png");
		defaultImages[BlockType.redstoneRepeater] = ImageSurface.createFromPng("icons/repeater_1_right.png");
		defaultImages[BlockType.redstoneComparator] = ImageSurface.createFromPng("icons/comparator_comp_left.png");
		defaultImages[BlockType.redstoneTorch] = ImageSurface.createFromPng("icons/redstone_torch_up.png");

		/*imageRedstoneUnconnected = ImageSurface.createFromPng("icons/redstone_unconnected.png");
		imageRedstoneCross = ImageSurface.createFromPng("icons/redstone_cross.png");
		imageRedstoneHorizontal = ImageSurface.createFromPng("icons/redstone_horizontal.png");
		imageRedstoneVertical = ImageSurface.createFromPng("icons/redstone_vertical.png");
		imageRedstoneTRight = ImageSurface.createFromPng("icons/redstone_t_right.png");
		imageRedstoneTLeft = ImageSurface.createFromPng("icons/redstone_t_left.png");
		imageRedstoneTDown = ImageSurface.createFromPng("icons/redstone_t_down.png");
		imageRedstoneTUp = ImageSurface.createFromPng("icons/redstone_t_up.png");*/

		imageRedstoneTorch[Direction.right] = ImageSurface.createFromPng("icons/redstone_torch_right.png");
		imageRedstoneTorch[Direction.left] = ImageSurface.createFromPng("icons/redstone_torch_left.png");
		imageRedstoneTorch[Direction.down] = ImageSurface.createFromPng("icons/redstone_torch_down.png");
		imageRedstoneTorch[Direction.up] = ImageSurface.createFromPng("icons/redstone_torch_up.png");

		imageRepeaterOne[Direction.right] = ImageSurface.createFromPng("icons/repeater_1_right.png");
		imageRepeaterOne[Direction.left] = ImageSurface.createFromPng("icons/repeater_1_left.png");
		imageRepeaterOne[Direction.down] = ImageSurface.createFromPng("icons/repeater_1_up.png");
		imageRepeaterOne[Direction.up] = ImageSurface.createFromPng("icons/repeater_1_down.png");

		imageRepeaterTwo[Direction.right] = ImageSurface.createFromPng("icons/repeater_2_right.png");
		imageRepeaterTwo[Direction.left] = ImageSurface.createFromPng("icons/repeater_2_left.png");
		imageRepeaterTwo[Direction.down] = ImageSurface.createFromPng("icons/repeater_2_up.png");
		imageRepeaterTwo[Direction.up] = ImageSurface.createFromPng("icons/repeater_2_down.png");

		imageRepeaterThree[Direction.right] = ImageSurface.createFromPng("icons/repeater_3_right.png");
		imageRepeaterThree[Direction.left] = ImageSurface.createFromPng("icons/repeater_3_left.png");
		imageRepeaterThree[Direction.down] = ImageSurface.createFromPng("icons/repeater_3_up.png");
		imageRepeaterThree[Direction.up] = ImageSurface.createFromPng("icons/repeater_3_down.png");

		imageRepeaterFour[Direction.right] = ImageSurface.createFromPng("icons/repeater_4_right.png");
		imageRepeaterFour[Direction.left] = ImageSurface.createFromPng("icons/repeater_4_left.png");
		imageRepeaterFour[Direction.down] = ImageSurface.createFromPng("icons/repeater_4_up.png");
		imageRepeaterFour[Direction.up] = ImageSurface.createFromPng("icons/repeater_4_down.png");

		imageComparator[Direction.right] = ImageSurface.createFromPng("icons/comparator_comp_right.png");
		imageComparator[Direction.left] = ImageSurface.createFromPng("icons/comparator_comp_left.png");
		imageComparator[Direction.down] = ImageSurface.createFromPng("icons/comparator_comp_down.png");
		imageComparator[Direction.up] = ImageSurface.createFromPng("icons/comparator_comp_up.png");
	}
}
