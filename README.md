# llvm_pgo

Repo to build a Clang PGO+LTO+BOLT prepared Ubuntu image

## Steps

1. Place your standalone build script with the name `build_<Project>.sh` into `build_scripts`.
2. Run `docker build -f clang-pgo-lto-bolt.Dockerfile . --build-arg LLVM_VERSION=17.0.6 --build-arg <Project> -t clang_pgo_lto_bolt_ready:17.0.6` to build your optimized clang & (unoptimized) llvm suite with a specific llvm version.
