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
};

SynthDef(\mykick, {
   |out, sustain=0.35, freq=55, pan=0|
   var env = EnvGen.ar(Env.perc(0.001, sustain, curve: -5), doneAction: 2);
   var pitch = XLine.kr(freq * 8, freq, 0.06);
   var sig = SinOsc.ar(pitch) * env;
   OffsetOut.ar(out, DirtPan.ar(sig, ~dirt.numChannels, pan, 1));
}).add;
)
