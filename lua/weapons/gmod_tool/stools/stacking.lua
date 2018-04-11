-- Copyright (c) 2015 luckyxxl
--
-- This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
--
--    1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
--
--    2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
--
--    3. This notice may not be removed or altered from any source distribution.
--

TOOL.Category = "Construction"
TOOL.Name = "#tool.stacking.name"

TOOL.ClientConVar["class"] = "prop_physics"
TOOL.ClientConVar["model"] = "models/props_borealis/bluebarrel001.mdl"
TOOL.ClientConVar["mode"] = 1
TOOL.ClientConVar["height"] = 4
TOOL.ClientConVar["spawn_asleep"] = 0

if CLIENT then
	language.Add("tool.stacking.name", "Stacking Tool")
	language.Add("tool.stacking.desc", "Stack objects beautifully")
	language.Add("tool.stacking.0", "Left-Click to stack objects, Reload to select object")
	language.Add("tool.stacking.mode", "Mode")
	language.Add("tool.stacking.mode.pile", "Pile")
	language.Add("tool.stacking.mode.pyramid", "Pyramid")
	language.Add("tool.stacking.mode.3dpyramid", "3D Pyramid")
	language.Add("tool.stacking.mode.wall", "Wall")
	language.Add("tool.stacking.mode.cube", "Cube")
	language.Add("tool.stacking.mode.box", "Box")
	language.Add("tool.stacking.mode.stair", "Stair")
	language.Add("tool.stacking.mode.plane", "Plane")
	language.Add("tool.stacking.height", "Height")
	language.Add("tool.stacking.spawn_asleep", "Spawn objects asleep")
	language.Add("Undone_stacking", "Undone Stacking")
end

local function spawn_grid_pile(spawn, height)
	for y=0, height-1 do
		spawn(Vector(0, 0, y))
	end
end

local function spawn_grid_pyramid(spawn, height)
	for level=0, height-1 do
		local num_on_level = height - level
		for i=0, num_on_level-1 do
			spawn(Vector(i - (num_on_level-1)/2, 0, level))
		end
	end
end

local function spawn_grid_3dpyramid(spawn, height)
	for level=0, height-1 do
		local sidelength = height - level
		for i=0, sidelength-1 do for j=0, sidelength-1 do
			spawn(Vector(i - (sidelength-1)/2, j - (sidelength-1)/2, level))
		end end
	end
end

local function spawn_grid_wall(spawn, height)
	for y=0, height-1 do for x=0, height-1 do
		spawn(Vector(x - (height-1)/2, 0, y))
	end end
end

local function spawn_grid_cube(spawn, height)
	for z=0, height-1 do for y=0, height-1 do for x=0, height-1 do
		spawn(Vector(x - (height-1)/2, y - (height-1)/2, z))
	end end end
end

local function spawn_grid_box(spawn, height)
	for z=0, height-1 do for y=0, height-1 do for x=0, height-1 do
		if y==0 or y==height-1 or x==0 or x==height-1 then
			spawn(Vector(x - (height-1)/2, y - (height-1)/2, z))
		end
	end end end
end

local function spawn_grid_stair(spawn, height)
	for x=0, height-1 do for y=0, x do
		spawn(Vector(x-(height-1), 0, y))
	end end
end

local function spawn_grid_plane(spawn, height)
	for x=0, height-1 do for y=0, height-1 do
		spawn(Vector(x-(height-1)/2, y-(height-1)/2, 0))
	end end
end

local modes = {
	{ "#tool.stacking.mode.pile", spawn_grid_pile },
	{ "#tool.stacking.mode.pyramid", spawn_grid_pyramid },
	{ "#tool.stacking.mode.3dpyramid", spawn_grid_3dpyramid },
	{ "#tool.stacking.mode.wall", spawn_grid_wall },
	{ "#tool.stacking.mode.cube", spawn_grid_cube },
	{ "#tool.stacking.mode.box", spawn_grid_box },
	{ "#tool.stacking.mode.stair", spawn_grid_stair },
	{ "#tool.stacking.mode.plane", spawn_grid_plane },
}

for i, mode in ipairs(modes) do
	list.Set("Modes", mode[1], { stacking_mode = i })
end

function TOOL:LeftClick(trace)
	if not trace.Hit then return false end

	if CLIENT then return true end

	local class = self:GetClientInfo("class")
	local model = self:GetClientInfo("model")
	local mode = self:GetClientNumber("mode")
	local height = self:GetClientNumber("height")
	local spawn_asleep = self:GetClientNumber("spawn_asleep")

	local up = vector_up
	local right = up:Cross(trace.StartPos - trace.HitPos):GetNormalized()
	local back = up:Cross(right):GetNormalized()

	undo.Create("stacking")
	undo.SetPlayer(self:GetOwner())

	local spawn_grid = function(vec)
		local entity = ents.Create(class)

		entity:SetModel(model)

		local obbmin, obbmax = entity:GetModelBounds()
		local obbdiff = obbmax - obbmin

		local pos = trace.HitPos + Vector(0, 0, -obbmin.Z) +
			(vec.x * right * obbdiff.x + vec.y * back * obbdiff.y + vec.z * up * obbdiff.z)

		entity:SetPos(pos)
		entity:SetAngles(right:Angle())
		entity:Spawn()

		if spawn_asleep ~= 0 then
			local physobj = entity:GetPhysicsObject()
			physobj:Sleep()
		end

		undo.AddEntity(entity)
	end

	modes[mode][2](spawn_grid, height)

	undo.Finish()

	return true
end

function TOOL:Reload(trace)
	if not IsValid(trace.Entity) then return false end

	RunConsoleCommand("stacking_class", trace.Entity:GetClass())
	RunConsoleCommand("stacking_model", trace.Entity:GetModel())

	return true
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", { Description = "#tool.stacking.desc" })
	CPanel:AddControl("ComboBox", { Label = "#tool.stacking.mode", Options = list.Get("Modes") })
	CPanel:AddControl("Slider", { Label = "#tool.stacking.height", Type = "Integer", Command = "stacking_height", Min = 1, Max = 10 })
	CPanel:AddControl("Checkbox", { Label = "#tool.stacking.spawn_asleep", Command = "stacking_spawn_asleep" })
end
