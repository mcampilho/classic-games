class_name Settings
extends RefCounted
## Preferências guardadas entre sessões (user://settings.cfg).

const PATH := "user://settings.cfg"
static var _cfg: ConfigFile


static func _ensure() -> void:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(PATH)


static func get_value(section: String, key: String, default: Variant) -> Variant:
	_ensure()
	return _cfg.get_value(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> void:
	_ensure()
	_cfg.set_value(section, key, value)
	_cfg.save(PATH)
