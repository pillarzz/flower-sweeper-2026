-- define what prefab are valid to sweep
local validModPrefab = { "flower", "flower_evil", "succulent_plant", "succulent_potted", "cave_fern", "pottedfern", "marbleshrub", "deciduoustree", "carnivaldecor_lamp", "carnivaldecor_plant", "carnivaldecor_banner", "carnivaldecor_figure", "carnivaldecor_figure_season2", "singingshell_octave3", "singingshell_octave4", "singingshell_octave5", "cactus", "oasis_cactus", "hermitcrab_lightpost", "pirate_flag_pole", "dock_woodposts", "cavein_boulder", "vaultrelic_vase", "vaultrelic_planter", "berrybush", "berrybush2", "berrybush_juicy", "dug_berrybush", "dug_berrybush2", "dug_berrybush_juicy", "berrybush_waxed", "dug_berrybush_waxed" }

-- Flower variant groups for vase/planter sweeping (indexes into VASE_FLOWER_SWAPS)
local VASE_FLOWER_GROUPS = {
	{ 1, 2, 3, 4, 6, 10, 11, 12 }, -- petals (8 variants)
	{ 5, 7, 8 },                     -- lightbulb (3 variants)
	{ 13, 14 },                      -- forgetmelots (2 variants)
}

local function getVaseFlowerGroup(flowerid)
	for _, group in ipairs(VASE_FLOWER_GROUPS) do
		for _, id in ipairs(group) do
			if id == flowerid then
				return group
			end
		end
	end
	return nil
end

-- Variant counts per prefab (from game prefab definitions)
local VARIANT_COUNT = {
	flower = 10,
	flower_evil = 8,
	cave_fern = 10,
	pottedfern = 10,
	succulent_plant = 5,
	succulent_potted = 5,
}

-- Potted Plants (DST) 1311366056
if GetModConfigData("pottedPlantsMod") == 1 then
	table.insert(validModPrefab, "pottedbluemushroom")
	table.insert(validModPrefab, "pottedcactus")
	table.insert(validModPrefab, "pottedevilflower")
	table.insert(validModPrefab, "pottedflower")
	table.insert(validModPrefab, "pottedgreenmushroom")
	table.insert(validModPrefab, "pottedredmushroom")
	table.insert(validModPrefab, "pottedrose")
end

-- mod configuration prefabs
if GetModConfigData("changeEvergreens") == 1 then
	table.insert(validModPrefab, "evergreen")
	table.insert(validModPrefab, "evergreen_sparse")
end

if GetModConfigData("changeReeds") == 1 then
	table.insert(validModPrefab, "reeds")
	table.insert(validModPrefab, "grass")
end

if GetModConfigData("changeMushrooms") == 1 then
	table.insert(validModPrefab, "red_mushroom")
	table.insert(validModPrefab, "green_mushroom")
	table.insert(validModPrefab, "blue_mushroom")
	table.insert(validModPrefab, "mushtree_medium")
	table.insert(validModPrefab, "mushtree_small")
	table.insert(validModPrefab, "mushtree_tall")
end

AddPrefabPostInit("reskin_tool", function(inst)
	if inst.components ~= nil and inst.components.spellcaster ~= nil then
		-- save old functions to just extend them
		local oldSpellFunction = inst.components.spellcaster.spell
		local oldTestSpellFunction = inst.components.spellcaster.can_cast_fn

		local function puffEffect(tool, target, scale)
			--local fx = GLOBAL.SpawnPrefab("explode_reskin")

			local fx_prefab = "explode_reskin"
			if tool ~= nil then
				local skin_name = tool:GetSkinName()
				local skin_fx = skin_name ~= nil and GLOBAL.SKIN_FX_PREFAB[skin_name] or nil
				if skin_fx ~= nil and skin_fx[1] ~= nil then
					fx_prefab = skin_fx[1]
				end
			end

			local fx = GLOBAL.SpawnPrefab(fx_prefab)
			if fx ~= nil then
				fx.Transform:SetScale(scale, scale, scale)

				local fx_pos_x, fx_pos_y, fx_pos_z = target.Transform:GetWorldPosition()
				fx.Transform:SetPosition(fx_pos_x, fx_pos_y, fx_pos_z)
			end
		end

		local function inPrefabList(tbl, item)
			for key, value in pairs(tbl) do
				if value == item then return true end
			end
			return false
		end

		local function nextAnimVariant(currentAnimName, maxVariants)
			local num = math.floor(string.sub(currentAnimName, 2, 3))
			if num >= maxVariants then
				return "f1"
			end
			return "f" .. (num + 1)
		end

		local function setSucculentVariant(target, plantid)
			if plantid == 1 then
				target.AnimState:ClearOverrideSymbol("succulent")
			else
				target.AnimState:OverrideSymbol("succulent", "succulent_potted", "succulent" .. tostring(plantid))
			end
		end

		local function getOwnedSkins(userid, skinList)
			local owned = {}
			for _, skinName in ipairs(skinList) do
				if GLOBAL.TheInventory:CheckClientOwnership(userid, skinName) then
					table.insert(owned, skinName)
				end
			end
			return owned
		end

		local function can_cast_fn(doer, target, pos, tool)
			if target == nil or target.prefab == nil then
				return oldTestSpellFunction ~= nil and oldTestSpellFunction(doer, target, pos, tool) or false
			end

			local isModPrefabTwiggy = GetModConfigData("changeTwiggy") == 1 and (target.prefab == "twiggytree" or target.prefab == "sapling")

			if target.prefab == "vaultrelic_vase" or target.prefab == "vaultrelic_planter" then
				-- only allow sweeping if vase has a flower inside
				return target.components.vase ~= nil and target.components.vase:HasFlower()
			elseif target.prefab == "berrybush2_waxed" or target.prefab == "berrybush_juicy_waxed"
				or target.prefab == "dug_berrybush2_waxed" or target.prefab == "dug_berrybush_juicy_waxed" then
				-- waxed non-berrybush types have no skins, can't sweep
				return false
			elseif inPrefabList(validModPrefab, target.prefab) or isModPrefabTwiggy then
				-- it is a valid mod prefab
				return true
			else
				-- it is something default
				return oldTestSpellFunction ~= nil and oldTestSpellFunction(doer, target, pos, tool) or false
			end
		end

		local function spellCB(tool, target, pos, caster)
			local function replacePrefab(fromPrefab, toPrefab, size)
				puffEffect(tool, fromPrefab, size)

				-- add new tree at the old position
				local newPrefab = GLOBAL.SpawnPrefab(toPrefab)
				local fx_pos_x, fx_pos_y, fx_pos_z = fromPrefab.Transform:GetWorldPosition()

				newPrefab.Transform:SetPosition(fx_pos_x, fx_pos_y, fx_pos_z)

				-- remove old tree
				fromPrefab:Remove()

				return newPrefab
			end

			local function replaceBerryBush(fromPrefab, toPrefab)
				local pickable = fromPrefab.components.pickable
				local cycles_left = pickable and pickable.cycles_left
				local max_cycles = pickable and pickable.max_cycles
				local isBarren = pickable and cycles_left == 0
				local canBePicked = pickable and pickable.canbepicked
				local isWithered = fromPrefab.components.witherable ~= nil
					and type(fromPrefab.components.witherable.IsWithered) == "function"
					and fromPrefab.components.witherable:IsWithered()
				local regenTimeLeft = nil
				if pickable and pickable.targettime ~= nil then
					local now = GLOBAL.GetTime()
					if now then
						regenTimeLeft = math.max(0, pickable.targettime - now)
					end
				end

				local newPrefab = GLOBAL.SpawnPrefab(toPrefab)
				local fx_pos_x, fx_pos_y, fx_pos_z = fromPrefab.Transform:GetWorldPosition()
				newPrefab.Transform:SetPosition(fx_pos_x, fx_pos_y, fx_pos_z)
				fromPrefab:Remove()

				local newPickable = newPrefab.components.pickable
				if newPickable then
					newPickable.max_cycles = max_cycles
					newPickable.cycles_left = cycles_left

					if isBarren then
						newPickable:MakeBarren()
					elseif canBePicked then
						newPickable.canbepicked = true
						if newPickable.makefullfn then
							newPickable.makefullfn(newPrefab)
						end
					else
						newPickable.canbepicked = false
						if newPickable.makeemptyfn then
							newPickable.makeemptyfn(newPrefab)
						end
						if regenTimeLeft ~= nil then
							if newPickable.task ~= nil then
								newPickable.task:Cancel()
							end
							newPickable.task = newPrefab:DoTaskInTime(regenTimeLeft, function() newPickable:Regen() end)
							newPickable.targettime = GLOBAL.GetTime() + regenTimeLeft
						end
					end

					if isWithered and newPrefab.components.witherable
						and type(newPrefab.components.witherable.ForceWither) == "function" then
						newPrefab.components.witherable:ForceWither()
					end
				end

				return newPrefab
			end

			-- Potted Plants (DST) 1311366056
			local function changePottedPlants(prefix, maxVariation)
				local currentAnimName = target.animname
				local nextAnimName = prefix .. tostring(math.random(maxVariation))
				local prefixLength = string.len(prefix)

				if GetModConfigData("randomSelection") ~= 1 then
					if currentAnimName == prefix .. tostring(maxVariation) then
						-- start from beginning
						nextAnimName = prefix .. "1"
					else
						-- extract the number (string position after prefix), increment and add the following prefix number (+1)
						local minPosition = prefixLength + 1
						local maxPosition = prefixLength + 2
						nextAnimName = prefix .. (math.floor(string.sub(currentAnimName, minPosition, maxPosition) + 1))
					end
				end

				puffEffect(tool, target, 1)

				target.animname = nextAnimName
				target.AnimState:PlayAnimation(target.animname)
			end

			-- if there is no target, set empty string to compare
			local targetPrefabName = target ~= nil and target.prefab or ""
			-- print("targetPrefabName"..targetPrefabName)
			if targetPrefabName == "flower" then
				local maxVariants = VARIANT_COUNT.flower
				local ROSE_NAME = "rose"
				local ROSE_CHANCE = GetModConfigData("rosePercent")

				local nextAnimName
				local currentAnimName = target.animname

				if GetModConfigData("randomSelection") == 1 then
					nextAnimName = math.random() < ROSE_CHANCE and ROSE_NAME or ("f" .. tostring(math.random(maxVariants)))
				else
					if currentAnimName == ROSE_NAME then
						target:RemoveTag("thorny")
						nextAnimName = "f1"
					elseif currentAnimName == "f" .. maxVariants then
						nextAnimName = ROSE_NAME
					else
						nextAnimName = nextAnimVariant(currentAnimName, maxVariants)
					end
				end

				puffEffect(tool, target, 1)

				-- change flower skin as in the flower "setflowertype" function
				target.animname = nextAnimName
				target.AnimState:PlayAnimation(target.animname)

				if target.animname == ROSE_NAME then
					target:AddTag("thorny")
				end
			elseif targetPrefabName == "flower_evil" then
				local maxVariants = VARIANT_COUNT.flower_evil
				local nextAnimName

				if GetModConfigData("randomSelection") == 1 then
					nextAnimName = "f" .. tostring(math.random(maxVariants))
				else
					nextAnimName = nextAnimVariant(target.animname, maxVariants)
				end

				puffEffect(tool, target, 1)

				-- change flower skin as in the default function
				target.animname = nextAnimName
				target.AnimState:PlayAnimation(target.animname)
			elseif targetPrefabName == "succulent_plant" then
				local maxVariants = VARIANT_COUNT.succulent_plant
				if GetModConfigData("randomSelection") == 1 then
					target.plantid = math.random(maxVariants)
				else
					target.plantid = (target.plantid % maxVariants) + 1
				end

				puffEffect(tool, target, 1)

				if target.plantid == 1 then
					target.AnimState:ClearOverrideSymbol("Symbol_1")
				else
					target.AnimState:OverrideSymbol("Symbol_1", "succulent", "Symbol_" .. tostring(target.plantid))
				end
			elseif targetPrefabName == "succulent_potted" then
				local maxVariants = VARIANT_COUNT.succulent_potted
				local isSkinned = target:GetSkinBuild() ~= nil
				local ownsBearclaw = GLOBAL.TheInventory:CheckClientOwnership(caster.userid, "succulent_potted_bearclaw")

				if GetModConfigData("randomSelection") == 1 then
					local totalOptions = ownsBearclaw and (maxVariants + 1) or maxVariants
					local roll = math.random(totalOptions)
					puffEffect(tool, target, 1)
					if roll <= maxVariants then
						if isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
						target.plantid = roll
						setSucculentVariant(target, roll)
					else
						if not isSkinned then
							target.AnimState:ClearOverrideSymbol("succulent")
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, "succulent_potted_bearclaw", nil, caster.userid)
						end
					end
				else
					-- Sequential: Default 1→...→max → [Bearger Paw if owned] → Default 1
					puffEffect(tool, target, 1)
					if not isSkinned then
						if target.plantid == maxVariants and ownsBearclaw then
							target.AnimState:ClearOverrideSymbol("succulent")
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, "succulent_potted_bearclaw", nil, caster.userid)
						else
							target.plantid = (target.plantid % maxVariants) + 1
							setSucculentVariant(target, target.plantid)
						end
					else
						target.plantid = 1
						GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						target.AnimState:ClearOverrideSymbol("succulent")
					end
				end
			elseif targetPrefabName == "cave_fern" then
				local maxVariants = VARIANT_COUNT.cave_fern
				local nextAnimName
				if GetModConfigData("randomSelection") == 1 then
					nextAnimName = "f" .. tostring(math.random(maxVariants))
				else
					nextAnimName = nextAnimVariant(target.animname, maxVariants)
				end

				puffEffect(tool, target, 1)
				target.animname = nextAnimName
				target.AnimState:PlayAnimation(nextAnimName)
			elseif targetPrefabName == "pottedfern" then
				local maxVariants = VARIANT_COUNT.pottedfern
				local isSkinned = target:GetSkinBuild() ~= nil
				local allFernSkins = {
					"pottedfern_cotl", "pottedfern_cotl2", "pottedfern_cotl3",
					"pottedfern_rose", "pottedfern_rose2", "pottedfern_rose3"
				}
				local ownedSkins = getOwnedSkins(caster.userid, allFernSkins)

				if GetModConfigData("randomSelection") == 1 then
					local totalOptions = maxVariants + #ownedSkins
					local roll = math.random(totalOptions)
					puffEffect(tool, target, 1)
					if roll <= maxVariants then
						if isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
						target.animname = "f" .. tostring(roll)
						target.AnimState:PlayAnimation(target.animname)
					else
						GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[roll - maxVariants], nil, caster.userid)
						target.AnimState:PlayAnimation("c")
					end
				else
					-- Sequential: f1→...→fN → [owned skins] → f1
					puffEffect(tool, target, 1)
					if not isSkinned then
						if target.animname == "f" .. maxVariants and #ownedSkins > 0 then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[1], nil, caster.userid)
							target.AnimState:PlayAnimation("c")
						else
							target.animname = nextAnimVariant(target.animname, maxVariants)
							target.AnimState:PlayAnimation(target.animname)
						end
					else
						local currentIndex = nil
						for i, s in ipairs(ownedSkins) do
							if s == target.skinname then
								currentIndex = i
								break
							end
						end

						if currentIndex ~= nil and currentIndex < #ownedSkins then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[currentIndex + 1], nil, caster.userid)
							target.AnimState:PlayAnimation("c")
						else
							target.animname = "f1"
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
							target.AnimState:PlayAnimation("f1")
						end
					end
				end
			elseif targetPrefabName == "berrybush" or targetPrefabName == "berrybush2" or targetPrefabName == "berrybush_juicy" then
				local allBerrySkins = {
					"berrybush_cawnival", "berrybush_mystical", "berrybush_swamp",
				}
				local isSkinned = target:GetSkinBuild() ~= nil
				local ownedSkins = getOwnedSkins(caster.userid, allBerrySkins)
				local changeTypes = true

				-- Build the full cycle: for berrybush, default + owned skins, then optionally other types
				-- For berrybush2/berrybush_juicy (no skins), only type switching matters
				if targetPrefabName == "berrybush" then
					if GetModConfigData("randomSelection") == 1 then
						local totalOptions = 1 + #ownedSkins + (changeTypes and 2 or 0)
						local roll = math.random(totalOptions)
						puffEffect(tool, target, 1.4)
						if roll == 1 then
							-- default skin
							if isSkinned then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
							end
						elseif roll <= 1 + #ownedSkins then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[roll - 1], nil, caster.userid)
						else
							-- type switch
							local typePrefab = roll == 1 + #ownedSkins + 1 and "berrybush2" or "berrybush_juicy"
							replaceBerryBush(target, typePrefab)
						end
					else
						-- Sequential: default → owned skins → [berrybush2 → berrybush_juicy if enabled] → default
						puffEffect(tool, target, 1.4)
						if not isSkinned then
							if #ownedSkins > 0 then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[1], nil, caster.userid)
							elseif changeTypes then
								replaceBerryBush(target, "berrybush2")
							end
						else
							local currentIndex = nil
							for i, s in ipairs(ownedSkins) do
								if s == target.skinname then
									currentIndex = i
									break
								end
							end

							if currentIndex ~= nil and currentIndex < #ownedSkins then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[currentIndex + 1], nil, caster.userid)
							elseif changeTypes then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
								replaceBerryBush(target, "berrybush2")
							else
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
							end
						end
					end
				else
					-- berrybush2 or berrybush_juicy: no skins, only type switching
					if changeTypes then
						local nextType
						if targetPrefabName == "berrybush2" then
							nextType = "berrybush_juicy"
						else
							nextType = "berrybush"
						end

						puffEffect(tool, target, 1.4)
						replaceBerryBush(target, nextType)
					else
						puffEffect(tool, target, 1.4)
					end
				end
			elseif targetPrefabName == "dug_berrybush" or targetPrefabName == "dug_berrybush2" or targetPrefabName == "dug_berrybush_juicy" then
				local allDugSkins = {
					"dug_berrybush_cawnival", "dug_berrybush_mystical", "dug_berrybush_swamp",
				}
				local isSkinned = target:GetSkinBuild() ~= nil
				local ownedSkins = getOwnedSkins(caster.userid, allDugSkins)
				local changeTypes = true

				if targetPrefabName == "dug_berrybush" then
					if GetModConfigData("randomSelection") == 1 then
						local totalOptions = 1 + #ownedSkins + (changeTypes and 2 or 0)
						local roll = math.random(totalOptions)
						puffEffect(tool, target, 1)
						if roll == 1 then
							if isSkinned then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
							end
						elseif roll <= 1 + #ownedSkins then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[roll - 1], nil, caster.userid)
						else
							local typePrefab = roll == 1 + #ownedSkins + 1 and "dug_berrybush2" or "dug_berrybush_juicy"
							replacePrefab(target, typePrefab, 1)
						end
					else
						puffEffect(tool, target, 1)
						if not isSkinned then
							if #ownedSkins > 0 then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[1], nil, caster.userid)
							elseif changeTypes then
								replacePrefab(target, "dug_berrybush2", 1)
							end
						else
							local currentIndex = nil
							for i, s in ipairs(ownedSkins) do
								if s == target.skinname then
									currentIndex = i
									break
								end
							end

							if currentIndex ~= nil and currentIndex < #ownedSkins then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[currentIndex + 1], nil, caster.userid)
							elseif changeTypes then
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
								replacePrefab(target, "dug_berrybush2", 1)
							else
								GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
							end
						end
					end
				else
					-- dug_berrybush2 or dug_berrybush_juicy: no skins, only type switching
					if changeTypes then
						local nextType
						if targetPrefabName == "dug_berrybush2" then
							nextType = "dug_berrybush_juicy"
						else
							nextType = "dug_berrybush"
						end
						replacePrefab(target, nextType, 1)
					else
						puffEffect(tool, target, 1)
					end
				end
			elseif targetPrefabName == "berrybush_waxed" or targetPrefabName == "dug_berrybush_waxed" then
				local isPlanted = targetPrefabName == "berrybush_waxed"
				local allWaxedSkins
				if isPlanted then
					allWaxedSkins = { "berrybush_waxed_cawnival", "berrybush_waxed_mystical", "berrybush_waxed_swamp" }
				else
					allWaxedSkins = { "dug_berrybush_waxed_cawnival", "dug_berrybush_waxed_mystical", "dug_berrybush_waxed_swamp" }
				end
				local isSkinned = target:GetSkinBuild() ~= nil
				local ownedSkins = getOwnedSkins(caster.userid, allWaxedSkins)

				if #ownedSkins == 0 then
					puffEffect(tool, target, 1.4)
				elseif GetModConfigData("randomSelection") == 1 then
					local totalOptions = 1 + #ownedSkins
					local roll = math.random(totalOptions)
					puffEffect(tool, target, 1.4)
					if roll == 1 then
						if isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
					else
						GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[roll - 1], nil, caster.userid)
					end
				else
					puffEffect(tool, target, 1.4)
					if not isSkinned then
						GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[1], nil, caster.userid)
					else
						local currentIndex = nil
						for i, s in ipairs(ownedSkins) do
							if s == target.skinname then
								currentIndex = i
								break
							end
						end

						if currentIndex ~= nil and currentIndex < #ownedSkins then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[currentIndex + 1], nil, caster.userid)
						else
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
					end
				end
			elseif targetPrefabName == "marbleshrub" then
				puffEffect(tool, target, 1.8)

				local currentShapeNumber = target.shapenumber
				-- returns 1, 2 or 3
				local newShapeNumber = (currentShapeNumber + 1) < 4 and currentShapeNumber + 1 or 1

				-- randominze the color again
				local color = .5 + math.random() * .5
				target.AnimState:SetMultColour(color, color, color, 1)

				if newShapeNumber == 1 then
					target.AnimState:ClearOverrideSymbol("marbleshrub_top1")
				else
					target.AnimState:OverrideSymbol("marbleshrub_top1", "marbleshrub_build", "marbleshrub_top" .. newShapeNumber)
				end

				target.MiniMapEntity:SetIcon("marbleshrub" .. newShapeNumber .. ".png")
				target.shapenumber = newShapeNumber
			elseif targetPrefabName == "evergreen" or targetPrefabName == "evergreen_sparse" then
				if not target:HasTag("stump") then
					local newPrefabName = targetPrefabName == "evergreen_sparse" and "evergreen" or "evergreen_sparse"
					local stage = 0

					if target.components ~= nil and target.components.growable then
						stage = target.components.growable.stage
					end

					local newPrefab = replacePrefab(target, newPrefabName, 1.8)
					newPrefab.components.growable.stage = stage
				end
			elseif targetPrefabName == "deciduoustree" then
				puffEffect(tool, target, 1.8)
				if target.leaf_state == "colorful" then
					target.build = ({ "red", "orange", "yellow" })[math.random(3)]
					target.AnimState:SetMultColour(1, 1, 1, 1)
					target.AnimState:OverrideSymbol("swap_leaves", "tree_leaf_" .. target.build .. "_build", "swap_leaves")
				else
					target.color = .5 + math.random() * .5
					target.AnimState:SetMultColour(target.color, target.color, target.color, 1)
				end
			elseif targetPrefabName == "carnivaldecor_lamp" then
				local NUM_SHAPES = 6
				puffEffect(tool, target, 1.4)

				local currentShape = target.shape
				target.shape = math.random(NUM_SHAPES)

				if GetModConfigData("randomSelection") ~= 1 then
					if currentShape >= NUM_SHAPES then
						-- start from beginning
						target.shape = 1
					else
						target.shape = currentShape + 1
					end
				end

				target.AnimState:PlayAnimation("idle" .. target.shape .. "_off")

				target.Light:Enable(false)

				if target.components.activatable ~= nil then
					target.components.activatable.inactive = true
				end

				target.turnofftask = nil
			elseif targetPrefabName == "carnivaldecor_plant" then
				puffEffect(tool, target, 1.4)

				local currentShape = target.shape
				target.shape = math.random(3)

				if GetModConfigData("randomSelection") ~= 1 then
					if currentShape == 3 then
						-- start from beginning
						target.shape = 1
					else
						target.shape = currentShape + 1
					end
				end

				target.AnimState:PlayAnimation("idle_" .. tostring(target.shape), true)
			elseif targetPrefabName == "carnivaldecor_figure" or targetPrefabName == "carnivaldecor_figure_season2" then

				-- defaults for carnivaldecor_figure (season 1)
				local shape_rarity = {
					s1 = "rare",
					s2 = "uncommon",
					s3 = "uncommon",
					s4 = "common",
					s5 = "common",
					s6 = "common",
					s7 = "uncommon",
					s8 = "common",
					s9 = "common",
					s10 = "common",
					s11 = "common",
					s12 = "common",
				}

				if targetPrefabName == "carnivaldecor_figure_season2" then
					-- season 2
					shape_rarity = {
						s1 = "rare",
						s2 = "uncommon",
						s3 = "uncommon",
						s4 = "common",
						s5 = "common",
						s6 = "common",
						s7 = "uncommon",
						s8 = "common",
						s9 = "common",
						s10 = "common",
						s11 = "common",
						s12 = "common",
					}
				end

				local rarity_decor_vale_map = {
					rare     = 20,
					uncommon = 16,
					common   = 12,
				}

				puffEffect(tool, target, 1.2)

				local defaultShape = "s" .. 0
				local currentShape = target.shape or defaultShape
				local newShape = "s" .. math.random(12)

				if GetModConfigData("randomSelection") ~= 1 then
					if currentShape == "s12" then
						-- start from beginning
						newShape = "s" .. 1
					else
						-- extract the number (string position after prefix), increment and add the following prefix number (+1)
						local minPosition = 2
						local maxPosition = 3
						newShape = 's' .. (math.floor(string.sub(currentShape, minPosition, maxPosition) + 1))
					end
				end

				if target.shape ~= nil then
					target:RemoveTag("blindbox_" .. tostring(shape_rarity[target.shape]))
				end

				target.shape = newShape
				target.components.carnivaldecor.value = rarity_decor_vale_map[shape_rarity[newShape]]
				target:AddTag("blindbox_" .. tostring(shape_rarity[newShape]))

				target.AnimState:PlayAnimation(tostring(newShape))
			elseif targetPrefabName == "singingshell_octave3" or targetPrefabName == "singingshell_octave4" or targetPrefabName == "singingshell_octave5" then
				puffEffect(tool, target, 1)

				-- eg. "ocatave3"
				local octave_str = targetPrefabName:sub(-7)
				local currentVariation = target._variation

				target._variation = math.random(3)
				if GetModConfigData("randomSelection") ~= 1 then
					if currentVariation == 3 then
						-- start from beginning
						target._variation = 1
					else
						target._variation = currentVariation + 1
					end
				end
				target.AnimState:OverrideSymbol("shell_placeholder", "singingshell", octave_str .. "_" .. target._variation)
				target.components.inventoryitem:ChangeImageName("singingshell_" .. octave_str .. "_" .. target._variation)
			elseif targetPrefabName == "red_mushroom" or targetPrefabName == "green_mushroom" or targetPrefabName == "blue_mushroom" then

				local prefab = "mushtree_medium" -- red
				if targetPrefabName == "green_mushroom" then prefab = "mushtree_small" end
				if targetPrefabName == "blue_mushroom" then prefab = "mushtree_tall" end

				replacePrefab(target, prefab, 1.6)
			elseif targetPrefabName == "mushtree_medium" or targetPrefabName == "mushtree_small" or targetPrefabName == "mushtree_tall" then

				local prefab = "red_mushroom"
				if targetPrefabName == "mushtree_small" then prefab = "green_mushroom" end
				if targetPrefabName == "mushtree_tall" then prefab = "blue_mushroom" end

				replacePrefab(target, prefab, 1)
			elseif targetPrefabName == "pottedbluemushroom" then
				changePottedPlants("bm", 3)
			elseif targetPrefabName == "pottedcactus" then
				changePottedPlants("c", 5)
			elseif targetPrefabName == "pottedevilflower" then
				changePottedPlants("ef", 8)
			elseif targetPrefabName == "pottedflower" then
				changePottedPlants("pf", 9)
			elseif targetPrefabName == "pottedgreenmushroom" then
				changePottedPlants("gm", 3)
			elseif targetPrefabName == "pottedredmushroom" then
				changePottedPlants("rm", 3)
			elseif targetPrefabName == "pottedrose" then
				changePottedPlants("pr", 7)
			elseif targetPrefabName == "carnivaldecor_banner" then
				local NUM_SHAPES = 3
				puffEffect(tool, target, 1.4)

				local currentShape = target.shape
				target.shape = math.random(NUM_SHAPES)

				if GetModConfigData("randomSelection") ~= 1 then
					if currentShape >= NUM_SHAPES then
						target.shape = 1
					else
						target.shape = currentShape + 1
					end
				end

				target.AnimState:PlayAnimation("idle_" .. tostring(target.shape), true)
			elseif targetPrefabName == "hermitcrab_lightpost" then
				local CORAL_COLORS = {
					{ 189/255, 89/255, 80/255 },
					{ 96/255, 139/255, 189/255 },
					{ 180/255, 157/255, 78/255 },
					{ 138/255, 91/255, 160/255 },
					{ 102/255, 136/255, 95/255 },
				}
				local maxColors = #CORAL_COLORS
				local isSkinned = target:GetSkinBuild() ~= nil
				local ownsYule = GLOBAL.TheInventory:CheckClientOwnership(caster.userid, "hermitcrab_lightpost_yule")

				if GetModConfigData("randomSelection") == 1 then
					local totalOptions = ownsYule and (maxColors + 1) or maxColors
					local roll = math.random(totalOptions)
					puffEffect(tool, target, 1.4)
					if roll <= maxColors then
						if isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
						target.colors_id = roll
						local colors = CORAL_COLORS[roll]
						target.AnimState:SetSymbolMultColour("coral", colors[1], colors[2], colors[3], 1)
					else
						if not isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, "hermitcrab_lightpost_yule", nil, caster.userid)
						end
					end
				else
					puffEffect(tool, target, 1.4)
					if not isSkinned then
						if target.colors_id == maxColors and ownsYule then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, "hermitcrab_lightpost_yule", nil, caster.userid)
						else
							target.colors_id = (target.colors_id % maxColors) + 1
							local colors = CORAL_COLORS[target.colors_id]
							target.AnimState:SetSymbolMultColour("coral", colors[1], colors[2], colors[3], 1)
						end
					else
						target.colors_id = 1
						GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						local colors = CORAL_COLORS[1]
						target.AnimState:SetSymbolMultColour("coral", colors[1], colors[2], colors[3], 1)
					end
				end
			elseif targetPrefabName == "pirate_flag_pole" then
				local NUM_FLAGS = 4
				puffEffect(tool, target, 1.4)

				local currentNum = GLOBAL.tonumber(target.flag_number) or 1

				local newNum
				if GetModConfigData("randomSelection") == 1 then
					newNum = math.random(NUM_FLAGS)
				else
					newNum = (currentNum % NUM_FLAGS) + 1
				end

				local flag_number = "0" .. tostring(newNum)
				target.flag_number = flag_number
				target.AnimState:OverrideSymbol("flag_01", "pirate_flag_pole", "flag_" .. flag_number)
			elseif targetPrefabName == "dock_woodposts" then
				local maxVariants = 3
				local isSkinned = target:GetSkinBuild() ~= nil
				local allDockSkins = {
					"dock_woodposts_carved", "dock_woodposts_carved2", "dock_woodposts_carved3",
					"dock_woodposts_decorated", "dock_woodposts_decorated2", "dock_woodposts_decorated3",
					"dock_woodposts_kitchen", "dock_woodposts_kitchen2", "dock_woodposts_kitchen3",
				}
				local ownedSkins = getOwnedSkins(caster.userid, allDockSkins)

				if GetModConfigData("randomSelection") == 1 then
					local totalOptions = maxVariants + #ownedSkins
					local roll = math.random(totalOptions)
					puffEffect(tool, target, 1.2)
					if roll <= maxVariants then
						if isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
						target._post_id = tostring(roll)
						target.AnimState:PlayAnimation("idle" .. target._post_id)
					else
						if not isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[roll - maxVariants], nil, caster.userid)
						else
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[roll - maxVariants], nil, caster.userid)
						end
					end
				else
					puffEffect(tool, target, 1.2)
					if not isSkinned then
						local currentId = GLOBAL.tonumber(target._post_id) or 1
						if currentId == maxVariants and #ownedSkins > 0 then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[1], nil, caster.userid)
						else
							target._post_id = tostring((currentId % maxVariants) + 1)
							target.AnimState:PlayAnimation("idle" .. target._post_id)
						end
					else
						local currentIndex = nil
						for i, s in ipairs(ownedSkins) do
							if s == target.skinname then
								currentIndex = i
								break
							end
						end

						if currentIndex ~= nil and currentIndex < #ownedSkins then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, ownedSkins[currentIndex + 1], nil, caster.userid)
						else
							target._post_id = "1"
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
							target.AnimState:PlayAnimation("idle1")
						end
					end
				end
			elseif targetPrefabName == "cavein_boulder" then
				local NUM_VARIATIONS = 8
				local isSkinned = target:GetSkinBuild() ~= nil
				local ownsKettlebell = GLOBAL.TheInventory:CheckClientOwnership(caster.userid, "cavein_boulder_kettlebell")

				if GetModConfigData("randomSelection") == 1 then
					local totalOptions = ownsKettlebell and (NUM_VARIATIONS + 1) or NUM_VARIATIONS
					local roll = math.random(totalOptions)
					puffEffect(tool, target, 1.4)
					if roll <= NUM_VARIATIONS then
						if isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
						end
						local variation = roll > 1 and roll or nil
						target.variation = variation
						if variation ~= nil then
							target.AnimState:OverrideSymbol("swap_boulder", "swap_cavein_boulder", "swap_boulder" .. tostring(variation))
						else
							target.AnimState:ClearOverrideSymbol("swap_boulder")
						end
					else
						if not isSkinned then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, "cavein_boulder_kettlebell", nil, caster.userid)
						end
					end
				else
					puffEffect(tool, target, 1.4)
					if not isSkinned then
						local currentVar = target.variation or 1
						if currentVar >= NUM_VARIATIONS and ownsKettlebell then
							GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, "cavein_boulder_kettlebell", nil, caster.userid)
						else
							local nextVar = (currentVar % NUM_VARIATIONS) + 1
							local variation = nextVar > 1 and nextVar or nil
							target.variation = variation
							if variation ~= nil then
								target.AnimState:OverrideSymbol("swap_boulder", "swap_cavein_boulder", "swap_boulder" .. tostring(variation))
							else
								target.AnimState:ClearOverrideSymbol("swap_boulder")
							end
						end
					else
						target.variation = nil
						target.AnimState:ClearOverrideSymbol("swap_boulder")
						GLOBAL.TheSim:ReskinEntity(target.GUID, target.skinname, nil, nil, caster.userid)
					end
				end
			elseif targetPrefabName == "vaultrelic_vase" or targetPrefabName == "vaultrelic_planter" then
				local vase = target.components.vase
				if vase ~= nil and vase.flowerid ~= nil then
					local group = getVaseFlowerGroup(vase.flowerid)
					if group ~= nil and #group > 1 then
						local currentIndex = 1
						for i, id in ipairs(group) do
							if id == vase.flowerid then
								currentIndex = i
								break
							end
						end

						local nextIndex
						if GetModConfigData("randomSelection") == 1 then
							nextIndex = math.random(#group)
						else
							nextIndex = (currentIndex % #group) + 1
						end

						local newFlowerid = group[nextIndex]
						vase.flowerid = newFlowerid
						local fresh = vase.fresh
						target.AnimState:OverrideSymbol("swap_flower", "swap_flower", string.format("f%d%s", newFlowerid, fresh and "" or "_wilt"))
					end
					puffEffect(tool, target, 1)
				end
			elseif targetPrefabName == "reeds" then
				replacePrefab(target, "grass", 1.4)
			elseif targetPrefabName == "grass" then
				replacePrefab(target, "reeds", 1.4)
			elseif targetPrefabName == "cactus" then
				replacePrefab(target, "oasis_cactus", 1.4)
			elseif targetPrefabName == "oasis_cactus" then
				replacePrefab(target, "cactus", 1.4)
			elseif targetPrefabName == "sapling" then
				replacePrefab(target, "twiggytree", 1.4)
			elseif targetPrefabName == "twiggytree" then
				replacePrefab(target, "sapling", 1.8)
			else
				-- do default stuff
				if oldSpellFunction ~= nil then
					oldSpellFunction(tool, target, pos, caster)
				end
			end
		end

		inst.components.spellcaster:SetSpellFn(spellCB)
		inst.components.spellcaster:SetCanCastFn(can_cast_fn)
	end

end)
