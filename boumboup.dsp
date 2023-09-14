import("stdfaust.lib");

process = kick, rumble, clap, bass, stars, waah, chords, tic :> ef.cubicnl(0.1,0) <:_,_ ;

//simple
//======

bass = (os.osc(fr)+os.osc(fr*2)*0.6+os.osc(fr*3)*0.3)*gate*0.2*amp with{
    fr = ba.midikey2hz(ba.hz2midikey(80)+(bar%4==2)*0.5);
    gate = ((bar>7)|(loop>0)):ba.line(15) -((loop==3)*(bar==7)):ba.line(15);
    //sidechain -->
        amp = 1- en.ar(0.01,0.15,trig);
        trig = (clock!=clock')*ba.selectn(16,clock,list);
        list = 3,0,0,0, 3,0,0,0, 3,0,0,0, 3,0,0,0;
};

chords = os.sawtooth(ba.midikey2hz(freq1+12+3.5)),
        os.sawtooth(ba.midikey2hz(freq2+12+3.5)),
        os.sawtooth(ba.midikey2hz(freq3+12+3.5)) :> _*0.8*mute : fi.lowpass(2,600):ef.cubicnl(0.1,0)*0.1:fi.resonhp(800,3,1) with{
    freq1 = ba.selectn(8,bar%8,39,41,40,39,46,41,39,40);
    freq2 = ba.selectn(8,bar%8,43,44,43,44,48,48,46,44);
    freq3 = ba.selectn(8,bar%8,48,48,49,48,52,51,50,49);
    mute = loop>2;
};

//sound engines
//=============

ticGen(val) = rPulse(val):fi.resonbp(2560,80,0.2) with{
rPulse(r) = ba.pulse((no.noise:ba.latch(ba.pulse(3000))*0.5+1.1)*(1-r)*40000+1500);
};

waahGen(gr) = (os.sawtooth(80+gro*120)*gro) +
            (no.noise*(0.9*gro+0.1)) :
                fi.resonlp(gro*500+100,5,gro*0.5) : fx : ef.cubicnl(0.2,0) with{
fx = _<: _*(1-ring)+_*os.osc(44)*ring;
mod = no.noise:ba.latch(ba.pulse(7000/(rand+1)))*rand*0.1;
gro = gr+mod:si.smoo; //0<gr<1
ring = 0.8;
rand = 0.8;
                };

simpleSynth(gate,freq) = (os.osc(f)+os.osc(f*2)+os.osc(f*4))*en.ar(0.05,0.2,gate)*0.1 with{
    f = freq * (1+rand*0.03);
    rand = no.noise:ba.sAndH(ba.pulse(200)):ba.line(200);
};

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

tic = ticGen(val)*mute with{
    val = (bar-4)/12:ba.line(200)+rand*0.5;
    rand = no.noise*0.5+0.5:ba.sAndH(ba.pulse((60/Tempo/2)*ma.SR)):ba.line(60/Tempo/2);
    mute = (loop==2)*(bar>3);
};

waah = waahGen(grog)*mute*0.1 with{
    grog = no.noise*0.5+0.5:ba.sAndH(ba.pulse((60/Tempo/2)*ma.SR)):ba.line(60/Tempo/2);
    mute = (loop>0)*(bar>7)*(loop%2==1):ba.line(15) + (loop==4)*(bar>7):ba.line(15);
};

stars = simpleSynth(gate,freq)*mute :fx : fi.resonlp(2000,3,0.4) with{
    val = (clock!=clock')*ba.selectn(2,loop,list0,list1);
    gate = val > 0;
    list0 = (clock!=clock')*ba.selectn(16,clock,640,0,0,0, 0,0,0,0, 640,0,0,0, 0,0,0,0);
    list1 = (clock!=clock')*ba.selectn(16,clock,640,0,720+(bar%4==2)*15,0, 0,680-(bar%4==2)*25,0,0, 640,0,0,0, 0,666-(bar%4==3)*666,0,0);
    freq = val:ba.sAndH(gate);
    mute = ((bar>3):ba.line(ma.SR*8)*(loop==0)*(bar<8))+(loop==1)+(loop==4);
    fx = _<:_*mute,(_*(1-mute):ef.echo(0.05,0.05,0.9*(1-mute))):>_;
};

kick = kickGen(gate)*mute*1.2 with{
    gate = (clock!=clock')*ba.selectn(16,clock,list);
    list = 6,0,0,0, 5,0,0,0, 6,0,0,0, 4,0,0,0;
    mute = (bar>7)|(loop>0) -((loop==3)*(bar<8));
};

rumble = rumbleGen(val)*amp*1.2 with{
    val = 100 - ((loop>0)|(bar>3))*33.33:ba.line(ma.SR*60*16/Tempo) +5*(bar%4==2)*(loop>1);
    amp = 1:ba.line(ma.SR*60*8/Tempo) -ba.line(15,loop>0) +ba.line(15,loop>1) -ba.line(15,(loop==3)*(bar<8)) ;
};

clap = noiseGen(gate,500,3)+@(noiseGen(gate,500,3),del) : _*0.2*mute : fx with{
    gate = (clock!=clock')*ba.selectn(16,clock,list);
    list = 3,0,0,3, 0,0,3,0, 0,3,0,3, 3,0,3-br,0;
    br = 3*(loop==0)*(bar==15) + 3*(loop==0)*(bar==7) ; //break
    del = int(0.01*ma.SR);
    fx = _ <: fi.resonhp(15000-(14900:ba.line(ma.SR*8)),4,1)*(loop==0)*(bar<8), _*((bar>7)|(loop>0)):>_;
    mute = 1 -((loop==3)*(bar<8));
};

//sequencer
//=========

loop = ba.counter(bar<bar') <:attach(_,hbargraph("[0]tourne",0,15));
bar = ba.counter(clock<clock')%16 <:attach(_,hbargraph("[1]mesure",0,15));
clock = os.phasor(16,Tempo/60/4):int <:attach(_,hbargraph("[2]double",0,15));
Tempo = 138;
