extends KinematicBody2D

export var ACC = 150
export var MAXSPEED = 30000
export var FRIC = 500
export var MAXJUMP = 100
var sprite = 'idle'
var state = 'idle'
var i = 0
var dir = Vector2.ZERO
var vel = Vector2.ZERO
var jumping = false
var rolling = false
var rolldir = 0
var rollvel = 0
var rings = 0

func _ready():
	if main.checkpoint != null:
		global_position = main.checkpoint

func _process(delta):
	$RayCast2D.force_raycast_update()
	hud()
	controls()
	move(delta)
	if $AnimatedSprite.animation != sprite: $AnimatedSprite.animation = sprite
	if $AnimatedSprite.speed_scale != 1: $AnimatedSprite.speed_scale = 1
	if vel.x<-10 and $AnimatedSprite.flip_h != true: $AnimatedSprite.flip_h = true
	elif vel.x>10 and $AnimatedSprite.flip_h != false: $AnimatedSprite.flip_h = false
	if sprite == 'jump': $CollisionShape2D.shape = preload("res://Shapes/Player-1.tres")
	else: $CollisionShape2D.shape = preload("res://Shapes/Player-0.tres")
	match state:
		'hurt':
			if sprite != 'hurtx':
				sprite = 'hurt'
			if abs(vel.y) < 10:
				state = 'roll'
		'sjump':
			if sprite!='sjump':sprite = 'sjump'
			if is_on_wall() or is_on_ceiling() or is_on_floor():
				state = 'roll'
		'down':
			i = 0
			if rollvel != 0:
				if Input.is_action_just_released("ui_accept"):
					$AudioStreamPlayer2D.stream = preload("res://Sounds/Roll.wav")
					$AudioStreamPlayer2D.play()
					vel.x = rollvel*rolldir
					rolling = true
					state = 'move'
					rollvel = 0
			if Input.is_action_just_released("ui_down"): 
				sprite = 'downy'
			if Input.is_action_just_pressed("ui_accept"):
				if $AnimatedSprite.flip_h: rolldir = -1
				else: rolldir = 1
				rollvel = 0
				FRIC = 0
			if Input.is_action_pressed("ui_accept"):
				if $AudioStreamPlayer2D.stream != preload("res://Sounds/Charge.wav"):
					$AudioStreamPlayer2D.stream = preload("res://Sounds/Charge.wav")
					$AudioStreamPlayer2D.playing = true
				sprite = 'spin'
				if rollvel < 500:
					rollvel += 10
					$AnimatedSprite.speed_scale = rollvel/50
			elif !'down' in sprite:
				sprite = 'down'
		'roll':
			i = 0
			rolling = false
			sprite = 'jump'
		'idle':
			rolling = false
			if i == 0 and !'bored' in sprite: sprite = 'idle'
		'move':
			i = 0
			if !rolling:
				FRIC = 500
				if vel.x == 0:
					state = 'idle'
				elif abs(vel.x) <=25:
					state = 'idle'
				elif abs(vel.x) <=200:
					sprite = 'walk'
				elif abs(vel.x) <=300:
					sprite = 'jog'
				elif abs(vel.x) <=500:
					sprite = 'run'
				else:
					sprite = 'dash'
			else:
				if abs(vel.x) < 10:
					rolling = false
				sprite = 'jump'
			if Input.is_action_pressed("ui_down") and dir.x == 0 and rolling!=true:
				$AudioStreamPlayer2D.stream = preload("res://Sounds/Roll.wav")
				$AudioStreamPlayer2D.play()
				rolling = true

func hud():
	$CanvasLayer/time.text = str(main.time)
	$CanvasLayer/rings.text = str(rings)
	$CanvasLayer/lifes.text = str(main.lifes)

func move(delta):
	if dir.x != 0:
		vel.x += dir.x*ACC*delta
		vel.x = vel.clamped(MAXSPEED*delta).x
	else:
		vel.x = vel.move_toward(Vector2.ZERO, FRIC*delta).x
	if jumping:
		if vel.y <= -MAXJUMP or is_on_ceiling():
			vel.y = -MAXJUMP
			jumping = false
		dir.y = -1
	vel.y += dir.y*ACC*delta
	vel = move_and_slide(vel, Vector2.UP, false, 4, 0.785398, false)

func controls():
	if state != 'sjump' and state != 'hurt':
		dir = Vector2.DOWN
		if abs(vel.x) >= 10 and (is_on_floor() or $RayCast2D.is_colliding()) and !jumping:
			state = 'move'
		elif (is_on_floor() or $RayCast2D.is_colliding()) and !jumping:
			state = 'idle'
			if Input.is_action_pressed("ui_down"):
				state = 'down'
		if state != 'down':
			dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
			if Input.is_action_just_pressed("ui_accept"):
				vel.x /= 2
			if Input.is_action_just_pressed("ui_accept"):
				if is_on_floor() or $RayCast2D.is_colliding():
					$AudioStreamPlayer2D.stream = preload("res://Sounds/Jump.wav")
					$AudioStreamPlayer2D.play()
					state = 'roll'
					jumping = true
			if Input.is_action_just_released("ui_accept"):
				if jumping:
					if vel.y >=-100:
						vel.y = -100
					jumping = false

func _on_AnimatedSprite_animation_finished():
	match sprite:
		'idle':
			i+=1
			if i >= 30:
				sprite = 'bored1'
				i = 0
		'down':
			sprite = 'downx'
		'downy':
			i = 0
			state = 'idle'
		'bored1':
			sprite = 'bored1x'
		'bored1x':
			i+=1
			if i >= 12:
				sprite = 'bored2'
				i = 0
		'bored2':
			sprite = 'bored2x'
		'bored2x':
			i+=1
			if i >=2:
				sprite = 'bored2y'
				i = 0
		'bored2y':
			i+=1
			if i >=4:
				sprite = 'bored2z'
				i = 0
		'bored2z':
			sprite = 'idle'
		'hurt':
			sprite = 'hurtx'

func die(pos):
	if !'hurt' in sprite :
		if rings == 0:
			main.lifes -= 1
			if main.lifes == 0:
				get_tree().change_scene("res://Scenes/Game Over.tscn")
			else:
				$AnimationPlayer.play("die")
				get_tree().paused = true
		else:
			$AudioStreamPlayer2D.stream = preload("res://Sounds/LoseRings.wav")
			$AudioStreamPlayer2D.play()
			if pos.y < global_position.y: vel.y = 100
			else: vel.y = -100
			if pos.x < global_position.x: vel.x = 100
			elif pos.x > global_position.x: vel.x = -100
			else: vel.x = 0
			state = 'hurt'
			sprite = state
			if rings > 1:
				rings = int(rings/2)
			for i in range(rings):
				var vr = preload("res://Scenes/VRing.tscn").instance()
				vr.global_position = global_position
				if i > (rings/2):
					vr.xvel = -vr.xvel
				owner.get_node('Rings').add_child(vr)
			rings = 0

func change_level():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'die':
		change_level()
