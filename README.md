# VR Modeling – Lab 1: Living Room

A starting virtual environment made in **Godot 4.5**: a small living room with 13 unique, textured 3D props. Every prop has collision.

![screenshot](docs/screenshot.png)

## How it meets the lab requirements

| Requirement | Where |
|---|---|
| At least 10 unique 3D props | 13 different `.glb` models in `models/` (see `MODEL_SOURCES.txt`) |
| Models are textured | All are PBR-textured glTF models (base color, normal, roughness, etc.) |
| Collisions for all models | Each prop is a `StaticBody3D` with `CollisionShape3D` nodes (convex or trimesh) in `scenes/main.tscn` |
| Links to downloaded models | `MODEL_SOURCES.txt` |

## Run it

1. Open Godot 4.5 → **Import** → pick `project.godot`.
2. Wait for the first import to finish, then press **F5** (Play).
3. Controls: **WASD** move, **mouse** look, **Shift** run, **Space** jump, **Esc** free the mouse (click to capture again).

To see the collision shapes: **Debug → Visible Collision Shapes**, then play.

## Project layout

```
models/               downloaded .glb props (+ textures Godot extracted from them)
scenes/main.tscn      the environment
scripts/player.gd     first-person controller
tools/build_scene.gd  script that generated main.tscn (props, collisions, room, lights)
MODEL_SOURCES.txt     links + licenses for every downloaded model
```
