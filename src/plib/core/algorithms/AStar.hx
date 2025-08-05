package plib.core.algorithms;

import plib.core.structs.Direction;
import plib.core.structs.Matrix;
import plib.core.structs.Position;
import plib.core.structs.PriorityQueue;

class Node
{
	public var x:Int;
	public var y:Int;
	public var g:Float;
	public var h:Float;
	public var f:Float;
	public var parent:Node;

	public function new(x:Int, y:Int, g:Float, h:Float, parent:Node)
	{
		this.x = x;
		this.y = y;
		this.g = g;
		this.h = h;
		this.f = g + h;
		this.parent = parent;
	}

	public function getHashcode()
	{
		return x ^ y << 2;
	}
}

class Astar
{
	public function new() {}

	/**
		The matrix given must be the collision check.
		Any non 0 value in the matrix is treated as a collision.
	**/
	public function findPath(matrix:Matrix<Int>, start:Position, end:Position)
	{
		final openset = new PriorityQueue<Node>((a, b) -> a.f < b.f);
		final closedset = new Map<Int, Node>();

		final startNode = new Node(start.x, start.y, 0, heuristic(start.x, start.y, end.x, end.y), null);
		openset.add(startNode);

		while (!openset.isEmpty())
		{
			var current = openset.pop();
			if (current.x == end.x && current.y == end.y)
			{
				return reconstructPath(current);
			}

			closedset.set(flatten(matrix, current.x, current.y), current); // this might cause error. in that case, use flatten

			for (n in getNeighbors(matrix, current, end))
			{
				if (closedset.exists(flatten(matrix, n.x, n.y)))
					continue;

				var tentativeG = current.g + 1; // assume uniform cost
				var existing = openset.find(node -> node.x == n.x && node.y == n.y);
				if (existing == null || tentativeG < existing.g)
				{
					n.g = tentativeG;
					n.f = tentativeG + n.h;
					n.parent = current;

					if (existing == null)
					{
						openset.add(n);
					}
				}
			}
		}
		return [];
	}

	private inline function flatten(matrix:Matrix<Int>, x:Int, y:Int)
	{
		return y * matrix.wid + x;
	}

	private function reconstructPath(node:Node):Array<Position>
	{
		var path = [];
		while (node != null)
		{
			path.unshift(new Position(node.x, node.y));
			node = node.parent;
		}
		return path;
	}

	private function getNeighbors(matrix:Matrix<Int>, node:Node, goal:Position)
	{
		var neighbors = [];

		// randomizer to avoid getting the same path priority each time.
		// this is important for ai, and avoiding entities getting stuck in a pattern.
		var rand = Math.random();

		if (rand < 0.25)
		{
			processNeighbor(neighbors, matrix, node.x + 1, node.y, node, goal);
			processNeighbor(neighbors, matrix, node.x - 1, node.y, node, goal);
			processNeighbor(neighbors, matrix, node.x, node.y + 1, node, goal);
			processNeighbor(neighbors, matrix, node.x, node.y - 1, node, goal);
		}
		else if (rand < 0.5)
		{
			processNeighbor(neighbors, matrix, node.x - 1, node.y, node, goal);
			processNeighbor(neighbors, matrix, node.x + 1, node.y, node, goal);
			processNeighbor(neighbors, matrix, node.x, node.y + 1, node, goal);
			processNeighbor(neighbors, matrix, node.x, node.y - 1, node, goal);
		}
		else if (rand < 0.75)
		{
			processNeighbor(neighbors, matrix, node.x, node.y + 1, node, goal);
			processNeighbor(neighbors, matrix, node.x, node.y - 1, node, goal);
			processNeighbor(neighbors, matrix, node.x + 1, node.y, node, goal);
			processNeighbor(neighbors, matrix, node.x - 1, node.y, node, goal);
		}
		else
		{
			processNeighbor(neighbors, matrix, node.x, node.y - 1, node, goal);
			processNeighbor(neighbors, matrix, node.x, node.y + 1, node, goal);
			processNeighbor(neighbors, matrix, node.x + 1, node.y, node, goal);
			processNeighbor(neighbors, matrix, node.x - 1, node.y, node, goal);
		}
		return neighbors;
	}

	private function processNeighbor(list:Array<Node>, matrix:Matrix<Int>, x:Int, y:Int, node:Node, goal:Position)
	{
		if (matrix.inbounds(x, y) && matrix.get(x, y) == 0)
		{
			list.push(new Node(x, y, 0, heuristic(x, y, goal.x, goal.y), node));
		}
	}

	private function heuristic(x1:Int, y1:Int, x2:Int, y2:Int)
	{
		return Math.abs(x1 - x2) + Math.abs(y1 - y2); // Manhattan distance
	}
}
