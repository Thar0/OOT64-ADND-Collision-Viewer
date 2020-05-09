--[[
This file contains the core of the collision viewer
--]]

dofile("memory.lua")
dofile("gbi.F3DZEX.lua")


-- Toggle this to keep collision between scene changes, useful for finding void warps
local update_on_scene_change = true

local global_context = 0x0 -- http://wiki.cloudmodding.com/oot/Global_Context

local COLLISION_DLIST = 0x0;
local COLLISION_DLIST_END = COLLISION_DLIST;
local VERTEX_ARRAY = 0x0;
local VERTEX_ARRAY_END = VERTEX_ARRAY;

-- Arbitrary entry point ran every frame.
-- In this implementation, Link's x-coordinate is used
local draw_proc = 0x0

-- TODO refactor this to obtain game version
function initGame()
	print("Setting up")

	memory.usememorydomain("ROM")

	-- TODO

	global_context = 0x801C84A0
	memory.usememorydomain("RDRAM")

	draw_proc = linkPosXAddr()

    COLLISION_DLIST = 0x80500000
    COLLISION_DLIST_END = COLLISION_DLIST;
    VERTEX_ARRAY = 0x80400000
    VERTEX_ARRAY_END = VERTEX_ARRAY;

	print(string.format("gfxCtx: %x",graphicsContext()))
end

-- TODO: find addresses and merge into initGame()
function initMM()
    global_context = 0

    COLLISION_DLIST = 0 --TODO: either find or create fake heap node to create a buffer
    COLLISION_DLIST_END = COLLISION_DLIST;
    VERTEX_ARRAY = 0 --TODO: either find or create fake heap node to create a buffer
    VERTEX_ARRAY_END = VERTEX_ARRAY;
end

-- Builds display list portion for clearing the z-buffer instead of grabbing it from RAM
-- for version-independence
function buildClearZBufferDL(dl)
	dl = gDPPipeSync(dl)
	dl = gSPTexture(dl,0xFFFF,0xFFFF,0,0,0)
	dl = gDPSetCombineLERP(dl,0x00327FFF, 0xFFFFF638)
	dl = gDPSetOtherMode(dl,0x00182C10,0xC8112078)
	dl = gSPLoadGeometryMode(dl,0x00230405)
	return dl
end

-- Global Context scene id
function sceneId()
    return readByte(global_context + 0xA5)
end

-- Global Context fadeout timer
function fadeTimer()
    return readByte(global_context + 0x121D1)
end

-- Global Context pointer to Graphics Context
function graphicsContext()
    return readWord(global_context)
end

-- Global Context warp flag address
function warpAddr()
	return global_context + 0x11E15
end

-- Global Context pointer to scene
function scene()
    return readWord(global_context + 0x117A8)
end

-- Global Context pointer to static collision header
function staticCollisionHeader()
    return readWord(global_context + 0x7C0)
end

-- For the hook to render collision every frame, only works properly if 
-- link instance is loaded
function linkPosXAddr()
	return readWord(global_context + 0x1C44) + 0x24
end

function getCollisionHeader(coll_header_addr)
    local header = {}
    header["xmin"] = readShort(coll_header_addr)
    header["ymin"] = readShort(coll_header_addr + 0x02)
    header["zmin"] = readShort(coll_header_addr + 0x04)
    header["xmax"] = readShort(coll_header_addr + 0x06)
    header["ymax"] = readShort(coll_header_addr + 0x08)
    header["zmax"] = readShort(coll_header_addr + 0x0A)
    header["vertexNum"] = readHWord(coll_header_addr + 0x0C)
    header["verticies"] = readWord( coll_header_addr + 0x10)
    header["polyNum"] = readHWord(coll_header_addr + 0x14)
    header["polies"] = readWord(coll_header_addr + 0x18)
    header["polyTypes"] = readWord( coll_header_addr + 0x1C)
    return header
end

function getVertexArray(collisionHdrAddr)
    local header = getCollisionHeader(collisionHdrAddr)
    local vertex_ary = header["verticies"]
    local vertex_num = header["vertexNum"]
    local verticies = {}
    verticies[-1] = vertex_num - 1
    for i=0,vertex_num-1 do
        verticies[i] = {readShort(vertex_ary),readShort(vertex_ary + 0x2),readShort(vertex_ary + 0x4)}
        vertex_ary = vertex_ary + 0x6
    end
    return verticies
end

function getPolyArray(collisionHdrAddr)
    local header = getCollisionHeader(collisionHdrAddr)
    local poly_ary = header["polies"]
    local poly_num = header["polyNum"]
    local polies = {}
    polies[-1] = poly_num-1
    for i=0,poly_num-1 do
        polies[i] = {readShort(poly_ary),readShort(poly_ary + 0x2),
            readShort(poly_ary + 0x4),readShort(poly_ary + 0x6),
            readShort(poly_ary + 0x8),readShort(poly_ary + 0xA),
            readShort(poly_ary + 0xC),readShort(poly_ary + 0xE)}
        poly_ary = poly_ary + 0x10
    end
    return polies
end

function getTriangles(collisionHdrAddr)
    local verticies = getVertexArray(collisionHdrAddr)
    local polies = getPolyArray(collisionHdrAddr)
    local triangles = {}
    triangles[-1] = polies[-1]
    for i=0,polies[-1] do
        triangles[i] = {}
        triangles[i][1] = verticies[bit.band(polies[i][2], 0xFFF)]
        triangles[i][2] = verticies[bit.band(polies[i][3], 0xFFF)]
        triangles[i][3] = verticies[bit.band(polies[i][4], 0xFFF)]
    end
    return triangles
end

function hookPOLY_XLU_DISP(dlist)
    local polyAddr = graphicsContext() + 0x2D0
    local poly_app = readWord(polyAddr)
    writeWord(poly_app, 0xDE000000)
    writeWord(poly_app + 4, dlist)
    writeWord(polyAddr ,poly_app + 8)
end

function writeVertex(vaddr, vertex)
    writeShort(vaddr       , vertex[1])          -- x coord
    writeShort(vaddr + 0x02, vertex[2])          -- y coord
    writeShort(vaddr + 0x04, vertex[3])          -- z coord
    writeShort(vaddr + 0x06, 0)                  -- blank
    writeShort(vaddr + 0x08, 0)                  -- s coord
    writeShort(vaddr + 0x0A, 0)                  -- t coord
    writeByte (vaddr + 0x0C, math.random(256)-1) -- r
    writeByte (vaddr + 0x0D, math.random(256)-1) -- g
    writeByte (vaddr + 0x0E, math.random(256)-1) -- b
    writeByte (vaddr + 0x0F, 0)                  -- a

    return vaddr + 0x10
end

function drawTriangles(addrs, tries)
    local dl = addrs[1]
    local vaddr = addrs[2]

    math.randomseed(420)

    numTries = tries[-1]
    for i=1,numTries do
        if tries[i] ~= nil then
            vaddr = writeVertex(vaddr, tries[i][1])
            vaddr = writeVertex(vaddr, tries[i][2])
            vaddr = writeVertex(vaddr, tries[i][3])
            dl = gSPVertex(dl, vaddr, 6, 0)
            dl = gSP2Triangles(dl, 0, 1, 2, 0, 2, 1) --draw with both orientations to prevent backface culling
        end
    end

    return {dl, vaddr}
end

function generateDList()
    local dl = COLLISION_DLIST
    local vaddr = VERTEX_ARRAY

    --dl = gDPPipeSync(dl)
    --dl = gSPDisplayList(dl, clearZBufferDL) -- clear z-buffer by using premade d-list used by room change actors
    --dl = gDPPipeSync(dl)

	dl = buildClearZBufferDL(dl)

    dl = gSPMatrix(dl, vaddr , 0x03)
    for i=0,3 do
        for j = 0,3 do
            if(i==j) then
                writeShort(vaddr + 2*(4*i+j),1)
            else
                writeShort(vaddr + 2*(4*i+j),0)
            end
        end
    end
    for i=0,3 do
        for j = 0,3 do
            writeShort(vaddr + 0x20 + 2*(4*i+j),0)
        end
    end
    vaddr = vaddr + 0x40

    dl = gSPTexture(dl,0,0,0,0,0)
    dl = gSPGeometryMode(dl, 0xEF0000, 0x200005)
    dl = gDPSetCombineLERP_G_CC_SHADE_G_CC_SHADE(dl);

    local addrs = {dl, vaddr}

    print("finding tries")
    local tries = getTriangles(staticCollisionHeader())
    print("found tries")
    addrs = drawTriangles(addrs, tries)

    dl = addrs[1]
    vaddr = addrs[2]

    dl = gSPPopMatrixN(dl,0,1)
    dl = gSPEndDisplayList(dl)

    COLLISION_DLIST_END = dl
    print(string.format("END: %x",COLLISION_DLIST_END))
end



function hook()
    --local inputs = joypad.getimmediate()
    --print(inputs["Power"])
    --print(inputs["Reset"])
	
    gSPEndDisplayList(COLLISION_DLIST_END)
    hookPOLY_XLU_DISP(COLLISION_DLIST)
end

local drawHookID
local warpHookID
local drawing = false
local enabled = false
function enableCollision()
	print("Enabling collision")
	drawing = true
    enabled = true
    drawHookID = event.onmemorywrite(hook, draw_proc, "drawing")
	--drawHookID = event.oninputpoll(hook, "drawing")
	if update_on_scene_change then
	    warpHookID = event.onmemorywrite(onSceneChange, warpAddr(), "scene_change_check")
	end
end

function disableCollision()
    event.unregisterbyname("drawing")
    event.unregisterbyname("scene_change_check")
    event.unregisterbyname("loadstate_check")
    drawing = false
    enabled = false
    event.unregisterbyid(drawHookID)
    event.unregisterbyid(warpHookID)
end

function initCollision()
	memory.usememorydomain("RDRAM")
	getCollisionHeader(staticCollisionHeader())
	generateDList()
end

local alreadyEnabled = false
function onSceneChange()
    local warp = readByte(warpAddr())
    if warp == 0xEC and not alreadyEnabled then
		disableCollision()
		initCollision()
		enableCollision()
		alreadyEnabled = true
	elseif warp == 0x00 then
		alreadyEnabled = false
	end
end

initGame()
initCollision()
enableCollision()

while true do
	emu.frameadvance()
end
