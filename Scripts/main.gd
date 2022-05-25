extends Node

var time = 000000
var timer = false
var lifes = 4
var checkpoint = null

func _process(delta):
	if timer: 
		time += int(delta*60)
