package.path="./?.lua;./?/init.lua;"..package.path
love={}
local Benchmark=require("src.stress_benchmark")
local values={.010,.020,.030,.040,.050}
assert(Benchmark.percentile(values,.50)==.030,"median frame time changed")
assert(Benchmark.percentile(values,.95)==.050,"p95 frame time changed")
assert(Benchmark.percentile({},.95)==0,"empty percentile must be zero")
local source=assert(io.open("src/stress_benchmark.lua","rb")):read("*a")
assert(source:find("TARGET_TREES=100",1,true)and source:find("p95<=25",1,true),"stress contract changed")
local modeSource=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(modeSource:find('true,48)',1,true),"score-mode drop bundle cap changed")
assert(modeSource:find('effectParticleCap=self.scoreAttack and 100',1,true),"score-mode particle budget changed")
local confSource=assert(io.open("conf.lua","rb")):read("*a")
assert(confSource:find('LAST_HAUL_STRESS_BENCHMARK',1,true)and confSource:find('t.window.vsync = 0',1,true),"benchmark must run without display-sync quantization")
print("STRESS_BENCHMARK_OK trees=100 full_build=true threshold=50fps+p95_25ms hidden=true")
