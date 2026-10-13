(
s.reboot {
		s.options.numBuffers = 1024 * 256;
		s.options.memSize = 8192 * 32; // 256 MB
		s.options.numWireBufs = 2048;
		s.options.maxNodes = 1024 * 32;
		s.options.numOutputBusChannels = 2;
		s.options.numInputBusChannels = 2;

		s.waitForBoot {
				s.sync;
				~dirt = SuperDirt(2, s);
				~dirt.loadSoundFiles;
				~dirt.start(57120, 0 ! 12);
				~dirt.orbits[0].globalEffects = ~dirt.orbits[0].globalEffects.insert(
						~dirt.orbits[0].globalEffects.size - 1,
						GlobalDirtEffect(\glue, [\glue]).alwaysRun_(true)
				);
				~dirt.orbits[0].initNodeTree;
				~dirt.orbits[0].set(\glue, 1);
		};

		SynthDef("glue2", {
				|dryBus, gate=1, glue=0, pauseImmediately=0, dirt_resumed=0|
				var amt = glue.clip(0, 1);
				var sig = In.ar(dryBus, 2);
				var link = (sig[0] + sig[1]) * 0.5 ! 2;

				// TWEAK: compressor. At full glue: threshold 0.20, slopeAbove 1/6 (~6:1).
				var threshold = 0.5 - (amt * 0.3); // Lower baseline / raise 0.3 for more compression.
				var slopeAbove = 1 / (1 + (amt * 8)); // Raise 5 for a stronger ratio at full glue.
				var attack = 0.01; // Seconds; higher is slower.
				var release = 0.22; // Seconds; higher lets compression recover more slowly.

				// TWEAK: output level and color.
				var makeupGain = 1 + (amt * 2); // 1x to 3x; raise 2 for more level into saturation.
				var saturationDrive = 2.0; // Raise for more saturation before tanh.
				var limiterLevel = 0.9; // Peak ceiling.
				var limiterDur = 0.01; // Limiter lookahead, in seconds.

				var comp = Compander.ar(sig, link, threshold, 1, slopeAbove, attack, release);
				var wet = Limiter.ar((comp * makeupGain * saturationDrive).tanh, limiterLevel, limiterDur);
				var out = XFade2.ar(sig, wet, (amt * 2) - 1);
				ReplaceOut.ar(dryBus, out * EnvGen.kr(Env.asr(0, 1, 0.2), gate, doneAction: 2));
		}).add;

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

		SynthDef(\my808, {
				|out, freq=65, pan=0, n=0|
				var k = n.clip(0, 6);
				var atk = Select.kr(k, [0.01, 0.01, 0.005, 0.002, 0.03, 0.001, 0.005]);
				var dec = Select.kr(k, [1.5, 1.2, 1.2, 0.35, 2.5, 0.5, 1.0]);
				var drop = Select.kr(k, [1, 1, 1.5, 2, 1, 4, 1.5]);
				var env = EnvGen.ar(Env.perc(atk, dec, curve: -3), doneAction: 2);
				var sine = SinOsc.ar(XLine.kr(freq * drop, freq, 0.03));
				var click = BPF.ar(WhiteNoise.ar, 2000, 0.5) * EnvGen.ar(Env.perc(0.0005, 0.01)) * 0.3;
				var sig = Select.ar(k, [
						sine,
						(sine * 3).tanh,
						sine + (HPF.ar((sine * 4).tanh, 100) * 0.5),
						(sine * 2).tanh,
						(sine * 1.5).tanh,
						(sine * 2).tanh + click,
						LPF.ar((sine * 10).clip2(0.6), 3000)
				]);
				OffsetOut.ar(out, DirtPan.ar(sig * env * 0.9, ~dirt.numChannels, pan, 1));
		}).add;

		SynthDef(\mykick, {
				|out, sustain=0.24, freq=44, pan=0, drive=1.0, click=0.4|
				var env = EnvGen.ar(Env.perc(0.001, sustain, curve: -4), doneAction: 2);
				var body = SinOsc.ar(XLine.kr(freq * 8, freq, 0.02)) * env;
				var transient = HPF.ar(WhiteNoise.ar, 3000) * EnvGen.ar(Env.perc(0.0005, 0.012)) * click;
				var sig = ((body + transient) * drive).tanh * 0.9;
				OffsetOut.ar(out, DirtPan.ar(sig, ~dirt.numChannels, pan, 1));
		}).add;

};
)
