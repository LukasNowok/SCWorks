//instrument for stochastic resynthesis

(
~par_text_frame = {//use on frame data format
	arg filePath, time;
	var file, freq = List.new, ratio = List.new, amp = List.new, data, line;

	file = FileReader.read(filePath);
	line = (time*100)+5;
	data = file.at(line);
	data.removeAt(0);
	data.removeAt(1);

	data.do
	({
		arg element, index;
		if(index%3 == 1)
		{
			freq.add(element.asFloat);
		};
		if(index%3 == 2)
		{
			amp.add(element.asFloat);
		};
	});

	freq.do
	({
		arg element, index;
		ratio.add(element/freq.at(0));
	});

	[freq.asArray, ratio.asArray, amp.asArray];
};
//[frequencies, ratios, amplitudes] of all analysis files in the folder (path)
p = "/Users/.../*.txt".pathMatch.collect(//folder with spear analysis files
	{
		arg path, i;
		~par_text_frame.value(path.asString, 0.5);
	};
);

///load audiofiles into buffers/ram starting from bufnum 0
"/Users/.../*.wav".pathMatch.collect(
	{
		arg path, i;
		Buffer.readChannel(s, path, bufnum: i, channels: 0);
	}
);

SynthDef(\zither,
	{
		arg buf, out = 0, rate = 1, rateScale, start = 0, amp = 0.1, group = 0, element;
		var sig, playhead, messageTrigger, bufLength;
		bufLength = BufFrames.kr(buf);
		playhead = Phasor.ar(0, BufRateScale.kr(buf)*(rate*rateScale), start, bufLength);
		messageTrigger = InRange.kr(playhead, bufLength*0.7, bufLength);
		sig = BufRd.ar(1, buf, playhead, 1, 4)*amp;
		sig = LPF.ar(sig, 2500);
		//sig = Shaper.ar(b, sig);
		Out.ar(out, LeakDC.ar(sig));

		SendReply.kr(messageTrigger, '/fading', [rate, amp, out, group, element]);

		FreeSelf.kr(InRange.kr(playhead, bufLength*0.99, bufLength));
	};
).add;
)

(//initial generation
var spectrum = 6;//expects a multidimensional array of analysis data (from "par-text-frame.scd")
var n = p.at(spectrum).at(1).size, width = 600, height = 600;
var w = Window.new("weights", Rect(50, 50, width, height)).front;
var m = MultiSliderView(w, Rect(20, 20, width*0.95, height*0.5));
var s = Slider(w, Rect(20, (height*0.5)+20, 50, (height* 0.5)-20));
~utilArray = Array.fill(p.at(spectrum).at(1).size, {|i|i;});//TO BE FIXED!!!
~partialWeights = Array.newClear(p.at(spectrum).at(1).size);

/////
//GUI
/////
m.elasticMode = 1;
m.action =
{
	arg q;
	~partialWeights = q.value.normalizeSum;
	//~partialWeights.postln;
};
m.valueAction = Array.fill(n, {|v| 0.5});

s.action =
{
	arg q;
	~density = q.value;
	//~density.postln;
};
s.valueAction = 0.5;

//////////////////////////
///spawning initial synths
//////////////////////////
(p.at(spectrum).at(1).size).do(
	{
		arg i;
		var group, element, bufnum;
		group = spectrum;
		element = i;
		Synth
		(\zither,
			[
				\buf, 14,
				\out, i%4,//number of output channels
				\rate, p.at(group).at(1).at(element),
				\rateScale, 0.3,
				\start, 96000.rand,
				\amp, p.at(group).at(2).at(element)*16,
				\group, group,
				\element, element
			]
		);
	};
);

//starting new synths when old synths are fading out, partials with weighted probability
OSCFunc(
	{
		arg mes;
		([0,1,2].wchoose([~density.linexp(0,0.3,1,0.01),~density,~density.linexp(0.6,1,0.01,2)].normalizeSum)).do//control density by spawing 2, 1 or no synths
		(
			{
				var group, element;
				//mes.postln;
				group = (mes.at(6))%(p.size);
				element = ~partialWeights.windex;
				element.postln;
				Synth
				(\zither,
					[
						\buf, 14,
						\out, 4.rand,//number of output channels
						\rate, p.at(group).at(1).at(element),
						\rateScale, 0.3,
						\amp, p.at(group).at(2).at(element)*16,
						\group, group,
						\element, element
					]
				);
			};
		);
	}, '/fading'
);
)