import("stdfaust.lib");

process = kick, rumble, clap, bass :> ef.cubicnl(0.1,0) <:_,_ ;

//simple
//======

bass = (os.osc(fr)+os.osc(fr*2)+os.osc(fr*3)*0.5)*gate*0.1*amp with{
    fr = ba.midikey2hz(ba.hz2midikey(80)+(bar%4==2)*0.5);
    gate = ((bar>7)|(loop>0)):ba.line(15);
    //sidechain -->
        amp = 1- en.ar(0.01,0.15,trig);
        trig = (clock!=clock')*ba.selectn(16,clock,list);
        list = 3,0,0,0, 3,0,0,0, 3,0,0,0, 3,0,0,0;
};

//sound engines
//=============

kickGen(gate) = env*os.osc(60*env+25) : ef.cubicnl(0.1,0) with{
    env = trig:en.ar(0.01,rel);
    rel = ((60/Tempo/16)-0.01)*gate : ba.sAndH(trig);
    trig = gate>0;
};

rumbleGen(intensity)=no.noise<:par(i,4,fi.resonbp(fr*(i+2)/(i+1),(200-intensity),amp)):>_ : fi.lowpass(1,500) : ef.cubicnl(0.1,0) with{
    fr = 40+intensity*1.2;
    amp = (0.1 + (100-intensity)/500)*0.2;
};

noiseGen(gate,fr,q) = no.noise:fi.resonbp(fr,q,amp):ef.cubicnl(0.1,0) with{
    amp = trig:en.ar(0.002,rel);
    trig = gate>0;
    rel = ((60/Tempo/16)-0.01)*gate : ba.sAndH(trig);
};

//instruments
//===========

kick = kickGen(gate)*mute*1.2 with{
    gate = (clock!=clock')*ba.selectn(16,clock,list);
    list = 3,0,0,0, 3,0,0,0, 3,0,0,0, 3,0,0,0;
    mute = (bar>7)|(loop>0);
};

rumble = rumbleGen(val)*amp with{
    val = 100 - ((loop>0)|(bar>3))*33.33:ba.line(ma.SR*60*16/Tempo);
    amp = 1:ba.line(ma.SR*60*8/Tempo) * (1-ba.line(15,loop>0));
};

clap = noiseGen(gate,500,3)+@(noiseGen(gate,500,3),del) : _*0.3 : fx with{
    gate = (clock!=clock')*ba.selectn(16,clock,list);
    list = 3,0,0,3, 0,0,3,0, 0,3,0,3, 3,0,3,0;
    del = int(0.01*ma.SR);
    fx = _ <: fi.resonhp(15000-(14900:ba.line(ma.SR*8)),4,1)*(loop==0)*(bar<8), _*((bar>7)|(loop>0)):>_;
};

//sequencer
//=========

loop = ba.counter(bar<bar') <:attach(_,hbargraph("[0]tourne",0,15));
bar = ba.counter(clock<clock')%16 <:attach(_,hbargraph("[1]mesure",0,15));
clock = os.phasor(16,Tempo/60/4):int <:attach(_,hbargraph("[2]double",0,15));
Tempo = 140;
