// https://scsynth.org/t/sound-design-recipies-coming-from-the-inside-kind-of-sound/7000
(
SynthDef(\tony, {    //after your very Shining-esque description :)
	|out|
	var trig = Dust.kr(7);
	var fFreq = Demand.kr(trig, 0, Dwhite(20,2000));
	var sig = PinkNoise.ar(0.3);
	var env = Env.perc(0.001, 0.01).ar(0,trig);
	sig = BPF.ar(sig, fFreq, 0.3, env);
	Out.ar(out, sig);
}).add;
)
