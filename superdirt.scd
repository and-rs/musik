(
s.reboot {
		s.options.numBuffers = 1024 * 256;
		s.options.memSize = 8192 * 32; // 256 MB
		s.options.numWireBufs = 2048;
		s.options.maxNodes = 1024 * 32;
		s.options.numOutputBusChannels = 2;
		s.options.numInputBusChannels = 2;

		s.waitForBoot {
				~dirt = SuperDirt(2, s);
				~dirt.loadSoundFiles;
				~dirt.start(57120, 0 ! 12);
		};

		SynthDef(\dasnare, {
				|out, sustain=0.2, freq=420, pan=0, drive=1.5, noise=0.8, rev=0.8|
				var toneEnv = EnvGen.ar(Env.perc(0.0005, 0.05, curve: -6));
				var noiseEnv = EnvGen.ar(Env.perc(0.001, sustain, curve: -4));
				var life = Line.kr(0, 1, sustain + 1.5, doneAction: 2);
				var tone = SinOsc.ar(XLine.kr(freq * 1.5, freq, 0.01)) * toneEnv;
				var verb = FreeVerb.ar(tone, 1, 0.7, 0.5) * rev;
				var tail = HPF.ar(WhiteNoise.ar, 1500) * noiseEnv * noise;
				var sig = ((tone + verb + tail) * drive).tanh * 0.8;
				OffsetOut.ar(out, DirtPan.ar(sig, ~dirt.numChannels, pan, 1));
		}).add;

		SynthDef(\mykick, {
				|out, sustain=0.10, freq=44, pan=0, drive=1.0, click=0.18|
				var env = EnvGen.ar(Env.perc(0.001, sustain, curve: -1), doneAction: 2);
				var pitch = XLine.kr(freq * 20, freq, 0.015);
				var body = SinOsc.ar(pitch) * env;
				var clickEnv = EnvGen.ar(Env.perc(0.0001, 0.008, curve: 2));
				var transient = HPF.ar(WhiteNoise.ar, 2000) * clickEnv * click;
				var sig = ((body + transient) * drive).tanh * 0.9;
				OffsetOut.ar(out, DirtPan.ar(sig, ~dirt.numChannels, pan, 1));
		}).add;

};
)
