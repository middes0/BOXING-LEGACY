extends Node3D

const PLAYER_COLOR := Color(0.12, 0.55, 0.95)
const ENEMY_COLOR := Color(0.92, 0.20, 0.16)

var player: Node3D
var enemy: Node3D
var player_hp := 100.0
var enemy_hp := 100.0
var stamina := 100.0
var punch_cooldown := 0.0
var enemy_cooldown := 0.0
var round_time := 180.0
var game_over := false

var hp_player_bar: ProgressBar
var hp_enemy_bar: ProgressBar
var stamina_bar: ProgressBar
var status_label: Label
var timer_label: Label
var move_axis := Vector2.ZERO

func _ready() -> void:
    _build_world()
    _build_fighter(true)
    _build_fighter(false)
    _build_hud()
    _update_hud()

func _process(delta: float) -> void:
    if game_over:
        return
    round_time = maxf(0.0, round_time - delta)
    punch_cooldown = maxf(0.0, punch_cooldown - delta)
    enemy_cooldown = maxf(0.0, enemy_cooldown - delta)
    stamina = minf(100.0, stamina + delta * 10.0)
    _player_movement(delta)
    _enemy_brain(delta)
    _update_hud()
    if round_time <= 0.0:
        _finish_round("TEMPO ESGOTADO")

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.025, 0.035, 0.06)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.78, 0.9)
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-48, -25, 0)
    light.light_energy = 1.5
    add_child(light)

    _box(Vector3(0, -0.25, 0), Vector3(14, 0.5, 9), Color(0.10, 0.12, 0.16))
    _box(Vector3(0, 0.12, 0), Vector3(9.0, 0.35, 6.2), Color(0.08, 0.09, 0.12))
    _box(Vector3(0, 0.34, 0), Vector3(8.2, 0.12, 5.4), Color(0.88, 0.88, 0.83))
    _box(Vector3(0, 0.42, 0), Vector3(7.8, 0.05, 5.0), Color(0.16, 0.30, 0.42))

    for x in [-4.0, 4.0]:
        for z in [-2.55, 2.55]:
            _box(Vector3(x, 1.2, z), Vector3(0.16, 2.4, 0.16), Color(0.12, 0.12, 0.14))
    for y in [0.9, 1.55, 2.2]:
        for z in [-2.55, 2.55]:
            _box(Vector3(0, y, z), Vector3(8.0, 0.055, 0.055), Color(0.86, 0.12, 0.16))
        for x in [-4.0, 4.0]:
            _box(Vector3(x, y, 0), Vector3(0.055, 0.055, 5.1), Color(0.86, 0.12, 0.16))

    var camera := Camera3D.new()
    camera.position = Vector3(0, 6.5, 12.5)
    camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
    camera.fov = 43
    add_child(camera)
    camera.current = true
    _box(Vector3(0, 3.0, -4.5), Vector3(16, 7, 0.3), Color(0.035, 0.05, 0.085))

func _build_fighter(is_player: bool) -> void:
    var root := Node3D.new()
    root.name = "Player" if is_player else "Opponent"
    root.position = Vector3(-1.8, 0.48, 0.0) if is_player else Vector3(1.8, 0.48, 0.0)
    add_child(root)

    # Visual de boxeador estilizado: silhueta atlética, roupa e equipamento.
    var facing := 1.0 if is_player else -1.0
    var skin := Color(0.40, 0.24, 0.16) if is_player else Color(0.68, 0.43, 0.29)
    var skin_shadow := skin.darkened(0.22)
    var outfit := Color(0.05, 0.30, 0.72) if is_player else Color(0.72, 0.08, 0.10)
    var outfit_dark := outfit.darkened(0.35)
    var glove := Color(0.04, 0.16, 0.42) if is_player else Color(0.48, 0.025, 0.035)
    var boot := Color(0.035, 0.04, 0.055)
    var hair := Color(0.035, 0.025, 0.02) if is_player else Color(0.12, 0.055, 0.025)

    # Tronco, pescoço e cintura.
    _capsule(root, Vector3(0, 1.02, 0), 0.39, 0.98, skin)
    _capsule(root, Vector3(0, 0.67, 0), 0.37, 0.48, outfit)
    _box_child(root, Vector3(0, 0.91, 0.015), Vector3(0.66, 0.10, 0.48), outfit_dark)
    _capsule(root, Vector3(0, 1.49, 0), 0.13, 0.30, skin_shadow)

    # Ombros, braços e luvas grandes de boxe.
    for side in [-1.0, 1.0]:
        _sphere(root, Vector3(side * 0.39, 1.34, 0), 0.22, skin)
        _capsule(root, Vector3(side * 0.43, 1.12, 0), 0.145, 0.48, skin)
        _capsule(root, Vector3(side * 0.40, 0.91, 0.015), 0.13, 0.34, skin_shadow)
        _capsule(root, Vector3(side * 0.39, 1.34, 0.10), 0.17, 0.28, glove)
        _sphere(root, Vector3(side * 0.39, 1.48, 0.10), 0.17, glove)
        _sphere(root, Vector3(side * 0.39, 1.25, 0.10), 0.15, glove)
        _box_child(root, Vector3(side * 0.39, 1.34, 0.235), Vector3(0.20, 0.055, 0.025), Color(0.88, 0.88, 0.90))

    # Shorts com cós e detalhes laterais.
    _box_child(root, Vector3(0, 0.55, 0), Vector3(0.72, 0.43, 0.48), outfit)
    _box_child(root, Vector3(0, 0.76, 0), Vector3(0.73, 0.075, 0.49), Color(0.92, 0.88, 0.72))
    _box_child(root, Vector3(-0.30, 0.53, 0.245), Vector3(0.045, 0.30, 0.025), outfit_dark)
    _box_child(root, Vector3(0.30, 0.53, 0.245), Vector3(0.045, 0.30, 0.025), outfit_dark)

    # Pernas, joelhos e botas.
    for side in [-1.0, 1.0]:
        _capsule(root, Vector3(side * 0.19, 0.27, 0), 0.145, 0.55, skin)
        _sphere(root, Vector3(side * 0.19, 0.34, 0.015), 0.15, skin_shadow)
        _capsule(root, Vector3(side * 0.19, 0.105, 0.035), 0.145, 0.25, boot)
        _box_child(root, Vector3(side * 0.19, 0.055, 0.13), Vector3(0.28, 0.10, 0.40), boot)
        _box_child(root, Vector3(side * 0.19, 0.16, 0.19), Vector3(0.23, 0.035, 0.025), Color(0.78, 0.78, 0.82))

    # Cabeça, orelhas e cabelo.
    _sphere(root, Vector3(0, 1.78, 0), 0.285, skin)
    _sphere(root, Vector3(-facing * 0.265, 1.79, 0), 0.075, skin_shadow)
    _sphere(root, Vector3(0, 1.96, -0.015), 0.235, hair)
    _sphere(root, Vector3(-0.13, 1.91, 0.13), 0.13, hair)
    _sphere(root, Vector3(0.13, 1.91, 0.13), 0.13, hair)

    # Rosto voltado para o adversário: sobrancelha, olhos, nariz e boca.
    var face_x := facing * 0.235
    for side in [-1.0, 1.0]:
        _sphere(root, Vector3(face_x, 1.82, side * 0.105), 0.035, Color(0.96, 0.91, 0.82))
        _sphere(root, Vector3(face_x + facing * 0.025, 1.82, side * 0.105), 0.018, Color(0.08, 0.045, 0.025))
        _box_child(root, Vector3(face_x, 1.88, side * 0.105), Vector3(0.035, 0.035, 0.10), hair)
    _sphere(root, Vector3(facing * 0.285, 1.75, 0), 0.045, skin_shadow)
    _box_child(root, Vector3(facing * 0.267, 1.68, 0), Vector3(0.035, 0.025, 0.12), Color(0.16, 0.045, 0.035))

    if is_player:
        player = root
    else:
        enemy = root

func _box(pos: Vector3, size: Vector3, color: Color) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    add_child(instance)

func _sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    parent.add_child(instance)

func _capsule(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = pos
    instance.material_override = _material(color)
    parent.add_child(instance)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.78
    return material

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    var title := Label.new()
    title.text = "BOXING LEGACY  •  COMBATE LIVRE"
    title.position = Vector2(28, 14)
    title.add_theme_font_size_override("font_size", 25)
    title.add_theme_color_override("font_color", Color.WHITE)
    root.add_child(title)

    hp_player_bar = _bar(root, Vector2(28, 58), Vector2(360, 24), PLAYER_COLOR)
    hp_enemy_bar = _bar(root, Vector2(892, 58), Vector2(360, 24), ENEMY_COLOR)
    stamina_bar = _bar(root, Vector2(28, 91), Vector2(220, 12), Color(0.95, 0.72, 0.12))

    timer_label = Label.new()
    timer_label.position = Vector2(600, 54)
    timer_label.size = Vector2(100, 40)
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    timer_label.add_theme_font_size_override("font_size", 28)
    root.add_child(timer_label)

    status_label = Label.new()
    status_label.position = Vector2(0, 115)
    status_label.size = Vector2(1280, 40)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
    root.add_child(status_label)

    _make_button(root, "◀", Vector2(30, 570), Vector2(90, 90), "left")
    _make_button(root, "▶", Vector2(130, 570), Vector2(90, 90), "right")
    _make_button(root, "ESQUIVA", Vector2(235, 570), Vector2(115, 90), "dodge")
    _make_button(root, "JAB", Vector2(855, 570), Vector2(105, 90), "jab")
    _make_button(root, "DIRETO", Vector2(970, 570), Vector2(115, 90), "cross")
    _make_button(root, "GANCHO", Vector2(1090, 570), Vector2(150, 90), "hook")

    var hint := Label.new()
    hint.text = "MOVA-SE  •  DEFENDA-SE  •  ACERTE O ADVERSÁRIO"
    hint.position = Vector2(0, 680)
    hint.size = Vector2(1280, 25)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
    root.add_child(hint)

func _bar(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = pos
    bar.size = size
    bar.min_value = 0
    bar.max_value = 100
    bar.show_percentage = false
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.corner_radius_top_left = 6
    fill.corner_radius_top_right = 6
    fill.corner_radius_bottom_left = 6
    fill.corner_radius_bottom_right = 6
    bar.add_theme_stylebox_override("fill", fill)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.12, 0.14, 0.19, 0.95)
    bar.add_theme_stylebox_override("background", bg)
    parent.add_child(bar)
    return bar

func _make_button(parent: Control, text_value: String, pos: Vector2, size: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = text_value
    button.position = pos
    button.size = size
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", Color.WHITE)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0.08, 0.12, 0.19, 0.92)
    normal.border_color = Color(0.35, 0.48, 0.65)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(14)
    button.add_theme_stylebox_override("normal", normal)
    var pressed := StyleBoxFlat.new()
    pressed.bg_color = Color(0.18, 0.32, 0.48, 1)
    pressed.set_corner_radius_all(14)
    button.add_theme_stylebox_override("pressed", pressed)
    parent.add_child(button)
    if action == "left":
        button.button_down.connect(func(): move_axis.x = -1.0)
        button.button_up.connect(_stop_left)
    elif action == "right":
        button.button_down.connect(func(): move_axis.x = 1.0)
        button.button_up.connect(_stop_right)
    elif action == "dodge":
        button.pressed.connect(_dodge)
    elif action == "jab":
        button.pressed.connect(func(): _punch(8.0, 0.45, "JAB"))
    elif action == "cross":
        button.pressed.connect(func(): _punch(13.0, 0.8, "DIRETO"))
    elif action == "hook":
        button.pressed.connect(func(): _punch(17.0, 1.1, "GANCHO"))

func _stop_left() -> void:
    if move_axis.x < 0.0:
        move_axis.x = 0.0

func _stop_right() -> void:
    if move_axis.x > 0.0:
        move_axis.x = 0.0

func _player_movement(delta: float) -> void:
    if player == null:
        return
    player.position.x = clampf(player.position.x + move_axis.x * delta * 3.2, -3.1, 3.1)
    player.position.z = clampf(player.position.z, -1.35, 1.35)
    if Input.is_key_pressed(KEY_A):
        player.position.x -= delta * 3.2
    if Input.is_key_pressed(KEY_D):
        player.position.x += delta * 3.2

func _enemy_brain(delta: float) -> void:
    if enemy == null or player == null:
        return
    var distance := enemy.position.distance_to(player.position)
    var dx := player.position.x - enemy.position.x
    if absf(dx) > 1.45:
        enemy.position.x += signf(dx) * delta * 1.25
    if distance < 2.0 and enemy_cooldown <= 0.0:
        enemy_cooldown = randf_range(1.0, 1.7)
        if randf() < 0.72:
            _damage_player(randf_range(5.0, 9.0))
            status_label.text = "O ADVERSÁRIO ACERTOU!"
        else:
            status_label.text = "O ADVERSÁRIO ERROU!"

func _punch(damage: float, cost: float, punch_name: String) -> void:
    if game_over or punch_cooldown > 0.0:
        return
    if stamina < cost * 2.0:
        status_label.text = "SEM ENERGIA! RECUPERE A RESISTÊNCIA."
        return
    stamina -= cost * 2.0
    punch_cooldown = 0.38 if punch_name == "JAB" else 0.62
    var distance := player.position.distance_to(enemy.position)
    if distance <= 2.45:
        enemy_hp = maxf(0.0, enemy_hp - damage)
        enemy.position.x = minf(3.1, enemy.position.x + 0.18)
        status_label.text = punch_name + " CONECTOU! -" + str(int(damage)) + " HP"
        if enemy_hp <= 0.0:
            _finish_round("NOCAUTE! VOCÊ VENCEU")
    else:
        status_label.text = punch_name + " NÃO ALCANÇOU O ALVO."

func _dodge() -> void:
    if game_over:
        return
    player.position.x = clampf(player.position.x - 0.55, -3.1, 3.1)
    stamina = maxf(0.0, stamina - 8.0)
    status_label.text = "ESQUIVA!"

func _damage_player(amount: float) -> void:
    player_hp = maxf(0.0, player_hp - amount)
    if player_hp <= 0.0:
        _finish_round("NOCAUTE! VOCÊ PERDEU")

func _update_hud() -> void:
    if hp_player_bar:
        hp_player_bar.value = player_hp
        hp_enemy_bar.value = enemy_hp
        stamina_bar.value = stamina
        timer_label.text = "%02d:%02d" % [int(round_time) / 60, int(round_time) % 60]

func _finish_round(message: String) -> void:
    game_over = true
    status_label.text = message + "  •  REINICIE PARA JOGAR NOVAMENTE"
    var restart := Button.new()
    restart.text = "JOGAR NOVAMENTE"
    restart.position = Vector2(515, 400)
    restart.size = Vector2(250, 65)
    restart.add_theme_font_size_override("font_size", 22)
    get_node("HUD").add_child(restart)
    restart.pressed.connect(func(): get_tree().reload_current_scene())
