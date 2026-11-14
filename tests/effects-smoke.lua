-- Host-side Lua 5.5 smoke test. Models the public geometry API, not UIKit rendering.
local root = assert(arg[1], "usage: lua tests/effects-smoke.lua scripts <effect files...>")
local originalLoad = loadfile
local cases, failures = 0, {}
local function finite(value)
    assert(type(value) == "number" and value == value and math.abs(value) < math.huge,
        "effect produced a non-finite number")
end
local methods = {}
function methods:rotate(angle, ...) finite(angle); for _, v in ipairs({...}) do finite(v) end end
function methods:translate(...) for _, v in ipairs({...}) do finite(v) end end
function methods:scale(...) for _, v in ipairs({...}) do finite(v) end end
function methods:center() return self.x + self.width / 2, self.y + self.height / 2 end
local function view(values)
    local layer = {x = values.x, y = values.y, width = values.width, height = values.height, transform = {}}
    values.layer = setmetatable({}, {
        __index = layer,
        __newindex = function(t, key, value)
            if key == "transform" then for _, component in ipairs(value) do finite(component) end
            else finite(value) end
            layer[key] = value
        end,
    })
    return setmetatable({}, {
        __index = function(_, key) return values[key] or methods[key] end,
        __newindex = function(_, key, value)
            if key == "alpha" then finite(value) end
            values[key] = value
        end,
        __len = function() return #values end,
    })
end
local function pageFor(columns, rows, count, landscape)
    local width, height = landscape and 1194 or 834, landscape and 834 or 1194
    local page = view({x = 0, y = 0, width = width, height = height,
        max_columns = columns, max_rows = rows, max_icons = columns * rows, alpha = 1})
    for i = 1, count do
        local row, column = (i - 1) // columns, (i - 1) % columns
        page[i] = view({row = row, column = column, x = 30 + column * 90,
            y = 40 + row * 100, width = 60, height = 60, alpha = 1})
    end
    page.subviews = page
    return page
end
for fileIndex = 2, #arg do
    local relative = arg[fileIndex]
    if not relative:match("/include/") and not relative:match("EXAMPLE.lua$") then
        local folder = relative:match("^(.*)/[^/]+$")
        local environment = setmetatable({
            BASE_TRANSFORM = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},
            PERSPECTIVE_DISTANCE = 1014,
            subviews = ipairs,
        }, {__index = _G})
        function environment.loadfile(name)
            return originalLoad(root .. "/" .. folder .. "/" .. name, "t", environment)
        end
        function environment.dofile(name) return assert(environment.loadfile(name))() end
        local ok, effect = pcall(function()
            return assert(originalLoad(root .. "/" .. relative, "t", environment))()
        end)
        if not ok then failures[#failures + 1] = relative .. ": " .. tostring(effect)
        else
            for _, grid in ipairs({{4,6,24,false}, {6,4,24,true}, {8,5,37,true}, {6,4,1,true}, {6,4,0,true}}) do
                for _, progress in ipairs({-1,-0.9,-0.5,-0.01,0,0.01,0.5,0.9,1}) do
                    local page = pageFor(table.unpack(grid))
                    local success, err = pcall(effect, page, progress * page.width, page.width, page.height)
                    cases = cases + 1
                    if not success then
                        failures[#failures + 1] = relative .. " (count=" .. grid[3] .. ", offset=" .. progress .. "): " .. tostring(err)
                    end
                end
            end
        end
    end
end
print(string.format("%d effect scenarios, %d failures", cases, #failures))
for _, failure in ipairs(failures) do print(failure) end
os.exit(#failures == 0 and 0 or 1)
