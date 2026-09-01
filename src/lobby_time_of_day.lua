local TimeOfDay={}

local function clamp(value,minimum,maximum)return math.max(minimum,math.min(maximum,value))end
local function smooth(value)value=clamp(value,0,1);return value*value*(3-2*value)end
local function mix(a,b,t)return a+(b-a)*t end
local function mixColor(a,b,t)return{mix(a[1],b[1],t),mix(a[2],b[2],t),mix(a[3],b[3],t),mix(a[4]or 1,b[4]or 1,t)}end

-- Local civil-time keys. The last key repeats midnight so interpolation stays
-- continuous across the date boundary instead of flashing at 00:00.
local KEYS={
 {hour=0,top={.012,.027,.082},middle={.035,.062,.13},bottom={.075,.09,.17},light=.25,warm=.08},
 {hour=5,top={.035,.075,.16},middle={.15,.17,.25},bottom={.48,.25,.24},light=.34,warm=.58},
 {hour=6.5,top={.10,.26,.43},middle={.43,.49,.55},bottom={.93,.53,.30},light=.62,warm=1},
 {hour=9,top={.13,.35,.54},middle={.43,.59,.68},bottom={.70,.69,.62},light=.90,warm=.42},
 {hour=12,top={.10,.32,.52},middle={.40,.59,.69},bottom={.68,.71,.69},light=1,warm=.20},
 {hour=16,top={.11,.29,.42},middle={.39,.49,.55},bottom={.89,.58,.36},light=.86,warm=.82},
 {hour=18.5,top={.055,.14,.27},middle={.25,.27,.37},bottom={.70,.29,.20},light=.48,warm=1},
 {hour=20,top={.018,.047,.13},middle={.07,.10,.19},bottom={.17,.13,.21},light=.29,warm=.28},
 {hour=24,top={.012,.027,.082},middle={.035,.062,.13},bottom={.075,.09,.17},light=.25,warm=.08},
}

function TimeOfDay.localHour(now)
 local value=now or os.date("*t")
 return((value.hour or 0)+(value.min or 0)/60+(value.sec or 0)/3600)%24
end

function TimeOfDay.state(hour)
 hour=(hour or TimeOfDay.localHour())%24
 local left,right=KEYS[1],KEYS[#KEYS]
 for index=1,#KEYS-1 do if hour>=KEYS[index].hour and hour<=KEYS[index+1].hour then left,right=KEYS[index],KEYS[index+1];break end end
 local blend=smooth((hour-left.hour)/math.max(.001,right.hour-left.hour))
 local night=hour<6 or hour>=18
 local phase=night and(((hour<6 and hour+24 or hour)-18)/12)or((hour-6)/12)
 phase=clamp(phase,0,1)
 local starAlpha
 if hour<6 then starAlpha=smooth((6-hour)/1.7)
 elseif hour>=18 then starAlpha=smooth((hour-18)/1.7)
 else starAlpha=0 end
 return{
  hour=hour,top=mixColor(left.top,right.top,blend),middle=mixColor(left.middle,right.middle,blend),bottom=mixColor(left.bottom,right.bottom,blend),
  light=mix(left.light,right.light,blend),warm=mix(left.warm,right.warm,blend),stars=starAlpha,
  celestial=night and"moon"or"sun",celestialX=.08+.84*phase,celestialY=.50-.35*math.sin(math.pi*phase),
 }
end

return TimeOfDay
