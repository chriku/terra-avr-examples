local C = terralib.includecstring [[
#include <stdint.h>
void _delay_loop_2	( uint16_t __count	);
]]

local f=16*1000*1000 -- CPU Frequency

local delay=macro(function(ms) -- Not perfect, but good enough for blinking
  ms=ms:asvalue()
  local cycles=math.floor((ms/1000.0*f)/4)
  local ret={}
  while cycles>0 do
    local m=math.min(65535,cycles)
    table.insert(ret,quote C._delay_loop_2(m) end)
    cycles=cycles-m
  end
  return ret
end)

local io={}
do
  local function dio(name,val,t)
    t=t or uint8
    local addr=val
    io[name]={set=macro(function(v) return quote @([&t](addr))=v end end)}
  end
  dio("portb",0x25)
  dio("ddrb",0x24)
  dio("tccr1b",0x81)
  dio("timsk1",0x6f)
  dio("ocr1a",0x88,int16)
end

terra main()
  io.ddrb.set(128)--LED-Pin to Output
  while true do
    io.portb.set(0)
    delay(100)
    io.portb.set(128)--LED-Pin
    delay(100)
  end
end

local avr=terralib.newtarget{
Triple="avr-none-eabi";
CPU="atmega2560";
}
terralib.saveobj("main.o","object",{main=main},nil,avr,true)
