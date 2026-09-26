class_name NetInterp
extends RefCounted

static func linear(from: Variant, to: Variant, weight: float) -> Variant:
	return lerpf(from, to, weight)


static func angle(from: Variant, to: Variant, weight: float) -> Variant:
	return lerp_angle(from, to, weight)


static func hold(from: Variant, _to: Variant, _weight: float) -> Variant:
	return from
