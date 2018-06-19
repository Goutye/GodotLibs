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
		obj = weakref(object)
		rate = 1.0 / time if time > 0.0 else 0.0
		progress = 0.0 if time > 0.0 else 1.0
		_delay = 0.0
		_ease = "quad"
		_ease_type = "out"
		vars = {}
		var_prev = {}
		if (!obj.get_ref()):
			return
		else:
			object = obj.get_ref()
		if mode == 'absolute':
			for key in varss:
				var x = null
				match key:
					"x":
						x = object.get_transform().get_origin().x
					"y":
						x = object.get_transform().get_origin().y
					"z":
						x = object.get_transform().get_origin().z
					"ui_x":
						x = object.rect_position.x
					"ui_y":
						x = object.rect_position.y
					"angle":
						x = 0
					_:
						x = object[key]
				vars[key] = { start = x, diff = varss[key] - x}	
		else:
			for key in varss:
				var x = null
				match key:
					"x":
						x = object.get_transform().get_origin().x
					"y":
						x = object.get_transform().get_origin().y
					"z":
						x = object.get_transform().get_origin().z
					"ui_x":
						x = object.rect_position.x
					"ui_y":
						x = object.rect_position.y
					"angle":
						x = 0
					_:
						x = object[key]
				vars[key] = { start = x, diff = varss[key]}

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
	return add(Tween.new(obj, time, vars, mode, self))

func add(tween):
	# Add to object table, create table if it does not exist
	self.tweens.append(tween)
	if not self.obj_tweens.has(tween.obj.get_ref()):
		self.obj_tweens[tween.obj.get_ref()] = [tween]
	else:
		self.obj_tweens[tween.obj.get_ref()].append(tween)
	tween.parent = self
	return tween

func clear(obj, vars):
	for t in self.obj_tweens[obj.get_ref()]:
		for key in t.vars:
			if t.vars[key] in vars:
				t.vars[key] = null
		if len(t.vars) == 0:
			t.oncomplete = {}

func remove(x):
	var obj = self.tweens[x].obj
	if not self.obj_tweens.has(obj.get_ref()):
		return
	self.obj_tweens[obj.get_ref()].erase(self.tweens[x])
	self.tweens[x] = self.tweens[len(self.tweens) - 1]
	self.tweens.remove(len(self.tweens) - 1)

func update(deltatime):
	for i in range(len(self.tweens) - 1, -1, -1):
		var t = self.tweens[i]
		if (!t.obj.get_ref()):
			continue
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
				if not t.var_prev.has(k):
					t.var_prev[k] = 0
				var xvDif = x * v.diff
				match k:
					"x":
						t.obj.get_ref().translate(Vector2(xvDif - t.var_prev[k], 0))
					"y":
						t.obj.get_ref().translate(Vector2(0, xvDif - t.var_prev[k]))
					"z":
						t.obj.get_ref().translate(Vector3(0, 0, xvDif - t.var_prev[k]))
					"ui_x":
						t.obj.get_ref().rect_position.x += (xvDif - t.var_prev[k])
					"ui_y":
						t.obj.get_ref().rect_position.y += (xvDif - t.var_prev[k])
					"angle":
						t.obj.get_ref().rotate(xvDif - t.var_prev[k])
					_:
						t.obj.get_ref()[k] += xvDif - t.var_prev[k]
				match k:
					"ui_x":
						continue
					"ui_y":
						t.var_prev[k] = floor(xvDif)
					_:
						t.var_prev[k] = xvDif

			if len(t.onupdate) > 0:
				for fct in t.onupdate:
					fct.call_func()
			if p >= 1:
				remove(i)
				#Fix for UI when too many tweens would sweep the UI element away
				if len(self.obj_tweens[t.obj.get_ref()]) == 0:
					for k in t.vars:
						var v = t.vars[k]
						if k == "ui_x":
							t.obj.get_ref().rect_position.x = (v.start + v.diff)
						elif k == "ui_y":
							t.obj.get_ref().rect_position.y = (v.start + v.diff)
				if len(t.oncomplete):
					for fct in t.oncomplete:
						fct.call_func()
