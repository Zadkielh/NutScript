nut.scroll = nut.scroll or {}
nut.scroll.buffer = nut.scroll.buffer or {}

local CHAR_DELAY = 0.1

if (CLIENT) then
	NUT_CVAR_SCROLLVOL = CreateClientConVar("nut_scrollvol", 40, true)

	function nut.scroll.Add(text, callback)
		local info = {text = "", callback = callback, nextChar = 0, char = ""}
		local index = table.insert(nut.scroll.buffer, info)
		local i = 1

		timer.Create("nut_Scroll"..tostring(info), CHAR_DELAY, #text, function()
			if (info) then
				info.text = string.sub(text, 1, i)
				i = i + 1

				LocalPlayer():EmitSound("common/talk.wav", NUT_CVAR_SCROLLVOL:GetInt(), math.random(120, 140))

				if (i >= #text) then
					info.char = ""
					info.start = CurTime() + 3
					info.finish = CurTime() + 5
				end
			end
		end)
	end

	local SCROLL_X = ScrW() * 0.9
	local SCROLL_Y = ScrH() * 0.7

	function nut.scroll.Paint()
		for k, v in pairs(nut.scroll.buffer) do
			local alpha = 255

			if (v.start and v.finish) then
				alpha = 255 - math.Clamp(math.TimeFraction(v.start, v.finish, CurTime()) * 255, 0, 255)
			elseif (v.nextChar < CurTime()) then
				v.nextChar = CurTime() + 0.025
				v.char = string.char(math.random(47, 90))
			end

			nut.util.DrawText(SCROLL_X, SCROLL_Y - (k * 24), v.text..v.char, Color(255, 255, 255, alpha), nil, 2, 1)

			if (alpha == 0) then
				if (v.callback) then
					v.callback()
				end

				table.remove(nut.scroll.buffer, k)
			end
		end
	end

	netstream.Hook("nut_ScrollData", function(data)
		nut.scroll.Add(data)
	end)
else
	function nut.scroll.Send(text, receiver, callback)
		netstream.Start(receiver, "nut_ScrollData", text)

		timer.Simple(CHAR_DELAY*#text + 4, function()
			if (callback) then
				callback()
			end
		end)
	end
end