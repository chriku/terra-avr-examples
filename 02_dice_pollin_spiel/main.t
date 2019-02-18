local C = terralib.includecstring [[
#include <stdint.h>
void _delay_loop_2	( uint16_t __count	);
]]

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
  dio("tccr1b",0x81)
  dio("timsk1",0x6f)
  dio("ocr1a",0x88,int16)
end


local c={}

for i=1,4 do
  local val=0
  val=bit.bor((i==1) and bit.lshift(1,0) or 0,val)
  val=bit.bor((i==2) and bit.lshift(1,1) or 0,val)
  val=bit.bor((i==3) and bit.lshift(1,3) or 0,val)
  val=bit.bor((i==4) and bit.lshift(1,4) or 0,val)
  table.insert(c,quote
    io.portd.set(1<<4)
    delay(1000)
  end)
end

terra main()
  var state:uint8=0
  io.ddrd.set([ bit.bor(1,2,8,16) ])
  for i=0,5 do
    io.portd.set(0)
    delay(100)
    io.portd.set([ bit.bor(1,2,8,16) ])
    delay(100)
  end
  var w:uint8=0
  while true do
    if w==0 then
      io.portd.set(1<<0)
    elseif w==1 then
      io.portd.set(1<<1)
    elseif w==2 then
      io.portd.set(1<<3)
    elseif w==3 then
      io.portd.set(1<<4)
    end
    if (io.pind.get() and 4)~=0 then
      w=(w+1)%4
    end
  end
end

print(main)

local avr=terralib.newtarget{
Triple="avr-none-elf";
CPU="attiny2313";
}
terralib.saveobj("main.o","object",{main=main},nil,avr,false)
