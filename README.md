# VR Labs – Living Room

Living room scene made in Godot 4.7 for the Virtual Reality Modeling course.

![screenshot](docs/screenshot.png)

## Lab 1 – Environment
- 12 textured props with collisions (`scenes/main.tscn`)

## Lab 2 – Interactions

![lab 2](docs/lab2.png)

- First-person controller with look-at interaction (`scenes/lab2.tscn`, runs by default)
- A 10-task checklist: turn on the lamp, tidy up the toy car and teacup, water the plant, turn on the music and the lantern, and sit down
- Tasks can be done in any order, with natural dependencies: an item has to be picked up before it can be placed or used, and sitting on the sofa is always the last task
- Everything you can do right now glows in the scene; trying something not yet possible shows a hint

**Controls:** WASD to move, mouse to look, Shift to run, Space to jump, E to interact, R to restart when done, Esc to release the mouse.

Asset list (models and textures): [MODEL_SOURCES.txt](MODEL_SOURCES.txt). No asset packages were used.
