extends Node

func _ready():
	pass

func _process(delta):
	update(delta)

class Easing:
	static func apply(ease_name, type, p):
		match type:
			"in":
				p = call(ease_name, p)
			"out":
				p = 1.0 - p
				p = 1.0 - call(ease_name, p)
			"inout":
				p = p * 2.0
				if p < 1.0:
					p = .5 * call(ease_name, p)
				else:
					p = 2.0 - p
					p = .5 * (1.0 - call(ease_name, p)) + .5
		return p

	static func linear(p):
		return p

	static func quad(p):
		return p * p

	static func cubic(p):
		return p * p * p

	static func quart(p):
		return p * p * p * p

	static func quint(p):
		return p * p * p * p * p

	static func expo(p):
		return pow(2.0, 10 * (p - 1.0))

	static func sine(p):
		return -cos(p * (PI * .5)) + 1.0

	static func circ(p):
		return -(sqrt(1.0 - (p * p)) - 1.0)

	static func back(p):
		return p * p * (2.7 * p - 1.7)

	static func elastic(p):
		return -(pow(2.0, (10.0 * (p - 1.0))) * sin((p - 1.075) * (PI * 2.0) / .3))

	static func bounce(p):
		p = 1 - p
		if p < 0.363636:
			p = 7.5625 * p * p
		elif p < 0.727272:
			p = p - 0.545454
			p = 7.5625 * p * p + 0.75
		elif p < 0.909090:
			p = p - 0.818181
			p = 7.5625 * p * p + 0.9375
		else:
			p = p - 0.954545
			p = 7.5625 * p * p + 0.984375
		return 1 - p

var tweens = []
var obj_tweens = {}

class Tween:
	var easer
	var delay
	var onstart = []
	var onupdate = []
	var oncomplete = []

	var obj
	var rate
	var progress
	var _delay
	var _ease
	var _ease_type
	var vars
	var var_prev
	var mode
	var parent = null
	var next_tweens = []
	var flux

	func _init(object, time, varss, mode, fluxx):
		flux = fluxx
		obj = object
		rate = 1.0 / time if time > 0.0 else 0.0
		progress = 0.0 if time > 0.0 else 1.0
		_delay = 0.0
		_ease = "quad"
		_ease_type = "out"
		vars = {}
		var_prev = {}
		if mode == 'absolute':
			for key in varss:
				match key:
					"x":
						var x = object.get_transform().get_origin().x
						vars[key] = { start = x, diff = varss[key] - x}
					"y":
						var y = object.get_transform().get_origin().y
						vars[key] = { start = y, diff = varss[key] - y}
					"z":
						var z = object.get_transform().get_origin().z
						vars[key] = {start = z, diff = varss[key] - z}
					"angle":
						var angle = 0
						vars[key] = {start = angle, diff = varss[key] - angle}
		else:
			for key in varss:
				match key:
					"x":
						var x = object.get_transform().get_origin().x
						vars[key] = { start = x, diff = varss[key]}
					"y":
						var y = object.get_transform().get_origin().y
						vars[key] = { start = y, diff = varss[key]}
					"z":
						var z = object.get_transform().get_origin().z
						vars[key] = {start = z, diff = varss[key]}
					"angle":
						var angle = 0
						vars[key] = {start = angle, diff = varss[key]}

	func after(time, vars, mode='relative'):
		var t = flux.Tween.new(self.obj, time, vars, mode, flux)
		t.parent = self.parent
		self.next_tweens.append(t)
		self.oncomplete.append(funcref(self, "add_tween_on_complete"))
		return t

	func add_tween_on_complete():
		for t in self.next_tweens:
			flux.add(t)

	func ease(name, style):
		_ease = name
		_ease_type = style
		return self

	func play():
		flux.add(self)

	func stop():
		flux.remove(self)


func to(obj, time, vars, mode='relative'):
	print('test')
	return add(Tween.new(obj, time, vars, mode, self))

func add(tween):
	# Add to object table, create table if it does not exist
	self.tweens.append(tween)
	if not self.obj_tweens.has(tween.obj):
		self.obj_tweens[tween.obj] = {}
	else:
		self.obj_tweens[tween.obj].append(tween)
	tween.parent = self
	return tween

func clear(obj, vars):
	for t in self.obj_tweens[obj]:
		for key in t.vars:
			if t.vars[key] in vars:
				t.vars[key] = null
		if len(t.vars) == 0:
			t.oncomplete = {}

func remove(x):
	var obj = self.tweens[x].obj
	if self.obj_tweens[obj] == null:
		return
	self.obj_tweens.erase(obj)
	self.tweens[x] = self.tweens[len(self.tweens) - 1]
	self.tweens.remove(len(self.tweens) - 1)

func update(deltatime):
	for i in range(len(self.tweens) - 1, -1, -1):
		var t = self.tweens[i]
		if t._delay > 0:
			t._delay = t._delay - deltatime
		else:
			if len(t.onstart) > 0:
				for fct in t.onstart:
					fct.call_func()
				t.onstart = {}

			t.progress = t.progress + t.rate * deltatime
			var p = t.progress
			var x = (1 if p >= 1 else Easing.apply(t._ease, t._ease_type, p))
			for k in t.vars:
				var v = t.vars[k]
				if k == "x":
					if not t.var_prev.has(k):
						t.var_prev[k] = 0
					var xvDif = x * v.diff
					t.obj.translate(Vector2(xvDif - t.var_prev[k], 0))
					t.var_prev[k] = xvDif
				elif k == "y":
					if not t.var_prev.has(k):
						t.var_prev[k] = 0
					var xvDif = x * v.diff
					t.obj.translate(Vector2(0, xvDif - t.var_prev[k]))
					t.var_prev[k] = xvDif
				elif k == "angle":
					if not t.var_prev.has(k):
						t.var_prev[k] = 0
					var xvDif = x * v.diff
					t.obj.rotate(xvDif - t.var_prev[k])
					t.var_prev[k] = xvDif

			if len(t.onupdate) > 0:
				for fct in t.onupdate:
					fct.call_func()
			if p >= 1:
				remove(i)
				if len(t.oncomplete):
					for fct in t.oncomplete:
						fct.call_func()
