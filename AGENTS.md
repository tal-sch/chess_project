# C++ Chess Multi-Agent Rule

## Project Architecture
- Backend: C++ (Board, Piece, Move, Square, Game)
- Bridge: `godot-cpp` (Submodule) via GDExtension (.dll)
- Frontend: Godot 4.7.2 + GDScript
- Tests: Standalone C++ via doctest

## Core Constraint & Verification Loop
Every time C++ logic changes, the Validator agent must automatically run SCons compilation checks and execute standalone C++ logic tests. Do not present code to the user as complete unless all unit tests and SCons builds pass cleanly.
