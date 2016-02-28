112 => float bpm;
(60000 / (4 * bpm))::ms => dur time16;
0 => int beat;
0 => int meas;
60 => int key;

0.5 => dac.gain;

[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0] @=> float hatNotes[];
[1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0] @=> float bdNotes[];
[0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0] @=> float snNotes[];
[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0] @=> float tomNotes[];

0 => int snareFillFlag;

OscRecv recv;
9433 => recv.port;
recv.listen();
recv.event("/collision", "i f f f f f f f") @=> OscEvent @ mele;
recv.event("/drum", "i") @=> OscEvent @ drume;

OscRecv recv2;
9434 => recv2.port;
recv2.event("/chord", "i i i i i i") @=> OscEvent @ chorde;

Osc xmit;
xmit.setHost("localhost", 9435);

256 => int queueSize;
0 => int queueStart;
0 => int queueEnd;
int queue[3][queueSize];
0 => int chordQueueStart;
0 => int chordQueueEnd;
int chordQueue[6][queueSize];

TriOsc t[7];
for(0 => int i; i < 7; i++){
    t[i] => dac;
    0.4 => t[i].gain;
}

fun void melodyRecieve(){
    while(true){
        mele => now;
        while(mele.nextMsg()){
            mele.getInt() => queue[0][queueEnd];
            mele.getFloat() $ int => queue[1][queueEnd];
            mele.getFloat() $ int => queue[2][queueEnd];
            for(3 => int i; i < 8; i++){
                mele.getFloat();
            }
            (queueEnd + 1) % queueSize => queueEnd;
        }
    }
}

fun void drumRecieve(){
    while(true){
        drume => now;
        while(drume.nextMsg()){
            changeDrums(drume.getInt());
        }
    }
}

fun void chordRecieve(){
    while(true){
        chorde => now;
        while(chorde.nextMsg()){
            for(0 => int i; i < 6; i++){
                chorde.getInt() => chordQueue[i][chordQueueEnd];
            }
            (chordQueueEnd + 1) % queueSize => chordQueueEnd;
            xmit.startMsg("/queuelen", "i");
            (chordQueueEnd - chordQueueStart) % queueSize => xmit.addInt;
        }
    }
}

fun void hat(float vel){
    Noise n => HPF hi => LPF lo => dac;
    8000 => hi.freq;
    3 => hi.Q;
    18000 => lo.freq;
    for(0 => int i; i < 25; i++){
        (25 - i) $ float / 25 * vel => n.gain;
        1::ms => now;
    }
    0 => n.gain;
}

fun void bd(float vel){
    TriOsc k => dac;
    vel * 1.5 => k.gain;
    for(0 => int i; i < 40; i++){
        50 * Math.exp(-0.1 * i) + 50 => k.freq;
        (40 - i) $ float / 40 * vel * 1.5 => k.gain;
        5::ms => now;
    }
}

fun void sn(float vel){
    Noise n => LPF f => dac;
    2 => f.Q;
    for(0 => int i; i < 60; i++){
        1000 * Math.exp(-0.1 * i) + 3000 => f.freq;
        (60 - i) $ float / 60 * vel => n.gain;
        2::ms => now;
    }
}

fun void cymb(){
    Noise n => HPF hi => dac;
    6000 => hi.freq;
    3 => hi.Q;
    for(0 => int i; i < 25; i++){
        (25 - i) $ float / 25 => n.gain;
        20::ms => now;
    }
    0 => n.gain;
}

fun void melody(int note, int vel){
    SinOsc s => dac;
    [0, 2, 4, 5, 7, 9, 11] @=> int major[];
    Std.mtof(key + major[note % 7]) => s.freq;
    for(0 => int i; i < 100; i++){
        (100 - i) $ float / 100 => s.gain;
        2::ms => now;
    }
}

fun void changeChords(){
    if(chordQueueStart != chordQueueEnd){
        chordQueue[0][chordQueueStart] => t[6].freq;
        for(0 => int i; i < 6; i++){
            chordQueue[i][chordQueueStart] => t[i].freq;
        }
        chordQueueStart = (chordQueueStart + 1) % queueLength;
    }
}

fun void changeDrums(int param){
    Math.random2(0, 4) => int instChange;
    if(instChange == 0){
        [2, 3, 4, 6, 8] @=> int patLengths[];
        patLengths[Math.random2(0, 4)] => int hatPatLength;
        for(0 => int i; i < hatPatLength; i++){
            Math.randomf() => hatNotes[i];
            if(hatNotes[i] < 0.4){
                0 => hatNotes[i];
            }
        }
        for(hatPatLength => int i; i < 16; i++){
            hatNotes[i % hatPatLength] => hatNotes[i];
        }
    }
    else if(instChange == 1){
        [[1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
         [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
         [1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0],
         [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0],
         [1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1],
         [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0],
         [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0],
         [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1],
         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]] @=> int bdPats[][];
        Math.random2(0, 8) => int bdPatNum;
        for(0 => int i; i < 16; i++){
            bdPats[bdPatNum][i] => bdNotes[i];
        }
    }
    else if(instChange == 2){
        if(snareFillFlag == 0){
            Math.random2(0, 1) => snareFillFlag;
        }
    }
    else if(instChange == 3){
        Math.max(Math.min(bpm + Math.random2(-2, 2), 132), 88) => bpm;
        <<<bpm>>>;
        (60000 / (4 * bpm))::ms => time16;
    }
}

fun void beat16(){
    spork ~ hat(hatNotes[beat]);
    spork ~ bd(bdNotes[beat]);
    spork ~ sn(snNotes[beat]);
    if(beat == 0){
        changeChords();
        if(snareFillFlag == 3){
            0 => snareFillFlag;
            spork ~ cymb();
        }
    }
    if(beat % 2 == 0){
        10::ms => now;
    }
    beat++;
    if(beat == 16){
        0 => beat;
        meas++;
        if(meas == 16){
            0 => meas;
        }
        if(snareFillFlag == 1 && (meas % 4) == 3){
            for(0 => int i; i < 16; i++){
                Math.min(Math.randomf() + 0.3, 1) => snNotes[i];
                if(snNotes[i] < 0.6){
                    0 => snNotes[i];
                }
            }
            2 => snareFillFlag;
        }
        else if(snareFillFlag == 2){
            [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0] @=> snNotes;
            changeDrums(0);
            3 => snareFillFlag;
        }

        // take out later
        changeDrums(0);
    }
}

spork ~ melodyRecieve();
spork ~ drumRecieve();

while(true){
    beat16();
    if(queueStart != queueEnd){
        spork ~ melody(queue[0][queueStart], queue[1][queueStart]);
        (queueStart + 1) % queueSize => queueStart;
        time16 => now;
        beat16();
        if(queueStart != queueEnd){
            spork ~ melody(queue[0][queueStart], queue[1][queueStart]);
            (queueStart + 1) % queueSize => queueStart;
        }
    }
    else{
        time16 => now;
        beat16();
    }
    time16 => now;
}
