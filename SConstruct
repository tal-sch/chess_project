#!/usr/bin/env python
"""
Master SConstruct for chess_project.

Builds two targets:
  scons tests        -> build/run_tests.exe   (standalone doctest binary)
  scons gdextension  -> game/bin/chess_engine.dll  (GDExtension shared library)

Default target: tests
"""

import os
import sys

# ---------------------------------------------------------------------------
# 0.  Environment bootstrap
# ---------------------------------------------------------------------------
EnsureSConsVersion(4, 0)
EnsurePythonVersion(3, 8)

env = Environment(
    tools=["default", "msvc", "mslink"],
    TARGET_ARCH="amd64",
)
env.PrependENVPath("PATH", os.getenv("PATH"))

# ---------------------------------------------------------------------------
# 1.  Shared compiler flags
# ---------------------------------------------------------------------------
env.Append(CXXFLAGS=["/std:c++17", "/EHsc", "/W3"])
env.Append(CPPDEFINES=["NOMINMAX", "WIN32_LEAN_AND_MEAN"])

# ---------------------------------------------------------------------------
# 2.  Backend engine sources (everything except main.cpp and Pipe.cpp)
# ---------------------------------------------------------------------------
backend_dir = Dir("backend").srcnode().abspath

engine_src_names = [
    "Square.cpp",
    "Move.cpp",
    "Piece.cpp",
    "Board.cpp",
    "Game.cpp",
    "Bot.cpp",
]

engine_sources = [os.path.join(backend_dir, f) for f in engine_src_names]

engine_objects = []
for src in engine_sources:
    engine_objects.append(
        env.Object(
            target=os.path.join("build", "engine", os.path.splitext(os.path.basename(src))[0]),
            source=src,
            CPPPATH=[backend_dir],
        )
    )

# ---------------------------------------------------------------------------
# 3.  TARGET 1 — standalone run_tests.exe  (doctest)
# ---------------------------------------------------------------------------
test_env = env.Clone()
test_env.Append(CPPPATH=[backend_dir, Dir("tests").srcnode().abspath])

test_main = test_env.Object(
    target="build/tests/test_main",
    source="tests/test_main.cpp",
)

run_tests = test_env.Program(
    target="build/run_tests",
    source=engine_objects + [test_main],
)
Alias("tests", run_tests)

# ---------------------------------------------------------------------------
# 4.  TARGET 2 — GDExtension .dll
#     Only built when the user explicitly requests  `scons gdextension`.
#     We gate this behind GetOption / BUILD_TARGETS so that godot-cpp is
#     NOT compiled for the `tests` target.
# ---------------------------------------------------------------------------
build_targets = COMMAND_LINE_TARGETS or ["tests"]

if "gdextension" in build_targets or "." in build_targets:
    # Build godot-cpp via its own SConstruct (returns a configured env).
    godot_cpp_env = SConscript(
        "godot-cpp/SConstruct",
        exports={"env": env.Clone(), "api_version": "4.7"},
    )

    bridge_env = godot_cpp_env.Clone()
    bridge_env.Append(CPPPATH=[
        backend_dir,
        Dir("godot-cpp/include").srcnode().abspath,
        Dir("godot-cpp/gen/include").srcnode().abspath,
        Dir("godot-cpp/gdextension").srcnode().abspath,
    ])

    bridge_sources = Glob("bridge/*.cpp")

    bridge_objects = []
    for src in bridge_sources:
        bridge_objects.append(bridge_env.SharedObject(
            target=os.path.join("build", "bridge", os.path.splitext(str(src.name))[0]),
            source=src,
        ))

    # Engine objects recompiled as position-independent for the shared lib.
    engine_shared_objects = []
    for src in engine_sources:
        engine_shared_objects.append(bridge_env.SharedObject(
            target=os.path.join("build", "engine_shared", os.path.splitext(os.path.basename(src))[0]),
            source=src,
            CPPPATH=[backend_dir],
        ))

    gdextension_lib = bridge_env.SharedLibrary(
        target="game/bin/chess_engine",
        source=bridge_objects + engine_shared_objects,
    )
    Alias("gdextension", gdextension_lib)

# ---------------------------------------------------------------------------
# 5.  Default target
# ---------------------------------------------------------------------------
Default(run_tests)
