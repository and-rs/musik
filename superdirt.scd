(
s.reboot {
		var renderPath = "RENDER_PATH".getenv;
		var renderSeconds = "RENDER_SECONDS".getenv;

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
				s.sync;
				~dirt.start(57120, 0 ! 12);
				if (renderPath.notNil and: { renderSeconds.notNil }) {
					s.record(renderPath, duration: renderSeconds.asFloat);
					"RENDER_READY".postln;
					Routine {
						(renderSeconds.asFloat + 1).wait;
						s.quit;
						1.wait;
						0.exit;
					}.play;
				};
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
			|out, freq=50, sustain=0.2, pan=0|
			var env = EnvGen.ar(Env.perc(0.001, sustain), doneAction: 2);
			var body = SinOsc.ar(XLine.kr(freq * 4, freq, 0.03)) * env;
			OffsetOut.ar(out, DirtPan.ar(body, ~dirt.numChannels, pan, 1));
		}).add;

		SynthDef(\soft, {
			|out, freq=220, sustain=0.25, pan=0|
			var env = EnvGen.ar(Env.perc(0.01, sustain, curve: -4), doneAction: 2);
			var tone = (SinOsc.ar(freq) * 0.8) + (LFTri.ar(freq) * 0.3);
			var sig = LPF.ar(tone, 1800) * env * 0.5;
			OffsetOut.ar(out, DirtPan.ar(sig, ~dirt.numChannels, pan, 1));
		}).add;

};
)
