// High-density, continuous-time pixel fire. Two independently animated layers
// are composited around the bale to create depth without swapping sprite frames.
extern vec2 fireGrid;
extern number fireTime;
extern number intensity;
extern number variant;
extern number fireLayer;

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float noise(vec2 p){
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),
        mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){
    float value=0.0,amp=.52;
    for(int i=0;i<4;i++){value+=noise(p)*amp;p=p*2.03+vec2(17.1,9.2);amp*=.5;}
    return value;
}
// Holds a random value for one beat then SNAPS to the next (no smooth sine drift),
// so shape driven by this reads as a jittery lick, not a swaying tentacle.
float flicker(vec2 seed2,float t,float rate){
    float step1=floor(t*rate);
    float a=hash(seed2+vec2(step1,0.0));
    float b=hash(seed2+vec2(step1+1.0,0.0));
    return mix(a,b,smoothstep(0.0,1.0,fract(t*rate)))-.5;
}
vec3 fireRamp(float heat){
    vec3 rim=vec3(.19,.025,.012),red=vec3(.64,.075,.018);
    vec3 copper=vec3(.94,.22,.025),amber=vec3(1.0,.51,.07);
    vec3 gold=vec3(1.0,.78,.24),core=vec3(1.0,.95,.67);
    if(heat<.18)return mix(rim,red,heat/.18);
    if(heat<.40)return mix(red,copper,(heat-.18)/.22);
    if(heat<.64)return mix(copper,amber,(heat-.40)/.24);
    if(heat<.84)return mix(amber,gold,(heat-.64)/.20);
    return mix(gold,core,(heat-.84)/.16);
}

vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
    vec2 cell=floor(uv*fireGrid);
    vec2 p=(cell+.5)/fireGrid;
    float x=p.x-.5,y=1.0-p.y,t=fireTime;
    float seed=variant*2.371+fireLayer*7.13;
    float curl=fbm(vec2(x*3.4+seed,y*3.0-t*1.6));
    float detail=fbm(vec2(x*8.1-seed,y*7.2-t*2.6));
    // Per-Y-band jitter snaps to a new offset a few times a second instead of one
    // smooth sine threading base-to-tip - a continuous curve like that is exactly
    // what reads as a waving tentacle, so height/width/position all jump instead.
    float yBand=floor(y*7.0);
    float bandMain=flicker(vec2(yBand*3.7+seed*11.0,1.0),t,9.0);
    float bandL=flicker(vec2(yBand*3.7+seed*11.0,2.0),t,8.0);
    float bandR=flicker(vec2(yBand*3.7+seed*11.0,3.0),t,8.5);
    float tipDart=flicker(vec2(seed*13.0,4.0),t,6.0);
    float center=(curl-.5)*(.03+y*.03)+bandMain*(.075+y*.10)+tipDart*.05*y;
    float width=(fireLayer<.5?.245:.205)*pow(max(0.0,1.0-y),.58)+.012;
    float main=1.0-abs(x-center)/width-y*.12+(detail-.5)*.34;
    float crownJ=flicker(vec2(seed*17.0,5.0),t,7.0);
    float crown=.76+(crownJ+.5)*.26+(curl-.5)*.10;
    main-=smoothstep(crown-.025,crown+.035,y)*1.8;
    float sideL=1.0-abs(x+.255-bandL*.09)/(.095*pow(max(.01,1.0-y/.68),.55)+.009);
    float lenL=.53+(flicker(vec2(seed*19.0,6.0),t,5.0)+.5)*.16;
    sideL-=smoothstep(lenL,lenL+.07,y)*1.7;
    float sideR=1.0-abs(x-.255-bandR*.10)/(.10*pow(max(.01,1.0-y/.76),.55)+.009);
    float lenR=.60+(flicker(vec2(seed*23.0,7.0),t,5.5)+.5)*.16;
    sideR-=smoothstep(lenR,lenR+.07,y)*1.7;
    float bandA=flicker(vec2(yBand*4.3+seed*7.0,8.0),t,10.0);
    float bandB=flicker(vec2(yBand*4.3+seed*7.0,9.0),t,9.5);
    float splitA=1.0-abs(x+.075-bandA*.06)/(.068*pow(max(.01,1.0-y/.82),.63)+.007);
    float lenA=.68+(flicker(vec2(seed*29.0,10.0),t,6.5)+.5)*.14;
    splitA-=smoothstep(lenA,lenA+.07,y)*1.8;
    float splitB=1.0-abs(x-.105-bandB*.065)/(.062*pow(max(.01,1.0-y/.64),.63)+.007);
    float lenB=.50+(flicker(vec2(seed*31.0,11.0),t,7.0)+.5)*.14;
    splitB-=smoothstep(lenB,lenB+.07,y)*1.8;
    float crackle=flicker(vec2(cell.x*.41+cell.y*.23+seed*7.0,12.0),t,13.0)+.5;
    float pop=step(.9,crackle);
    float field=max(max(main,sideL),max(sideR,max(splitA,splitB)))+(curl-.5)*.13+pop*.08;
    float flameAlpha=smoothstep(.015,.16,field)*smoothstep(-.01,.045,y);
    float inner=1.0-abs(x-center*.55)/(width*.58+.005)-y*.30+(detail-.5)*.20;
    float heat=clamp(inner*.52+field*.28+(1.0-y)*.30+(crackle-.5)*.14+pop*.22,0.0,1.0);
    heat=floor(heat*18.0+.5)/18.0;
    vec3 rgb=fireRamp(heat);
    float rim=smoothstep(.015,.10,field)*(1.0-smoothstep(.10,.23,field));
    rgb=mix(rgb,vec3(.30,.035,.012),rim*.72);
    float smokeFlow=fbm(vec2(x*5.2+sin(y*5.0+t)*.35+seed,y*4.7-t*.46));
    float smokeWidth=.07+y*.09;
    float smokeShape=1.0-abs(x-center*.7-.08*sin(t*.7+seed))/smokeWidth;
    float smokeAlpha=smoothstep(.16,.42,smokeShape+(smokeFlow-.5)*.75)
        *smoothstep(.67,.91,y)*(1.0-flameAlpha)*(.10+.16*smokeFlow);
    vec3 smoke=mix(vec3(.12,.09,.075),vec3(.38,.31,.25),smokeFlow);
    float lane=hash(vec2(cell.x+floor(seed*11.0),floor(seed*5.0)+3.0));
    float travel=fract(t*(.85+lane*.7)+lane*4.7);
    vec2 sparkPos=vec2(.12+lane*.76+.045*sin(t*3.4+lane*12.0),.88-travel*.64);
    float spark=step(length((p-sparkPos)*vec2(1.0,1.45)),.012+lane*.008)*step(.72,hash(vec2(cell.x,floor(t*1.6)+seed)));
    float alpha=max(flameAlpha,smokeAlpha)*intensity;
    if(smokeAlpha>flameAlpha)rgb=smoke;
    if(spark>.5){rgb=vec3(1.0,.72,.19);alpha=max(alpha,.92*intensity);}
    if(alpha<=.004)return vec4(0.0);
    return vec4(rgb,alpha)*tint;
}
