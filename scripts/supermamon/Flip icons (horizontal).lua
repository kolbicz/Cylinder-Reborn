--[[ ******************************************************************
FlipIcons (Horizontal) v1.1
by @supermamon (github.com/supermamon/cylinder-scripts/)

v1.1 2014-02-16: Compatibility update for Cylinder v0.13.2.15
v1.0 2014-02-13: First release.
		
******************************************************************* ]]
local fade = dofile("include/fade.lua")
local iconFlip = dofile("include/iconFlip.lua")
local stayPut = dofile("include/stayPut.lua")

return function(page, offset, screen_width, screen_height)

	-- track progress
	local percent = offset/page.width
	
	-- ** PAGE EFFECTS ** --
    if math.abs(percent) >= 0.5 then
        page.alpha = 0
    end
	stayPut(page, offset)
	
	-- ** ICON EFFECTS ** --
    iconFlip(page, percent, "h")
end
