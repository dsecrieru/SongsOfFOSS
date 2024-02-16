local ffi = require("ffi")
local kernel32 = require("utils.win32api")

ffi.cdef[[
int LIBSOTE_Init(char* err_msg, const char* log_file);
int LIBSOTE_StartTask(char* err_msg, int task, unsigned int num, char* fname);
int LIBSOTE_WaitEndTask(char* err_msg);
int LIBSOTE_SetVar(char* err_msg, int dlen, unsigned int* desc, void* val);
int LIBSOTE_GetVar(char* err_msg, int dlen, unsigned int* desc, void* val);
int LIBSOTE_IsRunning();
int LIBSOTE_GetLoadMessage(char* err_msg, char* msg);
]]

local sote_params = {
    {name = "randomSeed",                       index =  0, ctype = "unsigned int",   value = 90638},
    {name = "WorldSize",                        index =  1, ctype = "unsigned short", value = 183},
    {name = "SuperOceans",                      index =  2, ctype = "short",          value = 1},
    {name = "SuperContinents",                  index =  3, ctype = "short",          value = 1},
    {name = "MajorPlates",                      index =  4, ctype = "short",          value = 7},
    {name = "MinorPlates",                      index =  5, ctype = "short",          value = 12},
    {name = "MajorHotspots",                    index =  6, ctype = "short",          value = 9},
    {name = "ModerateHotspots",                 index =  7, ctype = "short",          value = 12},
    {name = "MinorHotspots",                    index =  8, ctype = "short",          value = 30},
    {name = "HotspotWidth",                     index =  9, ctype = "double",         value = 1.0},
    {name = "majPlateExpansion",                index = 10, ctype = "short",          value = 4},
    {name = "minPlateExpansion",                index = 11, ctype = "short",          value = 3},
    {name = "plateRandomness",                  index = 12, ctype = "short",          value = 50},
    {name = "totalPlatesUsed",                  index = 13, ctype = "short",          value = 1},
    {name = "PlateSpeed",                       index = 14, ctype = "double",         value = 1.0},
    {name = "PercentCrust",                     index = 15, ctype = "short",          value = 45},
    {name = "OldMountains",                     index = 16, ctype = "double",         value = 1.0},
    {name = "OldHills",                         index = 17, ctype = "double",         value = 1.0},
    {name = "AncientMountains",                 index = 18, ctype = "double",         value = 1.0},
    {name = "MountainPasses",                   index = 19, ctype = "double",         value = 1.0},
    {name = "MountainWidth",                    index = 20, ctype = "double",         value = 1.0},
    {name = "BeltLength",                       index = 21, ctype = "double",         value = 1.0},
    {name = "BeltFrequency",                    index = 22, ctype = "double",         value = 1.0},
    {name = "MinorOceanPlates",                 index = 23, ctype = "short",          value = 4},
    {name = "LargeIslandArcs",                  index = 24, ctype = "double",         value = 2.0},
    {name = "SunkenContinents",                 index = 25, ctype = "double",         value = 0.0},
    {name = "ContinentalShelves",               index = 26, ctype = "double",         value = 1.0},
    {name = "ContinentalSlopes",                index = 27, ctype = "double",         value = 1.0},
    {name = "AbyssalPlains",                    index = 28, ctype = "double",         value = 1.0},
    {name = "evaporationConstant",              index = 29, ctype = "double",         value = 5000.0},
    {name = "rainfallMultiplier",               index = 30, ctype = "double",         value = 1.0},
    {name = "vapourAbsorptionFactor",           index = 31, ctype = "double",         value = 0.00175},
    {name = "backgroundGreenhouseEffectFactor", index = 32, ctype = "double",         value = 0.21},
    {name = "rainfallThreshold",                index = 33, ctype = "double",         value = 0.99},
    {name = "diffusionUpdatesPerClimateUpdate", index = 34, ctype = "int",            value = 3},
    {name = "diffusionStrength",                index = 35, ctype = "double",         value = 1.0 / 80.0},
    {name = "passiveRainCoefficient",           index = 36, ctype = "double",         value = 0.1},
    {name = "advectionStrength",                index = 37, ctype = "float",          value = 0.4},
    {name = "iceCapCorrection",                 index = 38, ctype = "double",         value = 0.09},
    {name = "hadleyDrynessFactor",              index = 39, ctype = "double",         value = 0.75},
    {name = "hadleyTemperatureImpact",          index = 40, ctype = "double",         value = 0.75},
    {name = "hadleyTargetTemperature",          index = 41, ctype = "double",         value = 306.15},
    {name = "hadleyMinLat",                     index = 42, ctype = "double",         value = 0.34906600000000004},
    {name = "hadleyMaxLat",                     index = 43, ctype = "double",         value = 0.61086550000000006},
    {name = "worldScaling",                     index = 44, ctype = "double",         value = 1.0},
    {name = "numOfPlates",                      index = 45, ctype = "int",            value = 10},
    {name = "numOfBoundaries",                  index = 46, ctype = "int",            value = 1},
    {name = "numWaterBodies",                   index = 47, ctype = "int",            value = 1},
    {name = "initialClimateTicks",              index = 48, ctype = "",               value = nil}, -- SKIPPED
    {name = "iceAgeSeverity",                   index = 49, ctype = "float",          value = 1.0}
}

---@enum sote_tasks
local sote_tasks = {
    init_world = 1,
    clean_up = 6
}

---@enum sote_vals
local sote_vals = {
    latitude = 40, -- Colatitude
    longitude = 41, -- MinusLongitude
    elevation = 1, -- Elevation
    -- water_movement = 20, -- skipped?
    rugosity = 43, -- Hilliness
    rock_type = 35, -- RockType (needs some translation)
    volcanic_activity = 5, -- VolcanicActivity
    -- IsLand: computed from elevation
    plate = 15,
}

local function log_info(msg)
  print("[libsote] " .. msg)
end

local function log_sote(sote_msg)
  print("[libSOTE.dll] " .. ffi.string(sote_msg))
end

local message = nil

local function log_and_set_msg(msg)
  log_info(msg)
  message = msg
end

local function get_message()
  return message
end

local function init_mem_reserve()
  kernel32 = ffi.load("kernel32")

  local addr = ffi.cast("LPVOID", 0x8000000000)
  local alloc_size = 0x5000002000
  local allocated_memory = nil
  local allocation_attempts = 10
  local allocation_success = false

  while allocation_attempts > 0 do
    allocated_memory = kernel32.VirtualAlloc(addr, alloc_size, ffi.C.MEM_RESERVE, ffi.C.PAGE_EXECUTE_READWRITE)

    if allocated_memory == nil then
      log_info("memory allocation failed with error code: " .. tostring(ffi.C.GetLastError()))
    elseif allocated_memory ~= addr then
      log_info("allocated memory, but not at expected address")
      kernel32.VirtualFree(allocated_memory, 0, ffi.C.MEM_RELEASE)
    else
      allocation_success = true
      log_info("libSOTE memory reserved")
      break
    end

    allocation_attempts = allocation_attempts - 1
  end

  if not allocation_success then
    log_and_set_msg("Memory allocation failed")
    return false
  end

  ffi.gc(allocated_memory, function(addr) kernel32.VirtualFree(addr, 0, ffi.C.MEM_RELEASE) end)

  return true
end

local lib_sote_instance = nil

local function init()
  print(_VERSION, jit.arch)
  return true
end

-- local function init()
--   -- print(_VERSION, jit.arch)

--   if ffi.os ~= "Windows" then
--     log_and_set_msg("libSOTE only supported on Windows for now")
--     return false
--   end

--   if not init_mem_reserve() then return false end

--   local bins_dir = love.filesystem.getSourceBaseDirectory() .. "/sote/engine/bins/win/"
--   lib_sote_instance = ffi.load(bins_dir .. "libSOTE.dll")
--   if not lib_sote_instance then
--     log_and_set_msg("Failed to load libSOTE.dll")
--     return false
--   end

--   local err_msg = ffi.new("char[256]")

--   local ret_code = lib_sote_instance.LIBSOTE_Init(err_msg, love.filesystem.getSourceBaseDirectory() .. "/sote/logs/libSOTE/log.txt")
--   if ret_code ~= 0 then
--     log_sote(err_msg)
--     log_and_set_msg("Failed to init libSOTE")
--     message = message .. ": " .. ffi.string(err_msg)
--     return false
--   end

--   log_info("initialized libSOTE")

--   return true
-- end

local function int_to_uint(n)
  local bit = require("bit")
  if n < 0 then
    n = bit.bnot(math.abs(n)) + 1
  end
  if n < 0 then
    n = n + 2^32
  end
  return n
end

local bit = require("bit")
local bnot_big_number = bit.bnot(int_to_uint(4294959104))
local min_int = -2^31

local function hex_coord_to_hex_number(face, q, r)
  face = int_to_uint(face)
  q = int_to_uint(q)
  r = int_to_uint(r)

  local shift_face = bit.lshift(face, 26)
  local r_and_bnbn = bit.band(r, bnot_big_number)
  local shift_r_and_bnbn = bit.lshift(r_and_bnbn, 13)
  local q_and_bnbn = bit.band(q, bnot_big_number)

  return int_to_uint(bit.bor(min_int, shift_face, shift_r_and_bnbn, q_and_bnbn))
end

local function get_val(desc, err_msg, val)
  local ret_code = lib_sote_instance.LIBSOTE_GetVar(err_msg, 3, desc, ffi.cast("void*", val))
  if ret_code ~= 0 then
    log_sote(err_msg)
    error("failed to get val")
  end
end

local function set_sote_params()
  local err_msg = ffi.new("char[256]")
  local ret_code = 0

  local desc = ffi.new("unsigned int[3]", {1, 0, 0})
  for _, v in ipairs(sote_params) do
    if v.ctype == "" then goto continue end

    desc[2] = v.index
    local val = ffi.new(v.ctype .. "[1]", v.value)
    ret_code = lib_sote_instance.LIBSOTE_SetVar(err_msg, 3, desc, ffi.cast("void*", val))

    ::continue::
  end
end

---
local function init_world()
  local err_msg = ffi.new("char[256]")
  local ret_code = 0

  ret_code = lib_sote_instance.LIBSOTE_StartTask(err_msg, sote_tasks.init_world, 0, nil)
  if ret_code ~= 0 then
    log_sote(err_msg)
    error("failed to start init_world task: ")
  end
  log_info("started task init_world")

  local current_msg = ""
  local msg = ffi.new("char[256]")
  while lib_sote_instance.LIBSOTE_IsRunning() == 1 do
    -- ffi.fill(msg, ffi.sizeof(msg))
    lib_sote_instance.LIBSOTE_GetLoadMessage(err_msg, msg)

    local new_msg = ffi.string(msg)
    if new_msg ~= current_msg then
      current_msg = new_msg
      log_sote(current_msg)
    end
  end

  log_and_set_msg("World generation finished")
end

local function get_tile(desc, err_msg, float_val)
  local ret_code = 0

  desc[2] = sote_vals.latitude
  get_val(desc, err_msg, float_val)

  desc[2] = sote_vals.longitude
  get_val(desc, err_msg, float_val)

  local tile = require("libsote.tile")
  tile = tile:new()
end

---
local function generate_world()
  -- if not lib_sote_instance then
  --   log_and_set_msg("libSOTE not initialized")
  --   return false
  -- end

  -- set_sote_params()
  -- init_world()

  local world_size = sote_params[2].value

  local world_allocator = require("libsote.world_allocator"):new()
  local world = world_allocator:allocate(183)
  if not world then
    log_and_set_msg("World allocation failed")
    return false
  end

  local err_msg = ffi.new("char[256]")
  local float_val = ffi.new("float[1]")

  local get_desc = ffi.new("unsigned int[3]", {0, 0, 0})

  -- for q = -world_size, world_size do
  --   for r = -world_size, world_size do
  --     local s = -(q + r)
  --     if q - s <= world_size and r - q <= world_size and s - r <= world_size then
  --       for face = 0, 19 do
  --         get_desc[1] = hex_coord_to_hex_number(face, q, r)
  --         local tile = get_tile(get_desc, err_msg, float_val)
  --       end
  --     end
  --   end
  -- end

  log_and_set_msg("World data loaded")
  return true
end

return {
  init = init,
  get_message = get_message,
  generate_world = generate_world
}