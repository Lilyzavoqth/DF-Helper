-- Set this to a number above 0 to hide monsters farther
-- away than this distance. Recommended value 750-1000,
-- but play with it and see what you like!
local maxDistance = 0

-- Standard enemy colors are white, rare enemies are yellow, bosses are red.
-- Minibosses are a less threatening red. 8)
-- Changing the second value to "false" makes the enemy not appear on the monster
-- reader.
local m = {}
m[0] =      { color = 0xFFFFFFFF, display = false } -- Unknown

-- Cave
segment = "Cave"
m[15] =     { color = 0xFFFFFFFF, display = true, height = 5, width = 5, cate = "Nano Dragon",            seg = segment } -- Nano Dragon

-- Mine
segment = "Mine"
m[26] =     { color = 0xFFFFFFFF, display = true, height = 30, width = 5, cate = "Sinow Beat / Sinow Blue", seg = segment } -- Sinow Beat / Sinow Blue
m[27] =     { color = 0xFFFFFFFF, display = true, height = 30, width = 5, cate = "Sinow Gold / Sinow Red",  seg = segment } -- Sinow Gold / Sinow Red
m[28] =     { color = 0xFFFFFFFF, display = true, height = 5, width = 5, cate = "Canadine / Canabin",      seg = segment } -- Canadine / Canabin
m[29] =     { color = 0xFFFFFFFF, display = true, height = 5, width = 5, cate = "Canane / Canune",         seg = segment } -- Canane / Canune
--m[49] =     { color = 0xFFFFFFFF, display = true, height = 3, width = 5, cate = "Dubwitch",                seg = segment } -- Dubwitch

-- Central Control Area
segment = "Central Control Area"
m[55] =     { color = 0xFFFF8080, display = true, height = 14, width = 5, cate = "Gi Gue",          seg = segment } -- Gi Gue
m[61] =     { color = 0xFFFF8080, display = true, height = 14, width = 5, cate = "Gibbles",         seg = segment } -- Gibbles
m[62] =     { color = 0xFFFFFFFF, display = true, height = 30, width = 5, cate = "Sinow Berill",    seg = segment } -- Sinow Berill
m[63] =     { color = 0xFFFFFFFF, display = true, height = 30, width = 5, cate = "Sinow Spigell",   seg = segment } -- Sinow Spigell

-- Seabed
segment = "Seabed"
m[69] =     { color = 0xFFFFFFFF, display = true, height = 30, width = 5, cate = "Sinow Zoa",   seg = segment } -- Sinow Zoa
m[70] =     { color = 0xFFFFFFFF, display = true, height = 30, width = 5, cate = "Sinow Zele",  seg = segment } -- Sinow Zele
m[66] =     { color = 0xFFFFFFFF, display = true, height = 14, width = 5, cate = "Morfos",      seg = segment } -- Morfos

-- Crater
segment = "Crater"
m[94] =     { color = 0xFFFFFFFF, display = true, height = 70, width = 5, cate = "Zu",          seg = segment } -- Zu
m[95] =     { color = 0xFFFFFF00, display = true, height = 14, width = 5, cate = "Pazuzu",      seg = segment } -- Pazuzu

return
{
    maxDistance = maxDistance,
    m = m,
}
