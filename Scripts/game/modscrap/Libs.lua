if __SE_Loaded then return end
__SE_Loaded = true
print("Loading Modscrap Libraries")

se = se or {}
sm.__SE = sm.__SE or {}

sm.__SE_Version = sm.__SE_Version or {}

print('══════════════════════════════════════════')
print('═══          Modscrap Modpack          ═══')
print('══════════════════════════════════════════')

local values = {} -- <<not directly accessible for other scripts
function sm.interactable.setValue(interactable, value)
    local currenttick = sm.game.getCurrentTick()
    values[interactable.id] = {
        {tick = currenttick, value = {value}},
        values[interactable.id] and (
            values[interactable.id][1] ~= nil and
            (values[interactable.id][1].tick < currenttick) and
            values[interactable.id][1].value or
			values[interactable.id][2]
        )
        or nil
    }
end
function sm.interactable.getValue(interactable, NOW)
	if sm.exists(interactable) and values[interactable.id] then
		if values[interactable.id][1] and (values[interactable.id][1].tick < sm.game.getCurrentTick() or NOW) then
			return values[interactable.id][1].value[1]
		elseif values[interactable.id][2] then
			return values[interactable.id][2][1]
		end
	end
	return nil
end

function sm.interactable.isNumberType(interactable)
	return (interactable:getType() == "scripted" and tostring(interactable:getShape().shapeUuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07"  --[[tickbutton]])
end

function getGlobal(shape, vec)
    return shape.right* vec.x + shape.at * vec.y + shape.up * vec.z
end
function getLocal(shape, vec)
    return sm.vec3.new(shape.right:dot(vec), shape.at:dot(vec), shape.up:dot(vec))
end

function math.round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end

function math.roundby( x, by)
	-- TODO

end

function table.size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i +1
	end
	return i
end

--HSV to RGB converter
function sm.color.toRGB( hsv )
	hsv.h = sm.util.clamp( hsv.h, -360000000, 360000000 )
	local C = hsv.v * hsv.s
	local X = C * ( 1 - math.abs( ((hsv.h / 60) % 2) - 1 ) )
	local M = hsv.v - C
	local H = math.floor( hsv.h % 360 / 60 )
	local out_rgb
	local rgb = {}
	rgb[0] = function( C, X ) return { r = C, g = X, b = 0 } end
	rgb[1] = function( C, X ) return { r = X, g = C, b = 0 } end
	rgb[2] = function( C, X ) return { r = 0, g = C, b = X } end
	rgb[3] = function( C, X ) return { r = 0, g = X, b = C } end
	rgb[4] = function( C, X ) return { r = X, g = 0, b = C } end
	rgb[5] = function( C, X ) return { r = C, g = 0, b = X } end
	out_rgb = rgb[H]( C, X )
	return sm.color.new( out_rgb.r + M, out_rgb.g + M, out_rgb.b + M)
end

if not sm.virtualButtons then sm.virtualButtons = {} end
function sm.virtualButtons.client_configure(parentInstance, virtualButtons)
	parentInstance.__virtualButtons = virtualButtons
end
function sm.virtualButtons.client_onInteract(parentInstance, x, y) -- x, y in blocks
	for _, virtualButton in pairs(parentInstance.__virtualButtons or {}) do
		if math.abs(x-virtualButton.x) < virtualButton.width and
			math.abs(y-virtualButton.y) < virtualButton.height then
			virtualButton:callback(parentInstance)
		end
	end
end
function sm.virtualButtons.client_getButtonPosition(parentInstance, x, y)
	for _, virtualButton in pairs(parentInstance.__virtualButtons or {}) do
		if math.abs(x-virtualButton.x) < virtualButton.width and
			math.abs(y-virtualButton.y) < virtualButton.height then
			return virtualButton.x, virtualButton.y
		end
	end
	return nil, nil
end
