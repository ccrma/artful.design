// the device number to open
0 => int KB_NUM;
// which gametrack
0 => int GT_NUM;
// number of virtual sound sources
5 => int NUM_SS;

// hack mode: no game-trak
true => int HACK_MODE;

// shared UGen
PoleZero bL => NRev rL => dac.left;
PoleZero bR => NRev rR => dac.right;
.1 => rL.mix;
.1 => rR.mix;
.95 => bL.blockZero => bR.blockZero;

// a stereo buffer
class Buff
{
    SndBuf L;
    SndBuf R;
    
    // no gain
    0 => L.gain => R.gain;
    
    // set rate
    1 => L.rate;
    1 => R.rate;
    
    // read
    fun void read( string filename )
    {
        // append path
        "audio/" + filename => L.read;
        "audio/" + filename => R.read;
        
        // print info
        <<< "[beijing]: loading:", filename, "length:", (L.length()/second+.5)$int, "seconds..." >>>;
        
        // if more than one channel
        if( L.channels() > 1 )
        {
            // select channel 1 for R
            R.channel(1);
        }
        
        // set the playhead to the end
        L.samples() => L.pos;
        R.samples() => R.pos;
    }
    
    // gain
    fun void gain( float value )
    {
        value => L.gain => R.gain;
    }
    
    // rate
    fun void rate( float value )
    {
        value => L.rate => R.rate;
    }
    
    // play
    fun void pos( int value )
    {
        value => L.pos;
        value => R.pos;
    }
}


// a virtual sound source
class VSS
{
    <<< "initializing VSS…" >>>;
    // connect by channel
    Gain left => KSChord objectL => LPF lowpassL;
    Gain right => KSChord objectR => LPF lowpassR;
    
    // default values
    1000 => lowpassL.freq => lowpassR.freq;

    // buffers
    SndBuf buffy[10];
    // read
    "audio/stanfirmd.aiff" => buffy[0].read;
    "audio/subway-1.aiff" => buffy[1].read;
    "audio/subway-2.aiff" => buffy[2].read;
    "audio/subway-3.aiff" => buffy[3].read;
    "audio/beeps-1b.aiff" => buffy[4].read;
    "audio/sizzle-2.aiff" => buffy[5].read;
    "audio/rev-engine-1.aiff" => buffy[6].read;
    "audio/rev-engine-2a.aiff" => buffy[7].read;
    "audio/motorbike-passing-1.aiff" => buffy[8].read;
    "audio/motorbike-passing-2.aiff" => buffy[9].read;

    // connect
    for( int i; i < buffy.size(); i++ )
    {
        // stereo
        // buffy[i].L => objectL;
        // buffy[i].R => objectR;
        // mono
        buffy[i] => left;
        buffy[i] => right;
        // set to end (don't play yet)
        buffy[i].samples() => buffy[i].pos;
    }

    fun void connect()
    {
        // connect to global reverb
        lowpassL => rL;
        lowpassR => rR;
    }

    // connect, with pan (0 to 1)
    fun void pan( float pan )
    {
        Math.cos( pan * pi / 2 ) => left.gain;
        Math.sin( pan * pi / 2 ) => right.gain;
    }
    
    // trigger
    fun void trigger( int which )
    {
        // sanity check
        if( which < 0 || which >= buffy.size() )
        {
            // log
            <<< "[beijing-studio]: internal error -- invalid buffer index:", which >>>;
            return;
        }
        
        // reset play pos
        buffy[which].pos( 0 );
    }
    
    // tune
    fun void tune( int p1, int p2, int p3, int p4 )
    {
        objectL.tune( p1, p2, p3, p4 );
        objectR.tune( p1, p2, p3, p4 );
    }
    
    // gain
    fun void gain( float val )
    {
        // loop
        for( int i; i < buffy.size(); i++ )
        {
            val => buffy[i].gain;
        }
    }
    
    // rate
    fun void rate( float val )
    {
        // loop
        for( int i; i < buffy.size(); i++ )
        {
            val => buffy[i].rate;
        }
    }
    
    // feedback
    fun void feedback( float val )
    {
        val => objectL.feedback => objectR.feedback;
    }
    
    // cutoff
    fun void cutoff( float val )
    {
        val => lowpassL.freq => lowpassR.freq;
    }
}

// number of virtual SS
VSS ss[NUM_SS];
// loop over them
for( int i; i < ss.size(); i++ )
{
    // connect
    ss[i].connect();
    // pan
    ss[i].pan( .1 + .8*(i$float / (ss.size()-1)) );
}

// keys
80 => int KEY_LEFT;
79 => int KEY_RIGHT;
82 => int KEY_UP;
81 => int KEY_DOWN;

54 => int KEY_COMMA;
55 => int KEY_PERIOD;
56 => int KEY_SLASH;
229 => int KEY_SHIFT_RIGHT;

30 => int KEY_1;
31 => int KEY_2;
32 => int KEY_3;
33 => int KEY_4;
34 => int KEY_5;
35 => int KEY_6;
36 => int KEY_7;
37 => int KEY_8;
38 => int KEY_9;
39 => int KEY_0;

// key map
int BUTTON[256];
// -1 for all
for( int i; i < BUTTON.size(); i++ )
    -1 => BUTTON[i];
// key and pitch
0 => BUTTON[29];
1 => BUTTON[27];
2 => BUTTON[6];
3 => BUTTON[25];
4 => BUTTON[5];
5 => BUTTON[4] => BUTTON[17];
6 => BUTTON[22] => BUTTON[16];
7 => BUTTON[7] => BUTTON[54];
8 => BUTTON[9] => BUTTON[55];
9 => BUTTON[10] => BUTTON[56];
10 => BUTTON[20] => BUTTON[11];
11 => BUTTON[26] => BUTTON[13];
12 => BUTTON[8] => BUTTON[14];
13 => BUTTON[21] => BUTTON[15];
14 => BUTTON[23] => BUTTON[51];
15 => BUTTON[28] => BUTTON[52];
16 => BUTTON[24];
17 => BUTTON[12];
18 => BUTTON[18];
19 => BUTTON[19];
20 => BUTTON[47];
21 => BUTTON[48];
22 => BUTTON[49];

// instantiate a Hid object
Hid hi;
// structure to hold HID messages
HidMsg msg;

// open keyboard
if( !hi.openKeyboard( KB_NUM ) ) me.exit();
// successful! print name of device
<<< "[beijing-studio]: keyboard '", hi.name(), "' ready..." >>>;

// z axis deadzone
0.015 => float DEADZONE;

// get from command line
// if( me.args() ) me.arg(0) => Std.atoi => device;

// HID objects
Hid trak;
HidMsg amsg;

// hack mode check
if( !HACK_MODE )
{
    // open joystick 0, exit on fail
    if( !trak.openJoystick( GT_NUM ) ) me.exit();
    // print
    <<< "joystick '" + trak.name() + "' ready", "" >>>;
}

// data structure for gametrak
class GameTrak
{
    // timestamps
    time lastTime;
    time currTime;
    
    // previous axis data
    float lastAxis[6];
    // current axis data
    float axis[6];
}

// gametrack
GameTrak gt;

// chords
1 => int CHORD_MAJ;
2 => int CHORD_MIN7;
3 => int CHORD_DIM;
4 => int CHORD_ADD4;

// chord class
class Chord
{
    // the pitches
    int p[4];
    // transpose
    0 => int transpose;
    
    // set the pitches
    fun void set( int p1, int p2, int p3, int p4 )
    {
        p1 => p[0];
        p2 => p[1];
        p3 => p[2];
        p4 => p[3];
    }
    
    // set
    fun int offset( int v )
    {
        v => transpose;
    }
}

// which SS
-1 => int theSSIndex;
// which soundfile
0 => int theSound;
// how much to transpose
0 => int theTranspose;
// the chord type (maj, m7, dim)
CHORD_ADD4 => int theChordType;
// the chord root
50 => int theChordRoot;
// the chord we are working with
Chord theChord;
// test chord (for printing)
Chord theTestChord;
// Dm7
theChord.set( 50, 53, 60, 62 );

// construct chord
fun void makeTheChord( Chord @ chord, int type, int root )
{
    // the root
    root => chord.p[0];
    
    // customize voicings
    if( type == CHORD_MAJ )
    {
        root + 7 => chord.p[1];
        root + 12 => chord.p[2];
        root + 16 => chord.p[3];
    }
    else if( type == CHORD_MIN7 )
    {
        root + 3 => chord.p[1];
        root + 10 => chord.p[2];
        root + 12 => chord.p[3];
    }
    else if( type == CHORD_DIM )
    {
        root + 6 => chord.p[1];
        root + 12 => chord.p[2];
        root + 15 => chord.p[3];
    }
    else if( type == CHORD_ADD4 )
    {
        root + 5 => chord.p[1];
        root + 7 => chord.p[2];
        root + 16 => chord.p[3];
    }
    else
    {
        <<< "NO!! DON'T!!!" >>>;
    }
}

fun void printChord()
{
    string type;
    if( theChordType == CHORD_MAJ ) "maj" => type;
    else if( theChordType == CHORD_MIN7 ) "m7" => type;
    else if( theChordType == CHORD_DIM ) "dim" => type;
    else if( theChordType == CHORD_ADD4 ) "add4" => type;
    
    // make it
    makeTheChord( theTestChord, theChordType, theChordRoot );
    
    <<< "[beijing]: root:", theChordRoot+theTranspose, type, 
    theTestChord.p[0] + theTranspose,
    theTestChord.p[1] + theTranspose,
    theTestChord.p[2] + theTranspose,
    theTestChord.p[3] + theTranspose,
    "transpose:", theTranspose >>>;
}

// send sound + chords
fun void send( int which, Chord @ c )
{
    // cycle through the host to send to
    theSSIndex++;
    // modulo
    NUM_SS %=> theSSIndex;
    
    // log
    <<< "[beijing-studio]: SOUND: ", which, "SOURCE:", theSSIndex >>>;     
    // get ref
    ss[theSSIndex] @=> VSS @ vss;

    // tune
    vss.tune( c.p[0] + theTranspose, c.p[1] + theTranspose, c.p[2] + theTranspose, c.p[3] + theTranspose );
    // play
    vss.trigger( which );
}

// send trak updates
fun void sendUpdate( float gain, float feedback, float rate, float cutoff )
{
    for( int i; i < NUM_SS; i++ )
    {
        // send which
        ss[i].gain( gain );
        ss[i].feedback( feedback );
        ss[i].rate( rate );
        ss[i].cutoff( cutoff );
    }
}

// spork control
if( !HACK_MODE ) spork ~ gametrak(); else spork ~ gametrak_emulate();
// start keyboard loop
spork ~ kb();

// time loop
while( true )
{
    1::second => now;
}

// map
fun void map()
{
    // LH Z axis gain
    gt.axis[2] * .1 => float gain;
    //RH Z axis feedback
    Math.pow(gt.axis[5]*1.5,1.0/9) => float limit;
    if (limit > .999999 ) {
        .999999 => limit;
    } 
    
    //LH x axis rate
    gt.axis[0]*.2+1 => float rate;
    
    //RH lowpass
    (3000 + gt.axis[3]*2000) => float cutoff;
    // <<< "gain:", gain, "limit:", limit, "lowpass:", cutoff, "rate:", rate >>>;
    
    // apply
    sendUpdate( gain, limit, rate, cutoff );
}

// keyboard
fun void kb()
{
    // log
    <<< "[beijing-studio]: starting kb handler..." >>>; 
    // infinite event loop
    while( true )
    {
        // wait on event
        hi => now;
        
        // get one or more messages
        while( hi.recv( msg ) )
        {
            // check for action type
            if( msg.isButtonDown() )
            {
                // up and down
                if( msg.which == KEY_UP ) 12 +=> theTranspose;
                else if( msg.which == KEY_DOWN ) 12 -=> theTranspose;
                else if( msg.which == KEY_COMMA ) CHORD_MAJ => theChordType;
                else if( msg.which == KEY_PERIOD ) CHORD_MIN7 => theChordType;
                else if( msg.which == KEY_SLASH ) CHORD_DIM => theChordType;
                else if( msg.which == KEY_SHIFT_RIGHT ) CHORD_ADD4 => theChordType;
                // selection
                else if( msg.which >= KEY_1 && msg.which <= KEY_0 )
                {
                    // select sound
                    msg.which-KEY_1 => theSound;
                    // make the chord
                    makeTheChord( theChord, theChordType, theChordRoot );
                    // send message
                    send( theSound, theChord );
                }
                else if( msg.which > 0 && msg.which < 256 && BUTTON[msg.which] >= 0)
                {
                    // freq
                    BUTTON[msg.which]+3+50 => theChordRoot;
                }
                
                // print chord
                printChord();
            }
        }
    }
}

// gametrack handling (hack mode only)
fun void gametrak_emulate()
{
    // gain
    .5 => gt.axis[2];
    // feedback
    .5 => gt.axis[5];
    // rate
    0 => gt.axis[0];
    // lowpass
    .9 => gt.axis[3];
    
    while( true )
    {
        // map
        map();
        // wait
        1000::ms => now;
    }
}

// gametrack handling
fun void gametrak()
{
    // log
    <<< "[beijing-studio]: starting gametrak handler..." >>>; 
    
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( amsg ) )
        {
            // joystick axis motion
            if( amsg.isAxisMotion() )
            {            
                // check which
                if( amsg.which >= 0 && amsg.which < 6 )
                {
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    gt.axis[amsg.which] => gt.lastAxis[amsg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( amsg.which != 2 && amsg.which != 5 )
                    { amsg.axisPosition => gt.axis[amsg.which]; }
                    else
                    {
                        1 - ((amsg.axisPosition + 1) / 2) - DEADZONE => gt.axis[amsg.which];
                        if( gt.axis[amsg.which] < 0 ) 0 => gt.axis[amsg.which];
                    }
                }
            }
        }
        
        // map
        map();
    }
}
