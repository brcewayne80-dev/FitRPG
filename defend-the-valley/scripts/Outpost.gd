extends Node2D
class_name Outpost

func get_muzzles() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	for c in get_children():
		var m := c as Marker2D
		if m != null and m.name.begins_with("Outpost") and m.name.ends_with("Archer"):
			result.append(m)
	return result
