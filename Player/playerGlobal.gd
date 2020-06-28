extends Node

enum {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var direction

var inventoryList : Dictionary

var spawn_location = Vector2(410, 188)

var coins = 1000

var interactedObjects : Dictionary

var interactedNPCs : Dictionary

var cutscenes : Array
