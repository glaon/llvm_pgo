# llvm_pgo

Repo to build a Clang PGO prepared Ubuntu image

## Requirements 
* Checkout llvm-project

## Steps
* Run [`checkout_llvm.sh`](checkout_llvm.sh)
* Run `LLVM_VERSION=17.0.6 docker compose build`
