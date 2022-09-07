
Tdef(\sambAll, {
inf.do {
q.samba.scramble.do { |buf, i|
var rate = [1, 1.25, 1.5, 0.75, 0.5].choose;
(instrument: \simpsamp, buf: buf, rate: rate, amp: 1).play;
(buf.duration / rate).wait;
} }
}).play;

q=q?();


// Sample Players SynthDefs

//  -----------------------------------------------------------
//  -----------------------------------------------------------
//  -----------------------------------------------------------
// MONO SynthDefs //-------------------------------------------



// synthdef to play a buffer. start: in seconds.
SynthDef(\simpsamp_m, { |out, buf, amp=0.1, rate = 1, pan=0, start|
    var snd = PlayBuf.ar(1,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, Pan2.ar(snd, pan, amp));
}).add;

SynthDef(\simpsamp, { |out, buf, amp=0.1, rate = 1, pan=0, start|
    var snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, Pan2.ar(snd, pan, amp));
}).add;
(
SynthDef(\sampGrain, { |out, buf, amp=0.1, rate = 1, stretch=1, pan=0, ovlp = 6, trigrate=33, jitter=0.01|
    var bdur = BufDur.ir(buf);
    var trig = Dust.ar(trigrate);
    var pos  = Line.ar(0, bdur, bdur * stretch, doneAction: 2) + TRand.ar(jitter.neg, jitter, trig).madd(bdur);
    var snd  = TGrains.ar(2, trig, buf, rate, pos, trigrate.reciprocal*ovlp, pan, amp );
    OffsetOut.ar(out, snd);
}).add;
);
/*
(instrument: \sampGrain, buf: 134, amp: 1, rate: 1/1.2, stretch: 1.0, ovlp: 8).play; // grainy stretchhhhhh
*/
SynthDef(\simpsampGlitch, { |out, buf, amp=0.1, rate = 1, pan=0, start|
    var snd, blendMess = Line.kr(-2,2, BufDur.ir(buf)).clip(0, 1);

    rate = rate * blend(1, LFNoise1.kr(Rand(2, 30), 5, 1).clip2(1), blendMess);
    snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, Pan2.ar(snd, pan, amp));
}).add;

// synthdef to play a section from a buffer. start/end in seconds
SynthDef(\sampEnv, { |out, buf, amp=0.1, rate = 1, pan, start, sustain=0.8, fade=0.01|
    var fadeTime = min(fade, BufDur.ir(buf)/3);
    var snd = PlayBuf.ar(1,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2
    );
    var env = EnvGen.ar(Env.linen(fadeTime, sustain, fadeTime), doneAction: 2);
    OffsetOut.ar(out, Pan2.ar(snd * env, pan, amp))
}).add;

// Stereo SynthDefs //--------------------------------------
SynthDef(\simpsamp, { |out, buf, amp=0.1, rate = 1, start|
    var snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, snd * amp);
}).add;

SynthDef(\sampEnv_st, { |out, buf, amp=0.1, rate = 1, start, sustain=0.8, fade=0.01|
    var fadeTime = min(fade, BufDur.ir(buf)/3);
    var snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2
    );
    var env = EnvGen.ar(Env.linen(fadeTime, sustain, fadeTime), doneAction: 2);
    OffsetOut.ar(out, snd * env * amp)
}).add;

(
SynthDef(\samp_s, { |out, bufnum = 0, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, numChan = 2|

    var sound, rate, phase, sawrate, numFrames = 1, numChans = 2, chans;

    // playback speed
    rate = Line.kr(speed, endSpeed, sustain) * (freq / 60.midicps);

    // sample phase
    // BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard

    numFrames = max(BufFrames.ir(bufnum), 1); // make sure it is > 0, when no file is read yet
    sawrate = rate * BufSampleRate.ir(bufnum) / (absdif(begin, end) * numFrames);
    phase = (speed.sign * LFSaw.ar(sawrate, 1)).range(begin, end) * numFrames;

    //phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);
    sound = BufRd.ar(
        numChannels: bufnum.numChannels,
        bufnum: bufnum,
        phase: phase,
        loop: 0,
        interpolation: 4 // cubic interpolation
    );

    sound = PanAz.ar(
        numChans: s.options.numOutputBusChannels,
        in: DC.ar(0!2),
        pos: pan,
        level: 0.5,
        width: 3,
        orientation: 0.5
    );
    OffsetOut.ar(out, sound)
}).add;
);

q.bufDefs = [\simpsamp, \sampGrain, \simpsampGlitch, \sampEnv];

/// e.o. SynthDefs -----------------------------------------------------------
//  -----------------------------------------------------------
//  -----------------------------------------------------------
//  -----------------------------------------------------------

// sound file load mechanism
// have all the samples stored in this Dir !!
// q.mainSampDir = (thisProcess.nowExecutingPath.dirname.dirname +/+ "Samples*").pathMatch.first.postcln;


(
var paths = "Samples/*".resolveRelative;
var folderPaths;
b = ();
b.family = ();
q.sampleFamilyFolders = ();
paths = paths ?? { "Samples/*".resolveRelative };
folderPaths = if(paths.isString) { paths.pathMatch } { paths.asArray };
folderPaths = folderPaths.select(_.endsWith(Platform.pathSeparator.asString));
q.sampleFamilyFolders = folderPaths;

q.loadSamples = { |q, dir, mainDir|

	var myDir = if(dir.contains("/") and: {mainDir.isNil} ){dir} { (mainDir ? q.mainSampDir) +/+ dir};
	var myPaths = (myDir +/+ "*").postcln.pathMatch;
	var mySFs = myPaths.collect{|p|
		var sf = SoundFile.openRead(p); // test if SoundFile Class can handle it - regardless of file name ext !
		if(sf.notNil){
			// load'em!
			var pa = sf.path;
			sf.close;
			pa
		};
	}.select( _.notNil );

	var returnArray = [];
	postf("\n\n>>>>> about to load the following % files: \n\n", mySFs.size);
	mySFs.collect{|f|f.basename}.printAll;

	if(s.serverRunning){
		if(mySFs.notEmpty){
			returnArray = mySFs.collect{|p|
				Buffer.readChannel(s, p, action: {|buf|
					buf.normalize;
					//.add(buf)
				});
			};
		}{
			"sorry, no sound files in folder \"%\"!".format(myDir).warn;
		};

	}{ "\n\noy, Server not running! please run s.boot; first!\n".warn;  };
	// "\n\n".postln;
	returnArray
};

fork {
    folderPaths.do { |family|
        b[family.basename.asSymbol] = ();
        b.family[family.basename.asSymbol] = ();
        0.2.wait;
        (family +/+ "*").pathMatch.do { |pa|
            if ( File.type(pa) == \directory )
            {
                b[family.basename.asSymbol][pa.basename.asSymbol] = q.loadSamples(pa);
                0.2.wait;
                s.sync;
                b[pa.basename.asSymbol] = shallowCopy(b[family.basename.asSymbol][pa.basename.asSymbol]);
                0.1.wait;
                s.sync;
                b.family[family.basename.asSymbol][pa.basename.asSymbol] = shallowCopy(b[pa.basename.asSymbol]);
                0.1.wait;
                s.sync;
                SynthDef(pa.basename.asSymbol, { |out, buf = 0, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, gate=1, degree = 0|

                    var numChannels = bufnum.numChannels;
                    var sampleFolder = b[pa.basename.asSymbol];
                    var bufnum = Select.kr(buf, sampleFolder);
                    // playback speed
                    var rate = XLine.kr( speed.abs, endSpeed.abs, sustain * absdif(begin, end),
                        (freq / 60.midicps),
                        doneAction:Done.freeSelf
                    );
                    var numFrames = max( BufFrames.kr( bufnum ), 1 ); // make sure it is > 0, when no file is read yet
                    var sawrate = BufDur.ir(bufnum) * absdif(begin, end);

                    var phase =  Sweep.ar( gate, rate * BufSampleRate.kr(bufnum) ) + ( numFrames * begin );
                    var sound = BufRd.ar(
                        numChannels: numChannels,
                        bufnum: bufnum,
                        phase: phase,
                        loop: 0,
                        interpolation: 4 // cubic interpolation
                    );
                    sound = PanAz.ar(
                        numChans: s.options.numOutputBusChannels,
                        in: sound,
                        pos: pan,
                        level: 0.5,
                        width: 2,
                        orientation: 0.5
                    );
                    OffsetOut.ar(out, sound)
                }).add;
            }
        };
    };
};
);
b.tr808.cl8[0].play;
/*(
SynthDef(\berimbau, { |out, buf = 0, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, numChan = 2, gate=1, degree = 0|

    var sound, rate, phase, sawrate, numFrames = 1, numChans = 2, chans = 1, sampleFolder, bufnum, env;

    sampleFolder = b.berimbau;
    bufnum = Select.kr(buf, sampleFolder);
    // playback speed
    rate = XLine.kr( speed.abs, endSpeed.abs, sustain * absdif(begin, end),
        (freq / 60.midicps),
        doneAction:Done.freeSelf
    );
    chans = bufnum.numChannels;

    numFrames = max( BufFrames.kr( bufnum ), 1 ); // make sure it is > 0, when no file is read yet

    sawrate = BufDur.ir(bufnum) * absdif(begin, end);

    phase =  Sweep.ar( gate, rate * BufSampleRate.kr(bufnum) ) + ( numFrames * begin );

    sound = BufRd.ar(
        numChannels: bufnum.numChannels,
        bufnum: bufnum,
        phase: phase,
        loop: 0,
        interpolation: 4 // cubic interpolation
    );

    sound = PanAz.ar(
        numChans: s.options.numOutputBusChannels,
        in: sound,
        pos: pan,
        level: 0.5,
        width: 2,
        orientation: 0.5
    );
    OffsetOut.ar(out, sound)
}).add;
)*/