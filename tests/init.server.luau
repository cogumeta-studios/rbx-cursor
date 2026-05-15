local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cursor = require(ReplicatedStorage.Cursor)
local Specium = require(ReplicatedStorage.DevPackages.Specium)

local expect = Specium.expect

local suite = Specium.suite("Cursor", function(ctx)
	ctx.describe("primitive serialization", function(ctx)
		local cursor: Cursor.Cursor
		ctx.beforeEach(function()
			cursor = Cursor.new()
		end)

		ctx.it("should write and read u8 properly", function()
			cursor:writeU8(123)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readU8()).toBe(123)

			return nil
		end)

		ctx.it("should write and read signed integers properly", function()
			cursor:writeI8(-12)
			cursor:writeI16(-1234)
			cursor:writeI32(-123456)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readI8()).toBe(-12)
			expect(read:readI16()).toBe(-1234)
			expect(read:readI32()).toBe(-123456)

			return nil
		end)

		ctx.it("should write and read floats properly", function()
			cursor:writeF32(3.14)
			cursor:writeF64(12345.6789)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(math.abs(read:readF32() - 3.14) < 0.001).toBe(true)
			expect(math.abs(read:readF64() - 12345.6789) < 0.0001).toBe(true)

			return nil
		end)

		ctx.it("should write and read booleans properly", function()
			cursor:writeBool(true)
			cursor:writeBool(false)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readBool()).toBe(true)
			expect(read:readBool()).toBe(false)

			return nil
		end)
	end)

	ctx.describe("string serialization", function(ctx)
		local cursor: Cursor.Cursor
		ctx.beforeEach(function()
			cursor = Cursor.new()
		end)

		ctx.it("should write and read strings properly", function()
			cursor:writeString("Hello, world!")

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readString()).toBe("Hello, world!")

			return nil
		end)

		ctx.it("should write and read empty strings properly", function()
			cursor:writeString("")

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readString()).toBe("")

			return nil
		end)

		ctx.it("should write and read large strings properly", function()
			local str = string.rep("a", 1000)

			cursor:writeString(str)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readString()).toBe(str)

			return nil
		end)
	end)

	ctx.describe("buffer serialization", function(ctx)
		local cursor: Cursor.Cursor
		ctx.beforeEach(function()
			cursor = Cursor.new()
		end)

		ctx.it("should write and read buffers properly", function()
			local b = buffer.create(1)
			buffer.writeu8(b, 0, 67)

			cursor:writeBuffer(b)

			local flushed = cursor:flush()
			local read = Cursor.from(flushed)

			expect(read:readU8()).toBe(67)

			return nil
		end)

		ctx.it("should preserve write order properly", function()
			cursor:writeU8(1)
			cursor:writeU16(2)
			cursor:writeU32(3)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:readU8()).toBe(1)
			expect(read:readU16()).toBe(2)
			expect(read:readU32()).toBe(3)

			return nil
		end)

		ctx.it("should grow properly when capacity is exceeded", function()
			for i = 1, 1000 do
				cursor:writeU8(i % 255)
			end

			local b = cursor:flush()
			local read = Cursor.from(b)

			for i = 1, 1000 do
				expect(read:readU8()).toBe(i % 255)
			end

			return nil
		end)
	end)

	ctx.describe("unbufferizable serialization", function(ctx)
		local cursor: Cursor.Cursor
		ctx.beforeEach(function()
			cursor = Cursor.new()
		end)

		ctx.it("should write and read unbufferizable values properly", function()
			local instance = Instance.new("Part")

			cursor:writeAny(instance)

			local b, refs = cursor:flush()
			local read = Cursor.from(b, refs)

			expect(read:readAny()).toBe(instance)

			return nil
		end)

		ctx.it("should preserve unbufferizable order properly", function()
			local a = Instance.new("Part")
			local b = Instance.new("Folder")
			local c = Instance.new("Model")

			cursor:writeAny(a)
			cursor:writeAny(b)
			cursor:writeAny(c)

			local flushed, refs = cursor:flush()
			local read = Cursor.from(flushed, refs)

			expect(read:readAny()).toBe(a)
			expect(read:readAny()).toBe(b)
			expect(read:readAny()).toBe(c)

			return nil
		end)
	end)

	ctx.describe("flush", function(ctx)
		local cursor: Cursor.Cursor
		ctx.beforeEach(function()
			cursor = Cursor.new()
		end)

		ctx.it("should flush properly", function()
			local instance = Instance.new("Part")

			local b = buffer.create(1)
			buffer.writeu8(b, 0, 67)

			cursor:writeU8(123)
			cursor:writeAny(instance)
			cursor:writeBuffer(b)

			local flushedBuffer, unbufferizable = cursor:flush()

			expect(buffer.readu8(flushedBuffer, 0)).toBe(123)
			expect(buffer.readu8(flushedBuffer, 1)).toBe(67)
			expect(unbufferizable).toEqual({ instance })

			return nil
		end)

		ctx.it("should flush empty buffers properly", function()
			local b, refs = cursor:flush()

			expect(buffer.len(b)).toBe(0)
			expect(refs).toBe(nil)

			return nil
		end)
	end)

	ctx.describe("state", function(ctx)
		local cursor: Cursor.Cursor
		ctx.beforeEach(function()
			cursor = Cursor.new()
		end)

		ctx.it("should detect end properly", function()
			cursor:writeU8(1)

			local b = cursor:flush()
			local read = Cursor.from(b)

			expect(read:ended()).toBe(false)

			read:readU8()

			expect(read:ended()).toBe(true)

			return nil
		end)
	end)
end)

local output = Specium.run(suite)
print(output)
