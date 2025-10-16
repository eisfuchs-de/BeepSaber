extends Node3D

class_name SliceParticles

var base_particles: CPUParticles3D

var particleArray: Array[CPUParticles3D]
var materialsArray: Array[StandardMaterial3D]	# for ease of access / performance

# currently active particle emitter
var pointer := 0

func _enter_tree() -> void:
	# prepare the base particles to be duplicated, this way we can leave the particle
	# emitters off one-shot in the editor for easier tweaking
	base_particles = $BaseParticles
	base_particles.visible = false
	base_particles.one_shot = true
	base_particles.top_level = true
	base_particles.emitting = false

func _ready() -> void:
	@warning_ignore("return_value_discarded")
	Settings.changed.connect(on_settings_changed)

	base_particles.restart()

	on_settings_changed(&"extra_particle_effects")

func fire(correct: bool, collider_color: Color, collision_point: Vector3, cutplane: Plane, cut_speed: Vector3) -> void:
	if not Settings.extra_particle_effects:
		return

	var p := particleArray[pointer]

	# var cut_angle_abs := Vector2(cutplane.normal.x, cutplane.normal.y).angle()
	# p.rotation.z = cut_angle_abs + TAU * 0.25
	p.global_transform.origin = collision_point

	var force := cut_speed.length() * 0.01
	p.spread = base_particles.spread * minf(force * 2.0 + 0.1, 1.0)
	p.amount = int(float(base_particles.amount) * minf(force * 2.0 + 0.1, 1.0))
	p.direction = Vector3(cut_speed.x * 0.1, cut_speed.y * 0.1, -1).normalized()
	p.initial_velocity_min = force * 0.3
	p.initial_velocity_min = force * 0.5

	if not correct:
		collider_color = Color.WHITE

	materialsArray[pointer].albedo_color = collider_color
	materialsArray[pointer].emission = collider_color

	p.restart()
	p.visible = true
	p.emitting = true

	pointer += 1
	pointer = pointer % len(particleArray)

func on_settings_changed(what: String) -> void:
	if what != &"extra_particle_effects" and what != &"use_gpu_particles":
		return

	# clear particle and material arrays when particles are disabled
	if not Settings.extra_particle_effects or Settings.use_gpu_particles:
		while len(materialsArray):
			materialsArray.pop_back()

		while len(particleArray):
			particleArray[-1].queue_free()
			particleArray.pop_back()

		return

	# if we already have sufficiently large arrays, don't re-create them
	if len(particleArray) >= Constants.SLICE_EMITTERS and len(materialsArray) >= Constants.SLICE_EMITTERS:
		return

	for num: int in range(Constants.SLICE_EMITTERS):
		var newp : CPUParticles3D = base_particles.duplicate()
		newp.mesh = base_particles.mesh.duplicate()
		newp.mesh.surface_set_material(0, base_particles.mesh.surface_get_material(0).duplicate() as Material)

		add_child(newp)

		@warning_ignore("return_value_discarded")
		newp.finished.connect(on_particles_finished.bind(newp))

		newp.visible = false
		newp.emitting = false
		newp.name = "SliceParticles_%02d" % [num]

		newp.restart()

		particleArray.append(newp)
		materialsArray.append(newp.mesh.surface_get_material(0) as StandardMaterial3D)

func on_particles_finished(emitter: CPUParticles3D) -> void:
	# make expired particle emitters invisible, so no spurious particles
	# are emitted when this emitter gets reused
	emitter.visible = false
