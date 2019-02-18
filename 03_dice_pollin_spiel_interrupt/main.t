local avr=terralib.newtarget{
Triple="avr-none-elf";
CPU="attiny2313";
}
local C = terralib.includecstring ([[
#include <avr/io.h>
]],{"-I","/usr/lib/avr/include/"},avr)

local ret={}
local sm=macro(function()
  local ret={}
  for i=0,31 do
    table.insert(ret,quote
      terralib.asm(terralib.types.unit,[ "push r"..i ],"",true)
    end)
  end
  table.insert(ret,quote
    terralib.asm(terralib.types.unit,"in r0,0x3f","",true)
    terralib.asm(terralib.types.unit,"push r0","",true)
  end)
  return ret
end)
local em=macro(function()
  local ret={}
  table.insert(ret,quote
    terralib.asm(terralib.types.unit,"pop r0","",true)
    terralib.asm(terralib.types.unit,"out 0x3f,r0","",true)
  end)
  for i=31,0,-1 do
    table.insert(ret,quote
      terralib.asm(terralib.types.unit,[ "pop r"..i ],"",true)
    end)
  end
  return ret
end)
local function isr(int,t)
  local num=C[int.."_num"]
  ret["__vector_"..num]=terra()
    sm()
    t()
    em()
    terralib.asm(terralib.types.unit,"reti","",true)
  end
end

local f=1*1000*1000 -- CPU Frequency

local delay=macro(function(ms) -- Not perfect, but good enough for blinking
  ms=ms:asvalue()
  local cycles=math.floor(ms/1000.0*f)
  local ret={}
  while cycles>=5 do
    local m=math.floor(math.min(65535,cycles/4))
    table.insert(ret,quote terralib.asm(terralib.types.unit,"sbiw $0,1\nbrne -4","{r24},~{r24}",false,m) end)
    cycles=cycles-((m*4)+1)
  end
  return ret
end)

local io={}
do
  local function dio(name,val,t)
    t=t or uint8
    local addr=val
    io[name]={set=macro(function(v)
      return quote terralib.attrstore([&t](addr),v,{isvolatile=true}) end
    end),get=macro(function()
      return `([t](terralib.attrload([&t](addr),{isvolatile=true})))
    end)}
  end
  dio("pinb",0x36)
  dio("ddrb",0x37)
  dio("portb",0x38)
  dio("pind",0x30)
  dio("ddrd",0x31)
  dio("portd",0x32)
  dio("tccr1b",0x4e)
  dio("timsk",0x59)
  dio("ocr1a",0x4a,uint16)
end

local w=global(uint8)
local noc=global(uint8)

terra ret.main()
  var state:uint8=0
  io.ddrd.set([ bit.bor(1,2,8,16) ])
  for i=0,5 do
    io.portd.set(0)
    delay(100)
    io.portd.set([ bit.bor(1,2,8,16) ])
    delay(100)
  end
  io.tccr1b.set((1<<C.WGM12) or 2)
  io.timsk.set(1<<C.OCIE1A)
  io.ocr1a.set([ (15000/5)-1 ])
  terralib.asm(terralib.types.unit,"sei","",true)
  var ww:uint8
  while true do
    if (io.pind.get() and 4)~=0 then
      ww=(ww+1)%4
      noc=0
    else
      w=ww
    end
  end
end

local dw=global(uint8)

isr("TIMER1_COMPA_vect",terra()
  if noc < 250 then noc=noc+1 else io.portd.set(0) return end
  if w==0 then
    io.portd.set(1<<0)
  elseif w==1 then
     io.portd.set(1<<1)
  elseif w==2 then
    io.portd.set(1<<3)
  elseif w==3 then
    io.portd.set(1<<4)
  else
    io.portd.set(0)
  end
  w=(w+1)%4
end)

terralib.saveobj("main.o","object",ret,nil,avr,true)
