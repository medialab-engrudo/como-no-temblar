(
s.waitForBoot({
	s.freeAll;
	Buffer.freeAll;

	s.sync;

	////synthsdef
	SynthDef(\play,
		{
			// args buf, amp, rel, rate, lpf, out
			var sig, env;
			sig = PlayBuf.ar(
				numChannels: 1, //debe ser fijo en la creacion,
				bufnum: \buf.kr(0), // numero de buffer, no hace falta indicar -> bufnum
				// BufRateScale calcula el rate del sample para que coincida con el server rate
				// Ej server rate = 48000, sample rate 44100  44100 / 48000 = 0.91875
				// 0.91875 es lo que se debe variar con respecto a 1 para que se reproduzca bien
				rate: BufRateScale.kr(\buf.kr(0)) * \rate.kr(1), // rate es para poder conrolarlo desde afuera
				startPos: \sps.kr(2),
				loop:1,

			);
			sig = RLPF.ar(sig,\lpf.kr(0));
			sig = HPF.ar(sig,\hpf.kr(10));
			env = EnvGen.kr(
				Env(
					[0,1,0],
					[\atk.kr(2),\rel.kr(2)],
					[4,-4]
				),
				doneAction: 2,
			);
			sig = sig * env;
			sig = Pan2.ar(sig,0,\amp.kr(0.2));
			Out.ar(\out.kr(0),sig);
		}
	).add;

	SynthDef(\pulse, { |freq = 100, amp=0.7, freq2=150|
		var sig;
		sig = Pulse.ar([freq,freq+1], 0.5, 0.04);
		sig = sig + SinOsc.ar([freq2,freq+0.6], 0, 0.15);
		sig = sig + BrownNoise.ar(0.04!2);
		sig = sig * EnvGen.kr(
			Env(
				[0,1,0],
				[\atk.kr(2),\rel.kr(2)],
				[4,-4]
			),
			doneAction: 2,
		);
		Out.ar(0, sig*amp)
	};
	).add;

	"sintes listos".postln;
	s.sync;

	~cntSamples = PathName.new(thisProcess.nowExecutingPath).parentPath ++ 'samples/';
	b = PathName.new(~cntSamples).entries.collect({
		arg sample;
		Buffer.read(s, sample.fullPath);
	});


	"samples listos".postln;
	s.sync;

	OSCdef(\datos, {|msg|
		msg.postln;
		r = msg[2].asInteger.linlin(0, 99, 1, 0.1);
		a = msg[1].asInteger.linexp(1, 1358, 100, 1200);
		// r = msg[1].asInteger.linlin(1, 1358, -1,1).postln;
		Synth(\play,[
			buf:b.choose,
			lpf:rrand(a, a + 100),
			rate:r,
			atk: rrand(0.001, 1),
			rel: r * rrand(1, 10),
			amp: rrand(0.1, 0.5),
			sps: rrand(0,1.0)]);

		Synth(\play,[
			buf:b.choose,
			lpf:rrand(a+100, a + 300),
			rate:r * rrand(0.99, 1.01),
			atk: rrand(0.001, 1),
			rel:rrand(9, 10),
			amp: rrand(0.1, 0.5),
			sps: rrand(0,1.0)]);

		Synth(\play,[
			buf:b.choose,
			lpf:rrand(5, 10000),
			hpf:rrand(2000, 4000),
			rate:r * rrand(0.99, 1.01),
			atk: rrand(0.001, 0.002),
			rel:rrand(1,20),
			amp: rrand(0.1, 0.5),
			sps: rrand(0,1.0)]);

		Synth(\play,[
			buf:b.choose,
			lpf:rrand(5000, 10000),
			hpf:rrand(a * 3, a * 4),
			rate:r,
			atk: rrand(1, 3),
			rel:rrand(5,10),
			amp: rrand(0.1, 0.5),
			sps: rrand(0,1.0)]);

		Synth(\play,[
			buf:b.choose,
			lpf:rrand(5000, 10000),
			hpf:rrand(a * 3, a * 4),
			rate:r,
			atk: rrand(1, 3),
			rel:rrand(5,10),
			amp: rrand(0.1, 0.5),
			sps: rrand(0,1.0)]);

		Synth(\pulse, [freq: rrand(50, (r + 50)),
			freq2: rrand(50, (r + 100)),
			atk: rrand(5, 10),
			rel: rrand(10, 20),
			amp: rrand(0.1, 0.2)]);
	}, '/datos', recvPort: 12001)
})
)
