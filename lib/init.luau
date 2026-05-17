local INITIAL_SIZE = 64

local Cursor = {}
Cursor.__index = Cursor

export type Cursor = typeof(setmetatable(
	{} :: {
		_buffer: buffer,
		_length: number,
		_offset: number,
		_unbufferizable: { any },
	},
	Cursor
))

function Cursor.new(): Cursor
	local self: Cursor = setmetatable({}, Cursor) :: any
	self._buffer = buffer.create(INITIAL_SIZE)
	self._length = INITIAL_SIZE
	self._offset = 0
	self._unbufferizable = {}
	return self
end

function Cursor.from(b: buffer, unbufferizable: { any }?): Cursor
	local self: Cursor = setmetatable({}, Cursor) :: any
	self._buffer = b
	self._length = buffer.len(b)
	self._offset = 0
	self._unbufferizable = unbufferizable or {}
	return self
end

function Cursor._grow(self: Cursor, bytes: number)
	local needed = self._offset + bytes
	if self._length >= needed then
		return
	end
	while self._length < needed do
		self._length *= 2
	end
	local new = buffer.create(self._length)
	buffer.copy(new, 0, self._buffer, 0, self._offset)
	self._buffer = new
end

function Cursor.flush(self: Cursor): (buffer, { any }?)
	local trimmed = buffer.create(self._offset)
	buffer.copy(trimmed, 0, self._buffer, 0, self._offset)
	local instances = if #self._unbufferizable > 0 then self._unbufferizable else nil
	return trimmed, instances
end

function Cursor.ended(self: Cursor): boolean
	return self._offset >= self._length
end

function Cursor.writeU8(self: Cursor, v: number)
	self:_grow(1)
	buffer.writeu8(self._buffer, self._offset, v)
	self._offset += 1
end

function Cursor.writeU16(self: Cursor, v: number)
	self:_grow(2)
	buffer.writeu16(self._buffer, self._offset, v)
	self._offset += 2
end

function Cursor.writeU32(self: Cursor, v: number)
	self:_grow(4)
	buffer.writeu32(self._buffer, self._offset, v)
	self._offset += 4
end

function Cursor.writeI8(self: Cursor, v: number)
	self:_grow(1)
	buffer.writei8(self._buffer, self._offset, v)
	self._offset += 1
end

function Cursor.writeI16(self: Cursor, v: number)
	self:_grow(2)
	buffer.writei16(self._buffer, self._offset, v)
	self._offset += 2
end

function Cursor.writeI32(self: Cursor, v: number)
	self:_grow(4)
	buffer.writei32(self._buffer, self._offset, v)
	self._offset += 4
end

function Cursor.writeF32(self: Cursor, v: number)
	self:_grow(4)
	buffer.writef32(self._buffer, self._offset, v)
	self._offset += 4
end

function Cursor.writeF64(self: Cursor, v: number)
	self:_grow(8)
	buffer.writef64(self._buffer, self._offset, v)
	self._offset += 8
end

function Cursor.writeBool(self: Cursor, v: boolean)
	self:_grow(1)
	buffer.writeu8(self._buffer, self._offset, if v then 1 else 0)
	self._offset += 1
end

function Cursor.writeString(self: Cursor, v: string)
	local len = #v
	self:_grow(2 + len)
	buffer.writeu16(self._buffer, self._offset, len)
	buffer.writestring(self._buffer, self._offset + 2, v)
	self._offset += 2 + len
end

function Cursor.writeBuffer(self: Cursor, v: buffer)
	local len = buffer.len(v)
	self:_grow(len)
	buffer.copy(self._buffer, self._offset, v)
	self._offset += len
end

function Cursor.writeAny(self: Cursor, v: any)
	table.insert(self._unbufferizable, v)
end

function Cursor.readU8(self: Cursor): number
	local v = buffer.readu8(self._buffer, self._offset)
	self._offset += 1
	return v
end

function Cursor.readU16(self: Cursor): number
	local v = buffer.readu16(self._buffer, self._offset)
	self._offset += 2
	return v
end

function Cursor.readU32(self: Cursor): number
	local v = buffer.readu32(self._buffer, self._offset)
	self._offset += 4
	return v
end

function Cursor.readI8(self: Cursor): number
	local v = buffer.readi8(self._buffer, self._offset)
	self._offset += 1
	return v
end

function Cursor.readI16(self: Cursor): number
	local v = buffer.readi16(self._buffer, self._offset)
	self._offset += 2
	return v
end

function Cursor.readI32(self: Cursor): number
	local v = buffer.readi32(self._buffer, self._offset)
	self._offset += 4
	return v
end

function Cursor.readF32(self: Cursor): number
	local v = buffer.readf32(self._buffer, self._offset)
	self._offset += 4
	return v
end

function Cursor.readF64(self: Cursor): number
	local v = buffer.readf64(self._buffer, self._offset)
	self._offset += 8
	return v
end

function Cursor.readBool(self: Cursor): boolean
	local v = buffer.readu8(self._buffer, self._offset)
	self._offset += 1
	return v == 1
end

function Cursor.readString(self: Cursor): string
	local len = buffer.readu16(self._buffer, self._offset)
	local v = buffer.readstring(self._buffer, self._offset + 2, len)
	self._offset += 2 + len
	return v
end

function Cursor.readAny(self: Cursor): Instance
	local v = self._unbufferizable[1]
	table.remove(self._unbufferizable, 1)
	return v
end

return Cursor
