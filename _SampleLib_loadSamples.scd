(
fork{
    var paths = "Samples/*".resolveRelative;
    var folderPaths;
    b = ();
    b.family = ();
    q.sampleFamilyFolders = ();
    q.samples = [];
    paths = paths ?? { "Samples/*".resolveRelative };
    folderPaths = if(paths.isString) { paths.pathMatch } { paths.asArray };
    folderPaths = folderPaths.select(_.endsWith(Platform.pathSeparator.asString));
    q.sampleFamilyFolders = folderPaths;
    wait(0.005);

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

    wait(0.005);
    fork {
        folderPaths.do { |family|
            b[family.basename.asSymbol] = ();
            b.family[family.basename.asSymbol] = ();
            0.0025.wait;
            (family +/+ "*").pathMatch.do { |pa|
                if ( File.type(pa) == \directory )
                {
                    b[family.basename.asSymbol][pa.basename.asSymbol] = q.loadSamples(pa);
                    0.0025.wait;
                    s.sync;
                    b[pa.basename.asSymbol] = shallowCopy(b[family.basename.asSymbol][pa.basename.asSymbol]);
                    0.0025.wait;
                    s.sync;
                    b.family[family.basename.asSymbol][pa.basename.asSymbol] = shallowCopy(b[pa.basename.asSymbol]);
                    0.0025.wait;
                    s.sync;
                    q.samples.add(pa);
                    SynthDef(pa.basename.asSymbol, { | out, buf = 0, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, gate=1, degree = 0, amp=0.5 |

                        var sound;

                        var sampleFolder = b[pa.basename.asSymbol];
                        var bufnum = Select.kr( buf.fold(0,sampleFolder.size-1), sampleFolder );
                        var numChannels = bufnum.numChannels;
                        // playback speed
                        var rate = XLine.kr( speed.abs, endSpeed.abs, sustain * absdif(begin, end),
                            (freq / 60.midicps),
                            doneAction:Done.freeSelf
                        );
                        var numFrames = max( BufFrames.kr( bufnum ), 1 ); // make sure it is > 0, when no file is read yet
                        var sawrate = BufDur.ir(bufnum) * absdif(begin, end);

                        var phase =  Sweep.ar( gate, rate * BufSampleRate.kr(bufnum) ) + ( numFrames * begin );

                        sound = BufRd.ar(
                            numChannels: sampleFolder[0].numChannels,
                            bufnum: bufnum,
                            phase: phase,
                            loop: 0,
                            interpolation: 4 // cubic interpolation
                        );
                        sound = PanAz.ar(
        numChans:s.options.numOutputBusChannels,
        in: sound,
    );
    sound = Balance2.ar(sound[0], sound[1], pan, amp);
                        OffsetOut.ar(out, sound)
                    }).add;
                }
            };
        };
    };
    28.wait;
    fork{32.do{|i| b.snare.choose.play; (1/(i+1)).wait};b.rie[0].play};

/*(
        b.keys.do{ |k|
            postf("% : % ------\n", k.toUpper, b[k.asSymbol].size );

            // if (
            b[k.asSymbol].class.postln;
                // == Array) {
            // b[k.asSymbol].keys.postln;
            // }
    };
    ''.postln;
    )*/
}
)
/*
(
SynthDef(\clas11m21, { | out, buf = 0, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, gate=1, degree = 0, amp = 0.5 |

    var sound;

    var sampleFolder = b.clas11m21;
    var bufnum = Select.kr( buf.fold(0,sampleFolder.size-1), sampleFolder );
    var numChannels = bufnum.numChannels;
    // playback speed
    var rate = XLine.kr( speed.abs, endSpeed.abs, sustain * absdif(begin, end),
        (freq / 60.midicps),
        doneAction:Done.freeSelf
    );
    var numFrames = max( BufFrames.kr( bufnum ), 1 ); // make sure it is > 0, when no file is read yet
    var sawrate = BufDur.ir(bufnum) * absdif(begin, end);

    var phase =  Sweep.ar( gate, rate * BufSampleRate.kr(bufnum) ) + ( numFrames * begin );

    sound = BufRd.ar(
        numChannels: b.clas11m21[0].numChannels,
        bufnum: bufnum,
        phase: phase,
        loop: 0,
        interpolation: 4 // cubic interpolation
    );
    sound = PanAz.ar(
        numChans:s.options.numOutputBusChannels,
        in: sound,
    );
    sound = Balance2.ar(sound[0], sound[1], pan, amp);
    // sound = SplayAz.ar(numChans: 2, inArray: sound, spread: 1, level: 1, width: 2, center: 0.0, orientation: 0.5, levelComp: true);
    OffsetOut.ar(out, sound)
}).add;
)
*/
