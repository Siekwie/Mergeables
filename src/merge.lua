local util = require("src.util")

local Merge = {}

-- Find a merge target for a dragged animal
function Merge.findTarget(draggedAnimal, animals)
    local bestDist = draggedAnimal.size * 0.8
    local best = nil
    for _, other in ipairs(animals) do
        if draggedAnimal:canMergeWith(other) and other.state ~= "dragged" then
            local d = util.distance(draggedAnimal.x, draggedAnimal.y, other.x, other.y)
            if d < bestDist then
                bestDist = d
                best = other
            end
        end
    end
    return best
end

-- Execute a merge: remove source, upgrade target
function Merge.execute(source, target, animals, particles)
    -- Remove source from animals list
    for i, a in ipairs(animals) do
        if a == source then
            table.remove(animals, i)
            break
        end
    end

    -- Upgrade target tier
    target.tier = target.tier + 1
    target:triggerMergeAnimation()

    -- Particles
    if particles then
        particles:spawnMergeEffect(target.x, target.y)
    end

    return target
end

-- Auto-merge: merge pairs of same type+tier when 3+ exist
function Merge.autoMerge(animals, particles)
    local merged = false
    -- Count by type+tier
    local counts = {}
    for _, a in ipairs(animals) do
        if a.state ~= "dragged" then
            local key = a.type .. "_" .. a.tier
            counts[key] = (counts[key] or 0) + 1
        end
    end

    -- Merge pairs where count >= 3
    for key, count in pairs(counts) do
        if count >= 3 then
            local parts = {}
            for part in key:gmatch("[^_]+") do
                table.insert(parts, part)
            end
            local aType = parts[1]
            local aTier = tonumber(parts[2])

            -- Find two animals of this type+tier
            local first, second
            for _, a in ipairs(animals) do
                if a.type == aType and a.tier == aTier and a.state ~= "dragged" then
                    if not first then
                        first = a
                    elseif not second then
                        second = a
                        break
                    end
                end
            end

            if first and second and first:canMergeWith(second) then
                Merge.execute(first, second, animals, particles)
                merged = true
                break  -- Only one auto-merge per frame to prevent cascading issues
            end
        end
    end
    return merged
end

return Merge
