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
    // Fast per-cell crackle: holds a random jitter for a short beat, then snaps to
    // a new one, so the tongues pop/flicker instead of gently swaying like a tentacle.
    float crackleRate=13.0;
    float crackleStep=floor(t*crackleRate);
    float crackleA=hash(vec2(crackleStep+seed*7.0,cell.x*.41+cell.y*.23));
    float crackleB=hash(vec2(crackleStep+1.0+seed*7.0,cell.x*.41+cell.y*.23));
    float crackle=mix(crackleA,crackleB,smoothstep(0.0,1.0,fract(t*crackleRate)));
    float pop=step(.88,crackleA);
    float curl=fbm(vec2(x*3.4+seed,y*3.0-t*2.05));
    float detail=fbm(vec2(x*8.1-seed,y*7.2-t*3.6));
    float center=sin(y*5.4-t*4.6+seed)*(.018+y*.090)
        +sin(y*12.7+t*2.7+seed*.7)*(.010+y*.030)
        +(curl-.5)*(.055+y*.07)+(crackle-.5)*.05*(1.0+y*.6);
    float width=(fireLayer<.5?.245:.205)*pow(max(0.0,1.0-y),.58)+.012;
    float main=1.0-abs(x-center)/width-y*.12+(detail-.5)*.31+(crackle-.5)*.12;
    float crown=.92+.055*sin(t*3.9+seed)+(curl-.5)*.17-pop*.05;
    main-=smoothstep(crown-.025,crown+.035,y)*1.8;
    float sideL=1.0-abs(x+.255-sin(y*9.0-t*6.2+seed)*.035)/(.095*pow(max(.01,1.0-y/.68),.55)+.009);
    sideL-=smoothstep(.53+.10*sin(t*5.3+seed),.60+.10*sin(t*5.3+seed),y)*1.7;
    float sideR=1.0-abs(x-.255-sin(y*7.2-t*5.1+seed+2.0)*.042)/(.10*pow(max(.01,1.0-y/.76),.55)+.009);
    sideR-=smoothstep(.62+.08*sin(t*4.4+seed+1.0),.70+.08*sin(t*4.4+seed+1.0),y)*1.7;
    float splitA=1.0-abs(x+.075-sin(y*15.0-t*7.1+seed)*.027)/(.068*pow(max(.01,1.0-y/.82),.63)+.007);
    splitA-=smoothstep(.70+.065*sin(t*6.0+seed),.77+.065*sin(t*6.0+seed),y)*1.8;
    float splitB=1.0-abs(x-.105-sin(y*13.0-t*6.4+seed+3.0)*.030)/(.062*pow(max(.01,1.0-y/.64),.63)+.007);
    splitB-=smoothstep(.52+.055*sin(t*4.9+seed),.60+.055*sin(t*4.9+seed),y)*1.8;
    float field=max(max(main,sideL),max(sideR,max(splitA,splitB)))+(curl-.5)*.13+pop*.08;
    float flameAlpha=smoothstep(.015,.16,field)*smoothstep(-.01,.045,y);
    float inner=1.0-abs(x-center*.55)/(width*.58+.005)-y*.30+(detail-.5)*.20;
    float heat=clamp(inner*.52+field*.28+(1.0-y)*.30+.07*sin(y*22.0-t*7.8+seed)+pop*.22,0.0,1.0);
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
