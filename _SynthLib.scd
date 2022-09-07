// Sound Library - synthetic sounds
/*
a percussion SynthDef Library by The Society For Nontrivial Pursuits
with generous contributions by Jan Kees van Kampen

to be expanded ...

unified parameter interface:
- out
- amp
- pan
- dur
- att
- dec
- ..?..
- freq for tonal sounds

*/
q = q ? ();
q.origSynthDefs = q.origSynthDefs ?? { SynthDescLib.global.synthDescs.keys };

"allesAnAlle.scd".loadRelative; // load here, so all SDs count into q.synthDefs

// SynthDescLib.at(\acid).makeGui

SynthDef(\acid, { | cut = 4000, rez = 0.75, dist = 0, wform = 0, slide = 0.5, att = 0.02 dec = 0.2, amp = 1, sustain = 1, pan = 1, freq = 1000, t_gate = 1, out = 0 |
    var waves = [ DPW4Saw.ar( freq.lag2(slide), 0.75 ),  Pulse.ar( freq.lag2(slide) ) ];
    var sound = SelectX.ar( wform, waves )!( s.options.numOutputBusChannels );
    var env = EnvGen.kr( Env.adsr( att, dec, 0.5, \rel.kr(0.1) ), t_gate, timeScale: sustain, doneAction: Done.freeSelf );
    var noise = { LFDNoise3.ar(0.3,0.0156,1) };
    sound = sound * noise;
    sound = ( RLPFD.ar( sound, cut, rez, dist ) * 0.5 ) + ( RLPF.ar(sound, cut) * 0.5 );
    sound = sound + ( HPF.ar(sound, 400, 10).softclip * 0.04);
    sound = sound + PitchShift.ar(sound, 0.1, 1.0, 0.02, 0.2) * 0.5 * env;
    sound = sound.softclip;
    OffsetOut.ar(out, sound * amp )
}, metadata: ( specs: (cut: \freq, rez: [0, 1], dist: [0,1], wform: [0,1], slide: [0,1], att: [0,1], rel: [0,4], dec: [0,1], sustain: [0.004,4] ) ) ).add;

SynthDef(\acid4, { | adrive = 0.5 wform = 0 att = 0.04 dec = 0.2 slide = 0.5 pan = 0 width = 2 amp = 1 sustain = 1 freq = (60.midicps) gate = 1 out = 0 |
    var ffreq = freq.lag2(slide);
    var waveShape = [ DPW4Saw.ar( ffreq, 0.75  ), Pulse.ar( ffreq )  ];
    var snd = SelectX.ar( wform, waveShape  );
    var env = EnvGen.kr( Env.adsr( att, dec, amp), gate, timeScale: sustain, doneAction: Done.freeSelf);
    var noise = { LFDNoise3.ar(0.3,0.0156,1) };
    snd = snd * noise;
    snd = SelectX.ar( adrive, [snd, snd * DFM1.ar(snd, freq, ffreq * 0.2 )] );
    snd = PanAz.ar( s.options.numOutputBusChannels, snd, pan, 1, width) * env;
    OffsetOut.ar(out, snd * amp);
}, metadata: ( specs: ( adrive: [0,1], wform: [0,1], slide: [0,1], att: [0.002,1], width: [0,2], rel: [0.1,10], dec: [0,1], sustain: [0,2] ) ) ).add;

SynthDef(\simples, { | width = 0.5, att = 0.01, dec = 0.5, sus = 0.5, rel = 0.5, slide = 0.1, pan = 1, amp = 0.2, sustain = 1, out = 0, freq = 220, gate = 1 |
    var sig, env;
    sig = VarSaw.ar([freq, freq * 1.01].lag2(slide), 0, width, amp);
    sig = SoftClipAmp.ar(sig, 32,  mul: amp );
    env = Env.adsr(att, dec, sus, rel).kr( doneAction: Done.freeSelf, gate: gate, timeScale: sustain);
    sig = sig * env;
    // sig = BMoog.ar(sig, 220,  q: 0.2,  mode: 0.0,  saturation: 0.95,  mul: 1.0,  add: 0.0);
    OffsetOut.ar( out, Pan2.ar(sig, pan) )
}, metadata: ( specs: ( adrive: [0,1], wform: [0,1], slide: [0,1], width: [0,2], att: [0,1], dec: [0,1], sus: [0,1], rel: [0,2] ) ) ).add;

SynthDef(\abracadabra, { |sustain = 0.8, amp = 0.1, freq = (60.midicps), out |
    var env = Line.kr(amp, 0, sustain, doneAction: Done.freeSelf);
    var snd = Saw.ar(freq + [0.3, -0.3]).sum;
    Out.ar(out, snd * env);
}).add;

SynthDef(\dubba, { | drive = 0 att = 0.1 rel = 4 dur = 0.137 sustain = 1 amp = 0.2 freq = (60.midicps) t_trig = 1 out = 0 |
    var sig, frecip, trig, trig2, env;
    frecip = ( freq / 440 + 0.001 ).reciprocal;
    trig2 = Trig1.kr(t_trig, dur);
    env = EnvGen.kr(
        Env( [ 0, (drive + amp).clip, 0 ], [ att, rel ], [ 4, -4 ] ), t_trig, timeScale: sustain, doneAction: Done.freeSelf );
    sig = SinOsc.ar( ( Lag3UD.kr( trig2, frecip / 1000, frecip, freq / 440 ) ).exprange( 0.44, 440 ) * [-0.1, 0, 0.1].midiratio, 0.5pi );
    sig = sig * env;
    sig = BPeakEQ.ar( sig, LFCub.kr(0.12, 1.5pi).exprange( 61.74, 164.81 ), 0.3, 2 );
    sig = (sig * 4).tanh;
    sig = (sig * Lag3UD.kr( trig2, 0.001, LFNoise2.kr(0.06).range( 0.5, 3) ).exprange(1, LFNoise2.kr(0.1).range(3, 10) ) ).tanh * (1 - drive ).clip(1-amp);
    sig = Compander.ar( sig, sig, 0.1, 1, 1/5, 0.05, 0.2 ) * amp;
    sig = BLowPass4.ar( sig, Lag3UD.kr( trig2, 0.01, 1 ).exprange(61.74, 11175.303), LFNoise2.kr(0.12).range( 0.25, 0.5 ) );
    sig = [ (sig[0] + sig[1]), (sig[1] + sig[2]) ];
    sig = LeakDC.ar(sig);
    OffsetOut.ar( out, Limiter.ar(sig) );
}, metadata: ( specs: ( drive: [0,1], sustain: [0,2], dur: [0,2], att: [0,1], rel: [0,2] ) ) ).add;

SynthDef(\tunel, {| degrade = 4, wform = 0.5, att = 0.01, rel = 0.1, sustain = 1, amp = 0.2, out, freq = 440, gate = 1 |
    var son, env, noise, bitReduc, down, pan, initPhase, slide = 1;
    var ffreq = freq.lag(slide);
    son = (
        Saw.ar(ffreq * 0.5, mul: (0.5 + wform).wrap(0.5, 1) ) +
        BlitB3Square.ar(ffreq, mul: ( 0.25 + wform).wrap(0.25, 1) ) +
        LFPulse.ar(ffreq * 2, mul: ( 0.25 + wform).wrap(0.25, 1) )
    ).softclip * 1.5;
    env = EnvGen.ar( Env.asr(att, amp, rel, [4, -4] ), gate, timeScale: sustain, doneAction: 2 );
    son = RLPF.ar(son, ffreq);
    noise = PinkNoise.ar(0.15);
    bitReduc = ( son + noise ).round(0.5 ** 8);
    down = Latch.ar(bitReduc, Impulse.ar(SampleRate.ir / degrade.max(2)));
    initPhase = {1.rrand(0.01)};
    pan = LFTri.ar(ffreq / (60.midicps), [initPhase, 1 - initPhase ]);
    son = son.ring3(down) * pan * env;
    OffsetOut.ar(out, son);
}, metadata: ( specs: ( degrade: [2,64], wform: [0,1], att: [0,1], rel: [0,2], sustain: [0,1] ) ) ).add;

// amateur choir - single voice
SynthDef(\hocuspocus, { | sustain = 0.8, amp = 0.1, pan, freq = (60.midicps), out |
    var env = EnvGen.kr(
        Env.linen(0.1, sustain - 0.15, 0.02),
        doneAction: 2
    );
    var slur = Line.kr(Rand(0.8, 0.96), 1, 0.2, doneAction: Done.freeSelf);
    var freqmod = LFNoise2.kr(6).range(0.97, 1.03);
    var snd = Formant.ar(
        freq * slur * freqmod,
        freq,
        freq * 1.5);
    Out.ar(out, Pan2.ar(snd * env, pan, amp) );
}).add;

(
SynthDef(\stiff, { | c3=20, fB = 80, rel= 0.1, sustain = 1, pan=0, amp=0.5, gate=1, freq, out |

    var env = EnvGen.ar(Env.new([0,1, 1, 0],[0.001,0.006, 0.0005],[5,-5, -8]), gate, timeScale:sustain, doneAction: 2 );
    var inp = amp * LFClipNoise.ar(2000) * env;
    var sound = DWGPluckedStiff.ar(freq, amp, 1,0.14,1,c3,inp,rel,fB);  //here was the problem!... input, rel, feedback

    DetectSilence.ar(sound, 0.001, doneAction:2);
    OffsetOut.ar(out,
        PanAz.ar( s.options.numOutputBusChannels, sound * 0.1, pan )
    )
}, metadata: ( specs: ( c3: [10,1000], fB: [0,500], rel: [0.1,1] ) ) ).add
);

(
SynthDef(\atari, { | freqb=550, freqc=660, vola=15, volb=0, volc=0, chink=1, wobbly=1, envfreq=4, pan=0, amp=0.1, gate = 1,  sustain = 1, out, freq |
    var ay, chinkenv, wobblyenv, env;

    env = EnvGen.kr( Env.asr( 0.01, 1, 0.05 ), gate,  timeScale:sustain, doneAction:2 );
    //chinkenv = if(chink>0, EnvGen.kr(Env.new([0.06125, 0.06125, 1, 1], [0.05, 0, 0.1], 0, 4, 4)), 1);
    chinkenv = if(chink>0, EnvGen.kr(Env.new([2, 2, 1, 1], [0.05, 0, 0.1], 0, 4, 4)), 1);
    wobblyenv = LFPulse.kr(10, 0.5, mul:wobbly).range(0.5, 1);

    # freq, freqb, freqc = [freq, freqb, freqc] * [1, wobblyenv, wobblyenv] * chinkenv;
    ay = AY.ar(AY.freqtotone(freq), AY.freqtotone(freqb), AY.freqtotone(freqc),
        0, 3, vola, volb, volc, /*envfreq, */mul: amp);
    ay = ay * env;
    OffsetOut.ar( out, PanAz.ar( s.options.numOutputBusChannels, ay, pan ) )
}, metadata: ( specs: ( freqb: [10,10000, \exp], freqc: [0.005,5000, \exp], vola: \ampx4.asSpec, volb:\ampx4.asSpec, volc:\ampx4.asSpec, chink:[0,1,\lin,1,1], wobbly:[0.125,12.5], envfreq:[0,4095], sustain:[0,4] ) ) ).add;
);

(
SynthDef(\bow, { | force=1, pos=0.07, c1=0.25, c3=31, pan = 0, gate, sustain = 0.1, freq = (60.midicps), amp=0.5, out |
    var vib = Gendy1.kr(1,1,1,1,0.1, 4,mul:0.003,add:1);
    var son = DWGBowedTor.ar(freq*vib, amp,force, gate, pos,0.1,c1,c3);
    son = DWGSoundBoard.ar(son);
    son = BPF.ar(son,118,1)+son;
    son = BPF.ar(son,430,1)+son;
    son = BPF.ar(son,490,1)+son;
    son = LPF.ar(son,6000);
    OffsetOut.ar(out,
        PanAz.ar( s.options.numOutputBusChannels, son * 0.1, pan )

    )
}, metadata: ( specs: ( force: [0.02,2], pos: [0,1], c1: [0,1], c3: [0.01,1] ) ) ).add;
);

(
SynthDef(\windsaw, { | accelerate = 0, maxamp = 2.5, loamp = 0.1, att = 0.1, rel = 5, dec = 3,  /*maxosc = 20, loosc = 6,*/ pan = 0, amp = 0.3, sustain = 1, gate = 1, freq = (60.midicps), out |
    var snd, env;
    env = Env.adsr( att, dec, 0.75, rel, amp ).kr( Done.freeSelf,  gate, sustain );
    snd = LFSaw.ar( (freq*[2, 3, 4]/6) * Line.kr(1,accelerate+1, sustain),
        mul: env /* * SinOsc.kr(freq: XLine.kr(maxosc, loosc, 5).range(maxamp, loamp))*/ );
    snd = snd + LFTri.ar( freq * Line.kr(1,accelerate+1, sustain);,
        mul: env * SinOsc.kr( LFTri.kr((sustain * 10).reciprocal, 3 ).exprange(loamp, maxamp) ) );
    snd = Splay.ar(snd);
    OffsetOut.ar(out, PanAz.ar( s.options.numOutputBusChannels, snd, pan ) )
}, metadata: ( specs: ( accelerate: [0,3], maxamp: [1,4], loamp:[0.1,1], att:[0.02,2], rel:[0.1,1,], dec:[0,1] ) ) ).add;
);

(
SynthDef(\saw, { | att = 0.001, rel = 0.2, lofreq = 1000, hifreq = 3000, pan=0, gate = 1, sustain = 1, amp = 0.1, freq, out  |
    var env, snd;
    env = Env.perc( att, rel, amp ).kr( Done.freeSelf,  gate, sustain );
    snd = Saw.ar( freq * [0.99, 1, 1.001, 1.008] ) * env;
    snd = LPF.ar( snd, LFNoise2.kr(1).range(lofreq, hifreq) );
    snd = Splay.ar(snd);
    OffsetOut.ar( out, PanAz.ar( s.options.numOutputBusChannels, snd, pan ) )
}, metadata: ( specs: ( att: [0.002,1], rel: [0.02,2] ) ) ).add;
);

(instrument: \saw).play;

(
SynthDef(\bazz, { |  crunchy = 200, att = 0.025, dec = 0.6, rel = 0.5, amp=0.01, pan=0, gate = 1, sustain = 1, freq, out |
    var snd, env, snd2, sum;
    env = Env.adsr( att, dec, 0.5, rel ).kr( Done.freeSelf,  gate, sustain );
    env = env * 0.333;
    snd = LFSaw.ar( SinOsc.kr(XLine.kr(7, 2, 1)).range(freq, freq/2), mul: env * 0.5 )
    + LFSaw.ar( freq, mul: env)
    + LFTri.ar( freq * [3], mul: env * 0.5)
    + SinOsc.ar( freq * [2, 4, 6], mul: env);
    snd = LPF.ar( snd, XLine.kr( 10000, crunchy, att * 5 ) );
    snd = Splay.ar(snd);
    OffsetOut.ar(out, PanAz.ar( s.options.numOutputBusChannels, snd, pan ) )
}, metadata: ( specs: ( crunchy: [100,300], att: [0.002,1], dec: [0.01,1], rel: [0.02,2] ) ) ).add;
);

(
SynthDef(\rhodes, { | modind = 0.2 mix = 0.2 lfospeed = 0.4 lfodepth = 0.1 sustain = 1 pan = 0 amp = 0.8 gate = 1 freq out |
    var env1, env2, env3, env4;
    var osc1, osc2, osc3, osc4, snd;
    lfospeed = lfospeed * 12;
    freq = freq * 2;
    env1 = EnvGen.ar(Env.adsr(0.001, 1.25, 0.0, 0.04, curve: \lin));
    env2 = EnvGen.ar(Env.adsr(0.001, 1.00, 0.0, 0.04, curve: \lin));
    env3 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.0, 0.04, curve: \lin));
    env4 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.0, 0.04, curve: \lin));
    osc4 = SinOsc.ar(freq * 0.5) * 2pi * 2 * 0.535887 * modind * env4 * amp;
    osc3 = SinOsc.ar(freq, osc4) * env3 * amp;
    osc2 = SinOsc.ar(freq * 15) * 2pi * 0.108819 * env2 * amp;
    osc1 = SinOsc.ar(freq, osc2) * env1 * amp;
    snd = Mix((osc3 * (1 - mix)) + (osc1 * mix));
    snd = snd * (SinOsc.ar(lfospeed) * lfodepth + 1);
    // using the doneAction: 2 on the other envs can create clicks (bc of the linear curve maybe?)
    snd = snd * EnvGen.ar(Env.asr(0, 1, 0.1), gate, doneAction: 2);
    snd = Pan2.ar(snd, pan);
    OffsetOut.ar(out,  PanAz.ar( s.options.numOutputBusChannels, snd, pan ) )
}, metadata: ( specs: ( modind: [0,1], mix: [0,1], lfospeed: [0.02,2,\exp], lfodepth: [0.01,1], rel: [0.02,2] ) ) ).add;
);

// 	AnalogDrums215 by_otophilia
//	http://supercollider.jp/modules/xhnewbb/viewtopic.php?topic_id=125
(
SynthDef("ana_kick", { arg pan=0, amp=0.1, out=0;
    var env, env2, env3, pch, osc, noise, outS;
    env = EnvGen.kr(Env.perc(0, 0.20, 1, -4), doneAction:2);
    env2 = EnvGen.kr(Env.new([60,3,0],[0.08,0.16],[-18,-5]));
    env3 = EnvGen.kr(Env.new([0.8,0],[0.10],[-10]));
    pch = (32+env2).midicps;

    osc = SinOsc.ar(pch, 0, env);
    noise = BPF.ar(WhiteNoise.ar(env3), 200, 2);
    outS = osc+noise;
    OffsetOut.ar(out, Pan2.ar(outS, pan, amp));
}).add;

SynthDef("ana_snare", { arg out, pan=0, amp=0.1;
    var env, env2, env3, pch, osc, noise, outS;
    env = EnvGen.kr(Env.perc(0, 0.05, 1, -5));
    env2 = EnvGen.kr(Env.new([56,3,0],[0.08,0.1],[-20,-5]));
    env3 = EnvGen.kr(Env.new([0.5,0,0.5,0],[0.001,0.001,0.16],[0,-3,-8]), doneAction:2);
    pch = (49+env2).midicps;

    osc = SinOsc.ar(pch, 0, env);
    noise = BPF.ar(WhiteNoise.ar(env3), 9000, 2);
    outS = osc+noise;
    OffsetOut.ar(out, Pan2.ar(outS, pan, amp));
}).add;

SynthDef("ana_hat", { arg out=0, pan=0, dec=0.05, amp=0.1;
    var env, pch, osc, noise, outS;
    env = EnvGen.kr(Env.perc(0, dec, 1, -6), doneAction:2);
    pch = (SinOsc.ar(320, 0, 2000, 9000));
    osc = SinOsc.ar(pch, 0, 0.5);
    noise = WhiteNoise.ar;
    outS = osc + noise;
    outS = BPF.ar(outS, 12000, 0.3, env);
    OffsetOut.ar(out, Pan2.ar(outS, pan, amp));
}).add;

SynthDef("kick_electro1", {
    arg amp=1, pan=0, freq=60, out=0;
    var x, env1, env2, env3, mod, noise;
    env1 = Env.perc(0.001,0.15,1,-4);
    env2 = Env.perc(0.001,0.01,1,-4);
    env3 = Env.perc(0.0001,0.01,0.2,-10);
    mod = EnvGen.ar(env2, 1) * 100;
    noise = EnvGen.ar(env3, 1);
    x = SinOsc.ar(freq + mod);
    x = EnvGen.ar(env1, 1, timeScale: \legato.kr(0.2), doneAction: 2) * x - noise;
    OffsetOut.ar(out, Pan2.ar(x,pan, amp));
}).add;

);
/****** test:
(instrument: \ana_kick).play;
(instrument: \ana_snare).play;
(instrument: \ana_hat).play;
(instrument: \kick_electro1).play;
******/

SynthDef(\pandeiro1, { |out, amp = 0.1, pan, drumfreq = 100, drumres = 10, dec = 0.2, beldec = 0.02, belamp = 0.5|
    var snd = GrayNoise.ar();
    var filtFreq = amp.linlin(0.025, 0.1, 6000, 12000);
    var env = EnvGen.ar(Env.perc(0.01, dec, amp));
    var env2 = EnvGen.ar(Env.perc(0.05, dec + 0.1, amp), doneAction: 2);
    var filtered = RHPF.ar(snd, drumfreq, 0.3/drumres);
    var bellz = Klank.ar(`[
        [3567, 4200, 4765, 5100, 5689],
        belamp,
        beldec,
    ], Dust2.ar(4000) * env2).tanh;
    OffsetOut.ar(out, Pan2.ar(
        filtered * env + (bellz),
        pan));
}).add;


(
SynthDef( "Mridangam", { arg t_amp =0.4, freq = 85, out;
    var sig = Resonz.ar(
        WhiteNoise.ar([100,100]) * Decay2.kr( t_amp, 0.002, 0.1 ),
        freq,
        0.02,
        4
    ).distort;

    DetectSilence.ar( sig,  doneAction: 2 );
    OffsetOut.ar( out, sig  );
}, metadata: ( specs: ( t_amp: \amp.asSpec ) ) ).add;


SynthDef("baff",
    { arg fratio=2, envDepth=2, rq=0.8, dec=0.05, att=0.05, amp=1, freq=40, out=0;
        var sound, env;
        env = EnvGen.kr(Env.perc(0.01, dec), timeScale: \sustain.kr(1), doneAction:2);
        sound = RLPF.ar(
            Saw.ar([freq, freq+5], amp*4),
            freq * fratio * EnvGen.kr(Env.perc(att, dec, envDepth), levelBias:1),
            rq,
            env
        ).distort;
        OffsetOut.ar(out, sound);
}, metadata: ( specs: ( fratio: [0.25,4], envDepth: [0.25,4], att: [0.002,1], dec: [0.01,1] ) ) ).add;
);

/*****
(instrument: \pandeiro1).play;
(instrument: \Mridangam, amp: 0.2).play;
(instrument: \baff, dec: 1, midinote: 40 + 10.rand, envDepth: 0).play;
******/


/*
Chinese Gongs
modelled after AudioSculpt analysis

q.spruchDesTages = "es wurde ein schminktaeschchen gefunden. Die verliererin kann es im wagen 563 abholen"
*/
(
q.gongSpecs = [
    [ [1970, -28], [1245, -44], [1400, -53], [1634, -44], [3480, -58], [4456, -55], [7000, -75] ],
    [ [1639, -35], [1387, -45], [3880, -54], [4467, -67], [7055,-73] ],
    [ [1492, -21], [1250, -34], [2844, -48], [3388, -50], [3503, -53], [5456, -63], [6843, -70] ],
    [ [1240, -26], [528, -33], [3330, -50], [3400, -50], [3480, -43], [5460, -65] ],
    [ [972, -22], [810, -30], [1200, -46], [2025, -40], [2242, -48], [2320, -40], [3150, -48], [3679, -56], [4600, -72] ],
    [ [810, -22], [200, -45], [2020, -45], [242, -42], [2320, -40], [2602, -47], [3023, -53], [3680, -53], [4820, -63] ]

];
q.gongNames = q.gongSpecs.collect({ |spec, i| (\gong_ ++ i).asSymbol });

q.gongSpecs.collect({ |spec, i|
    (
        SynthDef( (\gong_ ++ i).asSymbol, {	arg out=0, dboffs = 22, dec = 2, amp= 0.1, pan=0, soft = 1;
            var sig, burst, specs, env, gate;
            specs = spec.flop;

            env = Env.new([0, 1, 0], [1, 1.5], \sin);
            burst = EnvGen.ar(env, 1,  levelScale: soft.reciprocal, timeScale: (\sustain.kr(1) * 0.012) * soft) * GrayNoise.ar(3) * WhiteNoise.ar(amp);
            burst = OnePole.ar(burst, 0.99, 15);

            sig = specs[0].collect({ arg f, i;
                Ringz.ar(burst, f , dec, (specs[1][i] + dboffs).dbamp )
            }).mean;
            sig = OnePole.ar(sig, 0.97);

            DetectSilence.ar(sig, 0.000001, doneAction:2);
            OffsetOut.ar(out, Pan2.ar(sig, pan))
        }).add
    );

})
);
/******
(instrument: ( '\gong_' ++ q.gongSpecs.size.rand ).asSymbol).play;
******/

// snr
SynthDef("up-snare-1", {
    arg   dec=0.01, amp=1, pan=0, ffreq=120, out=0;
    var x, e;
    e = Env.perc(0.01, dec, 1,-3);
    x = WhiteNoise.ar(amp);
    x = OnePole.ar(x, -0.2);
    x = HPF.ar(x, ffreq);
    x = EnvGen.kr(e, 1, doneAction: 2) * x;
    OffsetOut.ar(out, Pan2.ar(x, pan));
}).add;

// kick
SynthDef("up-kick-2", { arg dec=0.2,  pan=0, amp=0.1, freq=60,  out=0;
    var env1, env2, env3, mod1, mod2, x;
    env1 = Env.new([0.001,1,0.7,0.6,0], [0.001,0.003,0.1,0.1], -3);
    env2 = Env.perc(0, 0.01, 1, -3);
    env3 = Env.perc(0, 0.001, Rand(1, 0.5), -3);
    mod1 = EnvGen.ar(env2) * 500;
    mod2 = EnvGen.ar(env3) * 10;
    x = SinOsc.ar(freq + mod1, 0, 1, mod2) * amp;
    x = EnvGen.kr(env1, 1.0, dec * Rand(1, 0.9), doneAction:2) * x;
    OffsetOut.ar(out, Pan2.ar(x.distort.clip2(amp), pan));
}, metadata: ( specs: ( dec: [0.01,1] ) ) ).add;
/*****
(\instrument: "up-snare-1", dec: 0.1).play;
(\instrument: "up-kick-2").play;
*****/


//-----------------------------------------------------------
// SOS Drums by Renick Bell, renick_at_gmail.com
// recipes from Gordon Reid in his Sound on Sound articles
// should be simplified!


// SOSkick -------
// http://www.soundonsound.com/sos/jan02/articles/synthsecrets0102.asp
// increase mod_freq and mod_index for interesting electronic percussion
(
SynthDef(\SOSkick,
    { arg mod_freq = 5, mod_index = 5, beater_noise_level = 0.025, dec = 0.4, amp = 0.8, pan=0, freq = 50, out = 0;

        var pitch_contour, drum_osc, drum_lpf, drum_env;
        var beater_source, beater_hpf, beater_lpf, lpf_cutoff_contour, beater_env;
        var kick_mix;
        pitch_contour = freq * Line.kr(2, 1, 0.02);
        drum_osc = PMOsc.ar(	pitch_contour,
            mod_freq,
            mod_index/1.3,
            mul: 1,
            add: 0);
        drum_lpf = LPF.ar(in: drum_osc, freq: 1000, mul: 1, add: 0);
        drum_env = drum_lpf * EnvGen.ar(Env.perc(0.005, dec), 1.0, doneAction: 2);

        beater_source = WhiteNoise.ar(beater_noise_level);
        beater_hpf = HPF.ar( beater_source, 500);
        lpf_cutoff_contour = Line.kr(6000, 500, 0.03);
        beater_lpf = LPF.ar(in: beater_hpf, freq: lpf_cutoff_contour, mul: 1, add: 0);
        beater_env = beater_lpf * EnvGen.ar(Env.perc, 1.0, doneAction: 2);

        kick_mix = Mix.new([drum_env, beater_env]) * 2 * amp;
        OffsetOut.ar(out, Pan2.ar(kick_mix, pan))
    }, metadata: ( specs: ( mod_freq: [1,100,\exp], mod_index: [1,100,\exp], beater_noise_level: [0.0125,0.5], dec: [0.01,1] ) )
).add
);
/*
Synth(\SOSkick);
*/


// SOSsnare -------
// http://www.soundonsound.com/sos/Mar02/articles/synthsecrets0302.asp

(
SynthDef(\SOSsnare,
    {arg out = 0, dec = 0.1, drum_mode_level = 0.5,
        snare_level = 0.5, snare_tightness = 1000,
        freqSnr = 405, amp = 0.8, pan=0;

        var drum_mode_sin_1, drum_mode_sin_2, drum_mode_pmosc, drum_mode_mix, drum_mode_env;
        var snare_noise, snare_brf_1, snare_brf_2, snare_brf_3, snare_brf_4, snare_reson;
        var snare_env;
        var snare_drum_mix;
        var freq = freqSnr;

        drum_mode_env = EnvGen.ar(Env.perc(0.005, dec, 0.5), 1.0, doneAction: 2);
        drum_mode_sin_1 = SinOsc.ar(freq * 0.53, 0, drum_mode_env * 0.5);
        drum_mode_sin_2 = SinOsc.ar(freq, 0, drum_mode_env * 0.5);
        drum_mode_pmosc = PMOsc.ar(	Saw.ar(freq * 0.85),
            184,
            0.5 / 1.3,
            mul: drum_mode_env * 5
        );
        drum_mode_mix = Mix.new([drum_mode_sin_1, drum_mode_sin_2, drum_mode_pmosc]) ;

        // choose either noise source below
        //	snare_noise = Crackle.ar(2.01, 1);
        snare_noise = LFNoise0.ar(20000, 0.1);
        snare_env = EnvGen.ar(Env.perc(0.001, dec, 80, 2), 1.0, doneAction: 2);
        snare_brf_1 = BRF.ar(in: snare_noise, freq: 8000, mul: 0.5, rq: 0.1);
        snare_brf_2 = BRF.ar(in: snare_brf_1, freq: 5000, rq: 0.1);
        snare_brf_3 = BRF.ar(in: snare_brf_2, freq: 3600, rq: 0.1);
        snare_brf_4 = BRF.ar(in: snare_brf_3, freq: 2000, rq: 0.0001);
        snare_reson = Resonz.ar(snare_brf_4, snare_tightness, 1) * snare_env;
        snare_drum_mix =
        (drum_mode_mix * drum_mode_level)
        +
        (snare_reson * snare_level )
        * amp;
        OffsetOut.ar(out, Pan2.ar(snare_drum_mix, pan))
    }
).add
);
/*
Synth(\SOSsnare);
*/

// SOShats -------
// http://www.soundonsound.com/sos/Jun02/articles/synthsecrets0602.asp

(
SynthDef(\SOShats,
    {arg dec = 0.1, amp = 0.8, freq = 6000, out = 0;
        var root_cymbal, root_cymbal_square, root_cymbal_pmosc;
        var initial_bpf_contour, initial_bpf, initial_env;
        var body_hpf, body_env;
        var cymbal_mix;

        root_cymbal_square = Pulse.ar(freq, 0.5, mul: 1);
        root_cymbal_pmosc = PMOsc.ar(root_cymbal_square,
            freq * [1.34, 2.405, 3.09, 1.309],
            [310/1.3, 26/0.5, 11/3.4, 0.72772],
            mul: 1,
            add: 0);
        root_cymbal = Mix.new(root_cymbal_pmosc);
        initial_bpf_contour = Line.kr(15000, 9000, 0.1);
        initial_env = EnvGen.ar(Env.perc(0.005, 0.1), 1.0);
        initial_bpf = BPF.ar(root_cymbal, initial_bpf_contour, mul:initial_env);
        body_env = EnvGen.ar(Env.perc(0.005, dec, 1, -2), 1.0, doneAction: 2);
        body_hpf = HPF.ar(in: root_cymbal, freq: Line.kr(9000, 12000, dec),mul: body_env, add: 0);
        cymbal_mix = Mix.new([initial_bpf, body_hpf]) * amp;
        OffsetOut.ar(out, [cymbal_mix, cymbal_mix])
}, metadata: ( specs: ( dec: [0.01,1] ) ) ).add
);

/*
Synth(\SOShats);
*/


// SOStom -------
// http://www.soundonsound.com/sos/Mar02/articles/synthsecrets0302.asp

(
SynthDef(\SOStom, { | drum_mode_level = 0.25, drum_timbre = 1.0, dec = 0.4, amp = 0.8, freq = 90, out = 0 |
        var drum_mode_sin_1, drum_mode_sin_2, drum_mode_pmosc, drum_mode_mix, drum_mode_env;
        var stick_noise, stick_env;
        var drum_reson, tom_mix;

        drum_mode_env = EnvGen.ar(Env.perc(0.005, dec), 1.0, doneAction: 2);
        drum_mode_sin_1 = SinOsc.ar(freq*0.8, 0, drum_mode_env * 0.5);
        drum_mode_sin_2 = SinOsc.ar(freq, 0, drum_mode_env * 0.5);
        drum_mode_pmosc = PMOsc.ar(	Saw.ar(freq*0.9),
            freq*0.85,
            drum_timbre/1.3,
            mul: drum_mode_env*5,
            add: 0);
        drum_mode_mix = Mix.new([drum_mode_sin_1, drum_mode_sin_2, drum_mode_pmosc]) * drum_mode_level;
        stick_noise = Crackle.ar(2.01, 1);
        stick_env = EnvGen.ar(Env.perc(0.005, 0.01), 1.0) * 3;
        tom_mix = Mix.new([drum_mode_mix, stick_env]) * 2 * amp;
        OffsetOut.ar(out, [tom_mix, tom_mix])
    }, metadata: ( specs: ( drum_mode_level: [0.0125,2,\exp], drum_timbre: [0.0125,5], dec: [0.01,1] ) )
).add
);

/*****
(instrument: \SOSkick).play;
(instrument: \SOSsnare).play;
(instrument: \SOShats).play;
(instrument: \SOStom).play;
*****/
//-e.o. SOS drums ---------------------------------------------------





SynthDef("pgrain",
    { arg distortion = 0, dec=0.01, amp=0.1, pan = 0, freq=800, out = 0;
        var window, env, u, nu;
        window = Env.perc(freq.reciprocal * Rand(0.8, 4), dec);
        env = EnvGen.ar(window,  doneAction:2);
        amp = AmpCompA.ir(freq) * amp;
        freq = Vibrato.kr(freq, Rand(13,0), Rand(0.001, 0), depthVariation:0.001);
        freq = (freq * XLine.ar(4, 1, 0.0025)).minNyquist;
        u = SinOsc.ar(freq, 0.5pi);
        u = u + LFTri.ar(max(freq * 0.25, 30), 0.5, 0.2);
        u = u * env;
        distortion = distortion * (env.squared + 0.1);
        nu = distort(u * (distortion * 8 + 1));
        u = XFade2.ar(u, nu, distortion * 2 - 1);

        OffsetOut.ar(out,
            Pan2.ar(u, pan, amp * 4)
        )
    }, metadata: ( specs: ( distortion: [0,5], dec: [0.01,1] ) )
).add;
/*****
(instrument: \pgrain).play;
(instrument: \pgrain, \freq: 2000, \dec: 0.1).play;
******/

(
SynthDef("grainlet", { arg dec=0.05, pan=0, amp=0.2, freq=440, out=0;
    var env = EnvGen.kr(Env.perc(0.01, dec, amp), doneAction:2);
    OffsetOut.ar(out, Pan2.ar(FSinOsc.ar(freq, 0, env), pan))
}, metadata: ( specs: ( dec: [0.01,1] ) ) ).add;

SynthDef("grainFM_a", { arg freqFM=800, fmi = 100.5, att=0.01, dec=0.001, amp = 0.5, pan = 0, freq=800, out = 0, bendFac = 0;
    var window, ratio=0.1;
    freq = ( freq.cpsmidi + bendFac ).midicps;
    // freq = freq * 2;
    window = Env.perc(att, dec, amp);
    OffsetOut.ar(out,
        Pan2.ar(
            SinOsc.ar(
                SinOsc.ar(freqFM) * fmi
                +
                freq
            ),
            pan
        ) * EnvGen.ar(window, doneAction:2)
    )
}, metadata: ( specs: ( freqFM: \freq, fmi: \lofreq.asSpec, att: [0,1], dec: [0.02,2, \lin] ) )
).add;

SynthDef("grainFM_b", { | freqFM=800, fmi = 100.5, att=0.01, dec=0.001, amp = 0.5, pan = 0, freq=800, out = 0 |
    var window, ratio=0.1;
    window = Env.perc(att, dec, amp);
    OffsetOut.ar(out,
        Pan2.ar(
            SinOsc.ar(
                SinOsc.ar(freqFM * LFNoise1.kr(0.1).range(0.8, 1.2)) * fmi
                +
                freq
            ),
            pan
        ) * EnvGen.ar(window, doneAction:2)
    )
}, metadata: ( specs: ( freqFM: \freq, fmi: \lofreq.asSpec, att: [0,1], dec: [0.02,2, \lin] ) )
).add;
);
/*****
(instrument: \grainlet, \freq: 2000, dec: 0.001).play;
(instrument: \grainFM_a, \freq: 2000, dec: 1).play;
(instrument: \grainFM_b, \freq: 2000, dec: 1).play;
******/



//////////////////////////////////////////////////////////////////////////
/// PB_UP classix Synth Defs //////////////////////////////////////////////////////////////////////////

SynthDef("hatXLine", { arg sustain=0.0001, amp=0.5, pan = 0.0, freq=8000, out = 0;
        var window = Env.new([ amp, 0.001 ], sustain, 'exp');
        OffsetOut.ar(out,
            Pan2.ar(
                ( BPF.ar(ClipNoise.ar, freq * XLine.kr(1.1, 1, sustain) , 0.1) * 8 ).softclip
                + HPF.ar(WhiteNoise.ar, 13000)
                , pan
            ) * EnvGen.ar(window, doneAction:2)
        )
}).add;
/*****
(instrument: \hatXLine, freq: rrand(2000, 12000), sustain: 0.1).play;
*****/

SynthDef("hatXLRev", { arg sustain=0.0001, amp=0.5, pan = 0.0, freq=8000, out = 0;
    var window;
    window = Env.new([ 0.001, amp ], [ sustain * 1.3 ], 'exponential');
    OffsetOut.ar(out,
        Pan2.ar(
            (
                BPF.ar(ClipNoise.ar, freq * XLine.kr(1.0, 1.2, sustain) , 0.1)
                * 7).softclip
            + HPF.ar(WhiteNoise.ar, 13000)
            , pan
        ) * EnvGen.ar(window, doneAction:2)
    )
}).add;
/*****
(instrument: \hatXLRev, freq: rrand(2000, 12000), sustain: 0.1).play;
*****/



(
// \f is a glitch factor
SynthDef(\hhat, { | dec=0.2, amp=0.1, freq=9000, out=0 |
    var o, u;
    o = Pan2.ar(Decay.kr(Trig1.kr(Impulse.kr(1/1000), 0.01), dec ).clip2(1) * BPF.ar(WhiteNoise.ar, freq, 0.2, 6), Rand(-1, 1.0));
    Line.kr(1, 0, dec*1, doneAction:2);
    OffsetOut.ar(out, o*amp);
}).add;

SynthDef(\resobas, {|out=0, dec=2, freq=50, amp=1, pan=0|
    var o = Limiter.ar(
        Ringz.ar(
            Trig1.ar(Impulse.kr(0), 0.01)*BrownNoise.ar(0.125),
            freq,
            dec, 0.15 * amp
        )
    );
    Line.kr(1, 0, dec, doneAction:2 );
    OffsetOut.ar(out, Pan2.ar(o, pan));
}, metadata: ( specs: ( dec: [0.02,2, \lin] ) ) ).add;
);
/*****
(instrument: \hhat, freq: 9000).play;
(instrument: \resobas).play;
******/
/*
a percussion SynthDef Library by Jan Kees van Kampen

modified by HH so all Synths free themselves after playing

todo: better amp scaling in synthdef, so amp arg is normalized amongst synthdefs

Synth(\bssine,[\freq, 4000, \dec, 2])
Synth(\bspulse,[\freq, 1000, \width, 0.02, \dec, 2])
Synth(\bspulse,[\freq, 250, \width, 0.1, \dec, 2])
Synth(\bsfm,[\freq, 1250, \modfreq, 1.5, \modindex, 5, \dec, 2, \amp, 0.4])
Synth(\bsfm,[\freq, 150, \modfreq, 200.5, \modindex, 10, \dec, 2, \amp, 0.3])
Synth(\bsfnoise, [\freq, 2000, \rq,0.001, \dec, 0.9, \amp, 1]);
Synth(\bsfnoise2, [\freq, 4000, \rq,0.1, \dec, 0.1, \fdec, 0.03, \amp, 3]);
Synth(\honky, [\freq, 500, \dec, 0.3, \amp, 0.3]);
Synth(\drum1, [\freq, 1500, \freqMul, 10, \dec, 0.6, \fdec, 0.3, \amp, 3]);

Synth(\ana1,[\freq, 250, \dec, 2, \amp, 0.4])
Synth(\ana2,[\freq, 250, \dec, 2, \amp, 0.4])
Synth(\fm1,[\freq, 150, \dec, 2, \amp, 0.4])
Synth(\fm2,[\freq, 150, \dec, 2, \amp, 0.4])
*/

SynthDef(\bssine,{ |dec=0.2, amp=0.9, t_trig=1, freq=440, out=0 |
    var env, snd;
    env = EnvGen.ar(Env.perc(1e-3,dec), t_trig, doneAction:2);
    snd = SinOsc.ar(freq*[1,1.01]);
    OffsetOut.ar(out, snd * env * amp);
}, metadata: ( specs: ( dec: [0.02,2, \lin] ) ) ).add;

SynthDef(\bspulse,{ | width=0.5, dec=0.1, amp=0.6, pan=0, t_trig=1, freq=200, out=0 |
    var env, snd;
    env = EnvGen.ar(Env.perc(1e-2,dec), t_trig, doneAction:2);
    snd = Pulse.ar(freq, width);
    OffsetOut.ar(out, Pan2.ar(snd * env * amp * 0.5));
}, metadata: ( specs: ( width: [0,1], dec: [0.02,2] ) ) ).add;

SynthDef(\bsfm, {| modfreq=100, modindex=1, dec=0.2, amp=0.3, freq=1000, t_trig=1, out=0 |
    var snd, env = EnvGen.ar(Env.perc(0.01, dec ), t_trig, doneAction:2);
    snd = PMOsc.ar(freq, modfreq, modindex,SinOsc.kr(0.3,[0, 1],pi));
    OffsetOut.ar(out, snd * env * amp);
}, metadata: ( specs: ( modfreq: [1,100,\exp], modindex: [1,100,\exp], dec: [0.01,1] ) ) ).add;

SynthDef(\bsfnoise, {| rq=0.1, pan=0, dec=0.2, amp=0.3, t_trig=1, freq=1000, out=0 |
    var snd, env = EnvGen.ar(Env.perc(0.001, dec ), t_trig, doneAction:2);
    snd = BPF.ar(WhiteNoise.ar(4), freq, rq); // freq is filter cutoff frequency here, rq is the reciprocal of q (bandwith of filter)
    OffsetOut.ar(out, Pan2.ar(snd * env * amp, pan));
}, metadata: ( specs: ( dec: [0.01,1] ) ) ).add;

SynthDef(\bsfnoise2, {| rq=0.1, dec=0.2, fdecay=0.04, amp=0.3, pan=0, t_trig=1, freq=1000, out=0 |
    var snd, fenv, env = EnvGen.ar(Env.perc(0.001, dec ), t_trig, doneAction:2);
    fenv = EnvGen.ar(Env.perc(1e-5, fdecay, curve:-4), t_trig, doneAction:0);
    snd = BPF.ar(WhiteNoise.ar(4), freq*(1+fenv), rq); // freq is filter cutoff frequency here, rq is the reciprocal of q (bandwith of filter)
    OffsetOut.ar(out, Pan2.ar(snd * env * amp, pan));
}, metadata: ( specs: ( fdecay: [0.01,1,\exp], dec: [0.01,1] ) ) ).add;

SynthDef(\honky,{ | dec=0.1, amp=0.9, pan=0, t_trig=1, freq, out=0 |
    var snd = SinOsc.ar(freq).cubed.cubed;
    var env = EnvGen.ar(Env.perc(1e-3,dec), t_trig, doneAction:2);
    OffsetOut.ar(out, Pan2.ar(snd * amp * env, pan));
}, metadata: ( specs: ( dec: [0.01,1] ) ) ).add;

SynthDef(\drum1, {| freqMul=4,  fdecay=0.02, rq=0.2, dec=0.1,amp=0.7, pan=0, t_trig=1, freq, out=0 |
    var snd, fenv, env = EnvGen.ar(Env.perc(1e-5, dec, curve:-8), t_trig, doneAction:2);
    fenv = EnvGen.ar(Env.perc(1e-5, fdecay, curve:-4), t_trig, doneAction:0);
    snd = BPF.ar( WhiteNoise.ar(10), freq * freqMul * fenv + 100, rq);
    OffsetOut.ar(out, Pan2.ar(snd.softclip * amp * env, pan));
}, metadata: ( specs: ( freqMul: [0.5,2,\exp], fdecay: [0.01,1], dec: [0.01,1] ) ) ).add;

SynthDef(\drum2, {| freqMul=4, ffreq=1000, rq=0.3, dec=0.1, amp=0.4, pan=0, t_trig=1, freq, out=0 |
    var snd, env = EnvGen.ar(Env.perc(1e-9, dec, curve:-8), t_trig, doneAction:2);
    snd = BPF.ar( WhiteNoise.ar(10), freq * freqMul + 100, rq)
    + SinOsc.ar(freq/2)!2;
    OffsetOut.ar(out, Pan2.ar(LPF.ar(snd, ffreq, amp * env * 0.5), pan));
}, metadata: ( specs: ( freqMul: [0.5,2,\exp], ffreq: \freq, dec: [0.01,1] ) ) ).add;


SynthDef(\ana1, {| pwidth=0.2, pdecay=0.07, dec=0.3, ffreq=700, rq=0.3, amp=0.3, t_trig=1, freq=100, out=0 |
    var aenv, penv, osc1, osc2, filtd, pfreq, sfreq;
    aenv = EnvGen.ar(Env.perc(0.01, rrand(dec/2,dec*2)), t_trig, doneAction: 2);
    penv = 1 + EnvGen.ar( Env.perc(0.01, pdecay), t_trig, timeScale:0.2, levelScale:-0.1, doneAction: 0);
    pwidth = pwidth * SinOsc.kr(0.1, [0, pi], 0.24, 0.25);
    sfreq = freq;
    pfreq = freq * SinOsc.kr([0.5, 1.333],0,0.01,1);
    osc1 = VarSaw.ar(sfreq*penv,0,pwidth);
    osc2 = LFPulse.ar( ( pfreq ? sfreq ) * penv, 0, pwidth );
    filtd = RLPF.ar(Mix([osc1, osc2]), ffreq, rq);
    OffsetOut.ar(out, filtd * aenv * amp * 0.7)
}, metadata: ( specs: ( pwidth: [0,1], pdecay: [0.1,1], dec: [0.01,1], ffreq: \freq ) ) ).add;

SynthDef(\ana2, {| pwidth=0.2, dec=0.3, pdecay=0.07, ffreq=700, rq=0.3, amp=0.4, t_trig=1, freq=100, out=0 |
    var aenv, penv, osc1, osc2, filtd, pfreq, sfreq;
    aenv = EnvGen.ar(Env.perc(0.01, rrand(0.02,dec)), t_trig, doneAction:  2);
    penv = 1 + EnvGen.ar(Env.perc(0.01, pdecay), t_trig, timeScale:0.2, levelScale:-0.1, doneAction: 0);
    pwidth = pwidth * SinOsc.kr(0.1, [0, pi], 0.24, 0.25);
    sfreq = freq  * TChoose.kr(t_trig, [1.5, 1.0, 0.5, 2]);
    pfreq = freq * SinOsc.kr([0.5, 1.333],0,0.01,1) * TChoose.kr(t_trig, [1.5, 1.0, 0.5, 2]);
    osc1 = VarSaw.ar(sfreq*penv,0,pwidth);
    osc2 = LFPulse.ar((pfreq?sfreq)*penv,0,pwidth);
    filtd = RLPF.ar(Mix([osc1, osc2]), ffreq, rq);
    OffsetOut.ar(out, filtd * aenv * amp * 0.5)
}, metadata: ( specs: ( pwidth: [0,1], pdecay: [0.1,1], dec: [0.01,1], ffreq: \freq ) ) ).add;


SynthDef(\fm1, {| dec=0.3, amp=0.2, t_trig=1, freq=1040, out=0 |
    var snd, env = EnvGen.ar(Env.perc(0.01, freq.reciprocal * 200 * dec ), t_trig, doneAction: 2);
    snd = PMOsc.ar(freq, freq*0.5, 2*TExpRand.kr(0.5, 4, t_trig),SinOsc.kr(0.3,[0,1],pi));
    OffsetOut.ar(out, snd * env * amp);
}).add;


SynthDef(\fm2, {| dec=0.09, amp=0.6, t_trig=1, freq=1040, out=0 |
    var snd, env = EnvGen.ar(Env.perc(0.01,dec*LFNoise2.kr(0.1,0.1,1)), t_trig, doneAction: 2);
    snd = RLPF.ar(
        PMOsc.ar(freq, freq * IRand(2,4)/2, TRand.kr(0.5, 3, t_trig),0),
        SinOsc.kr([0.1, 0.11]).range(400, 1900),
        0.4
    );
    OffsetOut.ar(out, snd * env * amp);
}).add;

SynthDef(\sine, { arg att=0.01, dec=1, amp=1, pan, freq, out ;
    var snd, env, u=1;
    env = EnvGen.kr(Env.perc(att, dec), 1, doneAction:2);
    snd = SinOsc.ar(freq, 0, amp * env);
    OffsetOut.ar(out, Pan2.ar(snd, pan));
}, metadata: ( specs: ( att: [0.02,1], dec: [0.01,1] ) ) ).add;

SynthDef(\pmosc, { arg dec=1, amp=1, pan=0.5, freq, out;
    var env, u=1;
    env = EnvGen.kr(Env.perc(0.01, dec), 1, timeScale: \sustain.kr(1), doneAction:2);
    5.do { var d; d = exprand(0.01, 1); u = SinOsc.ar(d * 300, u, rrand(0.1,1.2) * d, 1) };
    OffsetOut.ar(out, Pan2.ar(SinOsc.ar(u + 1 * freq, 0, amp * env), pan));
}).add;

SynthDef(\saw,{ arg ffMul=0, att=0.01, dec=1, amp=1, pan, freq, out;
    var snd, env, u=1;
    env = EnvGen.kr(Env.perc(att, dec), 1, doneAction:2);
    snd = LPF.ar(LFSaw.ar(freq, 0, amp * env), freq*(ffMul+1));
    OffsetOut.ar(out, Pan2.ar(snd, pan));
}).add;

SynthDef(\drum3, { | freqMul=4, fdecay=0.02, dec=0.1, rq=0.2, amp=0.7, t_trig=1, freq, out=0 |
    var snd, fenv, env = EnvGen.ar(Env.perc(1e-5, dec, curve:-8), t_trig);
    fenv = EnvGen.ar(Env.perc(1e-5, fdecay, curve:-4), t_trig, doneAction:2);
    snd = BPF.ar( GrayNoise.ar(10) ! 2, freq * freqMul * fenv + 100, rq);
    snd = snd + SinOsc.ar(Rand(300,10080),0,fenv);
    OffsetOut.ar(out, snd.softclip * amp * env);
}).add;

//////////////////////// E.o. JKvK lib /////////////////////////////////

SynthDef("fbBass", { arg fb=1, pan = 0.5, amp=0.5, freq=50, sustain=1, out = 0;
    var window;
    var fbl = Line.kr(0.1, fb, sustain);
    window = Env.perc(0.001, 1, amp, -2);
    OffsetOut.ar(out,
        Pan2.ar(
            SinOscFB.ar(freq, fbl),
            pan
        ) * EnvGen.ar(window, timeScale: sustain, doneAction:2)
    )
}
).add;


/*SynthDef(\fooA, {| dur = 1, amp = 0.1, freq = 440 |
    OffsetOut.ar(0, SinOsc.ar(freq, 0, amp) * Env.perc(0.001, dur).kr(2));
}).add;*/

////////////////////////////////////////////////////////////////////////

(
q.printSParams = {(SynthDescLib.global.synthDescs.keys - q.origSynthDefs).asArray.reject {|it| it.asString.beginsWith("syst") }.sort.keysValuesDo { |key|
    var desc = SynthDescLib.match(key).controls;
    postf("% ->", key);
    desc.do { |ctr|
        if (ctr.name != \out) {
            postf(", % %", ctr.name, ctr.defaultValue.round(0.01));
        }
    };
    ".\n".postln;
};
'';
};
q.printSParams;
);


q.paramNames = ();

SynthDescLib.global.synthDescs.keysValuesDo { |key, desc|
    var dict = ();
    desc.controls.do { |cont|
        if (cont.name != \out) {
            dict.put(cont.name, cont.defaultValue);
        }
    };
    q.paramNames.put(key, dict);
};


(
q.printSdefs = {
    var synths = (SynthDescLib.global.synthDescs.keys - q.origSynthDefs).asArray.reject {|it| it.asString.beginsWith("syst") }.sort;
    synths.do { |key, i|
        key.postln;
    };
    '';
};
q.printSdefs;
);

q.synthDefs = (SynthDescLib.global.synthDescs.keys - q.origSynthDefs).asArray.reject {|it| it.asString.beginsWith("syst") }.sort;

q.tonalDefs = q.paramNames.select{|v| v.keys.includes(\freq) }.keys(SortedList);

postf("\n*** SynthDef Library loaded with % Synths *** \naccess them with \nq.printSdefs;\n\n", q.synthDefs.size);
// postf("\n*** % SynthDefs have a freq input: *** \naccess them with \nq.tonalDefs;\n\n", q.tonalDefs.size);
'';


// q.synthDefs.printcsAll;

postf("\n*** SynthDef Library loaded with % Synths *** access them with \nq.synthDefs;\n\n", q.synthDefs.size);
postf("\n*** % SynthDefs have a freq input: *** access them with \nq.tonalDefs;\n\n", q.tonalDefs.size);

Spec.add(\sustain, [0.04,4]);




