//real time sampler for the monome and the raspberry pi inspired by brian crabtree's mlr

///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////SYNTHDEFS//////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
(
SynthDef(\player,
	{
		arg loopStart = 0, loopEnd, loopSpeed = 1, amp = 0.6, buffer, resetPos = 0, t_trigger = 0, id;
		var signal, phasor;

		phasor = Phasor.ar(t_trigger, BufRateScale.kr(buffer)*loopSpeed, loopStart, loopEnd, resetPos);
		signal = BufRd.ar(1, buffer, phasor, 1, 4);
		Out.ar(0, signal);

		SendReply.kr(Impulse.kr(40), '/playPos', phasor, id);
	};
).add;

SynthDef(\recorder,
	{
		arg recLevel = 1, preLevel = 1, buffer, getLength = 0, id;
		var length, numFrames = BufFrames.kr(buffer);

		RecordBuf.ar(SoundIn.ar(0), buffer, 0, recLevel, preLevel, loop: 1);
		length = Line.ar(0, numFrames, numFrames/s.sampleRate);//count number of recorded frames
		SendReply.kr(getLength, '/length', length, id);//send number of recorded frames...
		FreeSelf.kr(getLength);//...and free the synth
	};
).add;
)

///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
///////////////////////FUNCTIONS/VARIABLES/INITIALISATION////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
(
~m = MonoM.new("/mlrpi");
~m.useDevice(0);

~trackMode = (0!7);//0=off, 1=record, 2=play
~isOverdubbing = (0!7);//0 or 1 to check if track is currently overdubbing

~recBuffers = Array.fill(7, {arg i; Buffer.alloc(s, 16*s.sampleRate, 1, bufnum: i)});//bufnums of recBuffers:0-6
~playBufnum = Array.fill(7, {arg i; ~recBuffers.size+i});
~playBuffers = Array.newClear(7);

~recorders = Array.newClear(7);
~players = Array.newClear(7);

~loopStart = nil;
)

////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////OSCDEFS/////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
(
OSCdef(\mlr,
	{
		arg grid;
		var trackNum;

		if (grid[3] == 1)//button pressed
		{
			if ((grid[2] == 7) && (grid[1] < 14))//track mode buttons
			{
				trackNum = (grid[1]/2).floor;//setting trackNum for mode buttons

				if ((grid[1]%2) == 0)//record mode button
				{
					switch
					(
						~trackMode[trackNum],//check for trackMode of selected track
						0,//when track is off --> start recording
						{
							~recorders.put(trackNum, Synth(\recorder, [\buffer, ~recBuffers[trackNum], \id, trackNum]));

							~trackMode.put(trackNum, 1);
							~m.levset(grid[1], grid[2], 15);
							"recording r".postln;
						},
						1,//when track is recording -->
						{//stop recording+start play
							~recorders[trackNum].set(\getLength, 1);//calls \copier OSCdef

							~trackMode.put(trackNum, 2);
							~m.levset(grid[1], grid[2], 0).levset(grid[1]+1, grid[2], 15);
							"stop recording|start playing r".postln;
						},
						2,//when track is playing --> start recording (overdubbing)
						{
							switch
							(~isOverdubbing[trackNum],
								0,//start overdubbing
								{
									~recorders.put(trackNum, Synth(\recorder, [\id, -1, \buffer, ~playBuffers[trackNum]]));

									~isOverdubbing.put(trackNum, 1);
									~m.levset(grid[1], grid[2], 15);
									"start overdubbing r".postln;
								},
								1,//stop overdubbing
								{
									~recorders[trackNum].free;

									~isOverdubbing.put(trackNum, 0);
									~m.levset(grid[1], grid[2], 0);
									"stop overdubbing r".postln;
								}
							);
						},

						{"wrong track mode".postln};//if no switch statement matches
					);
				};
				if ((grid[1]%2) == 1)//play mode button
				{
					switch
					(
						~trackMode[trackNum], //select track
						0,//when track is off --> start playing
						{
							~players.put(trackNum, Synth(\player, [\buffer, ~playBuffers[trackNum], \loopEnd, ~playBuffers[trackNum].numFrames, \id, trackNum]));

							~trackMode.put(trackNum, 2);
							~m.levset(grid[1], grid[2], 15);
							"playing p".postln;
						},
						1,//when track is recording
						{//--> stop recording+start playing
							~recorders[trackNum].set(\getLength, 1);//calls \copier OSCdef

							~trackMode.put(trackNum, 2);
							~m.levset(grid[1], grid[2], 15).levset(grid[1]-1, grid[2], 0);
							"stop recording|start playing p".postln;
						},
						2,//when track is playing --> stop playing
						{
							~players[trackNum].free;

							~trackMode.put(trackNum, 0);
							~m.levset(grid[1], grid[2], 0);
							~m.ledrow(0,  trackNum, 0, 0);
							"stop playing p".postln;
						},
						{"wrong track mode".postln};//if no switch statement matches
					);
				};
			};

			if (grid[2] < 7)//track position buttons
			{
				trackNum = grid[2];//setting trackNum for position buttons

				switch
				(
					~trackMode[trackNum], //select track
					0,//when track is off
					{
						~players.put(trackNum, Synth(\player, [\buffer, ~playBuffers[trackNum], \loopEnd, ~playBuffers[trackNum].numFrames, \resetPos, (grid[1]/16) * ~playBuffers[trackNum].numFrames, \t_trigger, 1, \id, trackNum]));

						~trackMode.put(trackNum, 2);
						~m.levset((trackNum*2)+1, 7, 15);
						"playing p".postln;
					},
					1,//when track is recording
					{},
					2,//when track is playing --> jump to triggered position
					{
						if (~loopStart == nil)
						{
							~m.ledrow(0,  trackNum, 0, 0);
							~players[trackNum].set(\loopStart, 0, \loopEnd, ~playBuffers[trackNum].numFrames, \resetPos, (grid[1]/16) * ~playBuffers[trackNum].numFrames, \t_trigger, 1);
							~loopStart = Array.with(grid[1], grid[2]);//save position and track
						}
						{
							~players[trackNum].set(\loopStart, (~loopStart[0]/16) * ~playBuffers[trackNum].numFrames, \loopEnd, (grid[1]/16) * ~playBuffers[trackNum].numFrames);
							~m.ledrow(0,  trackNum, 0, 0);
						};
					},
					{"wrong track mode".postln};//if no switch statement matches
				);
			};
		};

		if (grid[3] == 0)//button released
		{
			if ((grid[2] < 7) && (~loopStart != nil))
			{
				if (~loopStart[1] == grid[2]){~loopStart = nil};
			};

		};
	}, "/mlrpi/grid/key";
);

OSCdef(\copier,
	{//get num of recorded frames+copy recordBuffer into playBuffer
		arg msg;
		var index = msg[2];

		if(index == -1)
		{}//using index -1 for overdubbing into playBuffers
		{
			Routine.run
			{
				~playBuffers.put(index, Buffer.alloc(s, msg.at(3), 1, bufnum: ~playBufnum[index]));
				s.sync;
				~recBuffers[index].copyData(~playBuffers.at(index), 0, 0, msg.at(3));
				s.sync;
				~players.put(index, Synth(\player, [\buffer, ~playBuffers[index], \loopEnd, ~playBuffers[index].numFrames, \id, index]));
				~recBuffers[index].zero;
			};
		};
		msg.postln;
	}, "/length"
);

OSCdef(\playPos,
	{
		arg msg;
		var pos = msg[3].linlin(0, ~playBuffers[msg[2]].numFrames, 0, 15);

		~m.levset((pos.round(1) - 1)%16, msg[2], 0);
		~m.levset(pos.round(1), msg[2], 15);
		//~m.levset(pos.floor, msg[2], ((pos*(pi/2)).sin.wrap(0, 1))*15);
		//~m.levset(pos.floor, msg[2], ((pos*(pi/2)).cos.wrap(0, 1))*15);
		//pos.postln;
	}, "/playPos"
);
)

(
~m.levall(0);
OSCdef.freeAll;
Buffer.freeAll;
)