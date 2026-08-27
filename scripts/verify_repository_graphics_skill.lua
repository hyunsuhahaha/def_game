-- Guard the repository-portable graphics workflow required by AGENTS.md.
local function read(path)
    local file=assert(io.open(path,"rb"),"missing required file: "..path)
    local value=file:read("*a")
    file:close()
    return value
end

local skillPath=".agents/skills/defense-game-pixel-art/SKILL.md"
local agents=read("AGENTS.md")
local skill=read(skillPath)
local projectMap=read(".agents/skills/defense-game-pixel-art/references/project-map.md")

assert(agents:find(skillPath,1,true),"AGENTS.md must require the repository graphics skill")
for _,required in ipairs({
    "docs/GRAPHICS_STYLE_GUIDE.md",
    "docs/PIXEL_ART_PIPELINE.md",
    "docs/character_dossier.html",
    "py -3 scripts/headless_lua.py",
    "git diff --check",
}) do
    assert(skill:find(required,1,true) or projectMap:find(required,1,true),
        "repository graphics skill is missing required contract: "..required)
end
assert(skill:find("visually inspect",1,true),"graphics skill must require visual inspection")
assert(skill:find("Do not automatically launch the game window",1,true),
    "graphics skill must preserve the no-auto-launch rule")

print("REPOSITORY_GRAPHICS_SKILL_OK tracked entrypoint and workflow contract present")
