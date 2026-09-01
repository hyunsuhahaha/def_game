from PIL import Image
from render_score_axe_drum_preview import ROOT,OUT,replay,run

capture=OUT/"score-axe-tree-feedback-v2-draws.json"
run(ROOT/"scripts"/"capture_score_axe_tree_feedback.lua")
image=replay(capture)
image.save(OUT/"score-axe-tree-feedback-v2-display-scale.png")
image.resize((1920,720),Image.Resampling.NEAREST).save(OUT/"score-axe-tree-feedback-v2-2x.png")
print("SCORE_AXE_TREE_RENDER_OK v2 display=960x360 enlarged=1920x720 window=none")
