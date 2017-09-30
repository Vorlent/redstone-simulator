# Simulation Approach: Use Netlists for performance optimization

The idea is to skip powering individual redstone dust blocks sequentially
and instead go over the grid once to scan for the direct connection of output
and input devices. The result will me a many to many relation from output to
input device. The advantage of this approach is that signals don't have to be
propagated from redstone dust to redstone dust, block for block. Each
connection requires a simple distance calculation at the start of the
simulation.

## Devices
There are two types of devices but a device can both be an input component
and an output component at the same time.
Input devices are doors, pistons, torches, repeaters, comparators.
Output devices are buttons, levers, torches, repeaters, comparators.
Torches and comparators delay the signal by one tick. Repeaters have a variable
delay from 1 to 4 ticks.

## Netlist

A netlist is a list of point to point connections from output devices to input
devices. Each entry in the netlist contains the position of the output device
and input device and the distance between them. An output device can power
many input devices and an input device can be powered by many output devices.

## Generate Netlists

The generation of the netlist is relatively simple. Scan the grid for output
components. For every output component start an A* pathfinding algorithm that
determines the shortest path for all input components within the 15 block
distance. When an input device has been found add it to a list and continue
the algorithm instead of stopping. After visiting all connected redstone wires
go over the list of input devices and add a netlist entry from the output
component to the input component and the distance of the shortest path.

## Pathfinding Algorithm

The shortest paths can be computed with a simple A* pathfinder.
Four datastructures are needed
- The grid with the redstone wires and input/output devices
- A metadata grid that stores the parent, score and closed state
- An open list that contains elements that have been visited but not processed
- A list of the found input devices

The algorithm steps are the following:

1. The start position is the output device.
2. Initially add all neighbouring devices of the output device to the open list.
3. Take any element from the open list and remove it
4. Visit every neighbour device of the current element
4. If the neighbour is marked closed then skip it
6. If the neighbour is an input element then add it to the list of input elements
7. Add the neighbour to the open list
8. Take the distance of the current element and add 1 to it.
9. If the distance of the neighbour is larger or equal but smaller than 15 then
set it to the current distance + 1 and set the parent of the neighbour to the
current element
10. Remove the element from the open list and add it to the closed list
11. Repeat 3. until the open list is empty

Finally go over the list of output devices and record their distances.

#
