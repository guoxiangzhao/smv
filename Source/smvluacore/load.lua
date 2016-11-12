
--- @module load
load  = {}
unload = {}

function load.slice(matchFunc)
    local nslices = 0
    for key,value in pairs(sliceinfo) do
        if (matchFunc(value)) then
            load.datafile(value.file)
            nslices = nslices + 1
        end
    end
    if (nslices > 0) then
        print(nslices .. " slice loaded")
        return 0
    end
    error("No matching slices were found.")
end

function load.vslice(matchFunc)
    for key,value in pairs(sliceinfo) do
        if (matchFunc(value)) then
            return load.vdatafile(value.file)
        end
    end
end

function load.namedslice(name)
    return load.slice(function(slice)
        return (slice.label == name)
    end)
end

function load.namedvslice(name)
    return load.vslice(function(slice)
        return (slice.label == name)
    end)
end

local function findCellDimension(mesh,axis,distance)
    local orig_plt
    local bar
    if (axis == X) then
        orig_plt = mesh.xplt_orig
        bar = mesh.ibar
    elseif (axis == Y) then
        orig_plt = mesh.yplt_orig
        bar = mesh.jbar
    elseif (axis == Z) then
        orig_plt = mesh.zplt_orig
        bar = mesh.kbar
    else
        error("invalid axis")
    end
    -- TODO: account for being slightly out
    for i=0,bar-2,1 do
        if (orig_plt[i] < distance and distance < orig_plt[i+1]) then
            return (orig_plt[i+1]-orig_plt[i])
        end
    end
    -- error("cell dimensions not found "  .. distance .. " (" .. orig_plt[0] .. "," .. orig_plt[bar-1] .. ")")
    return nil
end

function load.slice_std(slice_type, axis, distance)
    -- validate inputs
    assert(type(slice_type) == "string", "slice_type must be a string")
    assert(type(axis) == "number", "axis must be a number")
    assert(axis == 1 or axis == 2 or axis == 3, "axis must be 1, 2, or 3")
    assert(type(distance) == "number", "distance must be a number")
    -- load applicable slices
    return load.slice(function(slice)
            local meshnumber = slice.blocknumber
            local mesh = meshinfo[meshnumber]
            -- find the cell size at the specified location
            local cellWidth = findCellDimension(mesh, axis, distance)
            -- go a quarter cell in either direction
            return (cellWidth and slice.longlabel == slice_type
                and slice.idir == axis
                and (slice.position_orig > (distance-cellWidth*0.25)) and (slice.position_orig < (distance+cellWidth*0.25)))
        end)
end

-- TODO: load using path relative to simulation directory
function load.datafile(filename)
    local errorcode = loaddatafile(filename)
    if errorcode == 1 then
        error("load.datafile: could not load " .. filename)
    end
    assert(errorcode == 0, string.format("loaddatafile errorcode: %d\n",errorcode))
    return errorcode
end

function load.vdatafile(filename)
    local errorcode = loadvdatafile(filename)
    if errorcode == 1 then
        error("load.vdatafile: could not load " .. filename)
    end
    assert(errorcode == 0, string.format("loadvdatafile errorcode: %d\n",errorcode))
    return errorcode
end

function load.tour(name)
    local errorcode = loadtour(name)
    if errorcode == 1 then
        error("load.tour: could not load " .. name)
    end
    assert(errorcode == 0, string.format("loadtour errorcode: %d\n",errorcode))
    return errorcode
end

function unload.all()
    unloadall()
end

function unload.tour()
    unloadtour()
end
