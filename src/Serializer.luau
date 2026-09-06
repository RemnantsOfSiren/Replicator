--!strict
local Types = require(script.Parent.Types)

local ValidKey = { "string", "number" }

local function ConvertToPacket(Info: { any }): { Types.PacketKey }
	local Packet = {}

	for _, Key in pairs(Info) do
		local _type = type(Key)

		if not table.find(ValidKey, _type) then
			if _type == "table" and Key.IsNumber then
				continue
			else
				error(`Invalid key type: {_type}. Expected 'string' or 'number'.`)
			end
		end

		table.insert(Packet, {
			Key = tostring(Key),
			IsNumber = _type == "number",
		})
	end

	return Packet
end

local function ConvertToPath(Packet: { Types.PacketKey }): { string | number }
	local Path: { string | number } = {}

	for _, PacketInfo in Packet do
		table.insert(Path, if PacketInfo.IsNumber then tonumber(PacketInfo.Key) :: number else PacketInfo.Key)
	end

	return Path
end

return {
	ConvertToPath = ConvertToPath,
	ConvertToPacket = ConvertToPacket,
}
