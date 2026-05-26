# We Lost Dave — Claude Code Briefing

## Project Overview
A sci-fi surreal top-down roguelike desktop game built in Godot 4 (GDScript).
Target platform: Steam (macOS, Windows, Linux).
Developer: Cameron Pentz (novice developer, learning as he builds).

## Core Narrative
The player IS Dave — they don't know this until the final reveal.
The game follows a fractured consciousness searching for itself.
Tone: cold, clinical, unsettling, psychological horror meets sci-fi.

## Tech Stack
- Engine: Godot 4.6.3 (GDScript, NOT C#)
- Renderer: Forward+
- Version control: Git/GitHub (CodingCam-7/We-Lost-Dave)
- IDE: Godot built-in editor + Claude Code in terminal

## Project Structure
res://
├── scenes/       # .tscn scene files
├── scripts/      # .gd GDScript files
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
├── ui/
└── data/

## Coding Conventions
- Snake_case for variables and functions
- PascalCase for class names and nodes
- Always comment non-obvious logic
- Keep scripts focused — one responsibility per script

## Current State
- Player scene built (CharacterBody2D + Polygon2D placeholder)
- Basic 8-directional movement working
- World scene created
- Motion mode set to Floating (top-down)

## What To Build Next
- House room (first level/HQ)
- Camera that follows player
- Basic walls and floor tilemap