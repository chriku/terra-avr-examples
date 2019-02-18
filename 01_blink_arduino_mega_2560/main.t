local f=16*1000*1000 -- CPU Frequency

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
    delay(1000)
    io.portb.set(128)--LED-Pin
    delay(100)
  end
end

local avr=terralib.newtarget{
Triple="avr-elf-eabi";
CPU="atmega2560";
}
terralib.saveobj("main.o","object",{main=main},nil,avr,true)
