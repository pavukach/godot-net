class_name ByteData
enum Type {
	BYTE,
	USHORT,
	UINT,
	INT,
	FLOAT,
	STRING,
	PEER,
}

static func wire_types(types: Array[ByteData.Type]) -> Array[ByteData.Type]:
	var out: Array[ByteData.Type] = []
	for type in types:
		if type != Type.PEER:
			out.append(type)
	return out


static func encode(args: Array, types: Array[ByteData.Type]) -> PackedByteArray:
	return _encode_wire(args, wire_types(types))


static func decode_with_peer(
	data: PackedByteArray,
	types: Array[ByteData.Type],
	sender_id: int,
) -> Array:
	var wire_args := decode(data, wire_types(types))
	var args: Array = []
	var wire_index := 0
	for type in types:
		if type == Type.PEER:
			args.append(sender_id)
		else:
			args.append(wire_args[wire_index])
			wire_index += 1
	return args


static func decode(data: PackedByteArray, types: Array) -> Array:
	return _decode_wire(data, types)


static func _encode_wire(args: Array, types: Array[ByteData.Type]) -> PackedByteArray:
	var stream := StreamPeerBuffer.new()
	for i in range(args.size()):
		var arg = args[i]
		match types[i]:
			Type.BYTE:
				stream.put_u8(arg)
			Type.USHORT:
				stream.put_u16(arg)
			Type.UINT:
				stream.put_u32(arg)
			Type.INT:
				stream.put_32(arg)
			Type.FLOAT:
				stream.put_float(arg)
			Type.STRING:
				stream.put_data(arg.to_utf8_buffer())
				stream.put_u8(0)
			Type.PEER:
				push_error("PEER must not be encoded on the wire")

	return stream.get_data_array()


static func _decode_wire(data: PackedByteArray, types: Array) -> Array:
	var args := []
	var stream := StreamPeerBuffer.new()
	stream.data_array = data

	for type in types:
		match type:
			Type.BYTE:
				args.append(stream.get_u8())
			Type.USHORT:
				args.append(stream.get_u16())
			Type.UINT:
				args.append(stream.get_u32())
			Type.INT:
				args.append(stream.get_32())
			Type.FLOAT:
				args.append(stream.get_float())
			Type.STRING:
				var bytes := []
				while true:
					var byte := stream.get_u8()
					if byte == 0:
						break
					bytes.append(byte)
				args.append(PackedByteArray(bytes).get_string_from_utf8())
			Type.PEER:
				push_error("PEER must not be decoded from the wire")

	return args