# HOLLOW CORE — DEVELOPMENT RULES

## Engine
- Godot 4.7+
- Forward+ renderer
- Vulkan
- GDScript
- Target: Windows 64-bit

## Development principles
- Inspect existing project architecture before modifying files.
- Never recreate existing systems without a technical reason.
- Prefer modular scenes and reusable components.
- Use statically typed GDScript.
- Avoid monolithic scripts.
- Use signals for loosely coupled communication.
- Keep gameplay logic separate from visual presentation.
- Avoid unnecessary autoloads and global state.

## Visual direction
- Realistic subterranean atmosphere.
- Deep obsidian and muted slate materials.
- Warm brass and amber lighting.
- Pale cyan bioluminescence.
- No excessive neon.
- No generic sci-fi HUD.
- No unnecessary UI panels.
- Diegetic interfaces only.

## Performance
- Consider GPU and CPU costs before implementing effects.
- Avoid excessive real-time shadows.
- Profile volumetric fog and particle effects.
- Use instancing for repeated environment objects.
- Consider LOD and occlusion from the beginning.

## Required workflow
1. Inspect existing scenes, scripts and resources.
2. Identify dependencies and possible regressions.
3. Present a concise implementation plan.
4. Implement only the requested subsystem.
5. Run Godot validation.
6. Launch the relevant scene when possible.
7. Inspect debugger output and visual results.
8. Report changed files and remaining issues.

Never claim that a feature works without actually verifying it.
Never invent Godot API methods or properties.
Preserve existing project functionality.
