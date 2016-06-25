//Spreading Frequency Bands over a number of Speakers. developed for the “Creative Music Innovations in Spatial Sound Sphere”-Workshop in the Music Innovation Studies Centre Vilnius (LT)

(SynthDef(\bpf,
	{
		arg low, high, outChan = 0, inChan = 2, amp;
		var in, chainA, lowpass, chainB, bandpass, out, sub, top;
		in = SoundIn.ar(inChan);
		//in = SinOsc.ar(SinOsc.kr(0.1).range(10, 10000), mul:0.4);
		//in = WhiteNoise.ar(0.4);
		//in = BPF.ar(PinkNoise.ar(0.4), SinOsc.kr(0.1).range(10, 10000), 0.3);
		//in = Silence.new;
		chainA = FFT(LocalBuf(1024), in);
		chainA = PV_BrickWall(chainA,  SampleDur.ir * (low*2));
		lowpass = IFFT(chainA);
		chainB = FFT(LocalBuf(1024), lowpass);
		chainB = PV_BrickWall(chainB, (SampleDur.ir * ((high*2))) - 1);
		sub = LPF.ar(in, 200);
		top = HPF.ar(in, 12000);
		bandpass = IFFT(chainB);
		out = bandpass*amp;
		out = out+(sub*0.0625)+(top*0.0625);
		Out.ar(outChan, out);
	}
).add;
)

~low=[0,200,300,400,510,630,770,920,1080,1270,1480,1720,2000,2320,2700,3150,3700,4400,5300,6400,7700,9500,12000];
~high=[200,300,400,510,630,770,920,1080,1270,1480,1720,2000,2320,2700,3150,3700,4400,5300,6400,7700,9500,12000,20000];


(23.do(//23 output channels
	{
		arg i;
		Synth(\bpf, [\low, ~low.at(i), \high, ~high.at(i), \outChan, i%23, \inChan, 1, \amp, 1]);
	};
))
Status API Training Shop Blog About
