#!/bin/bash
touch /build/.lock
cargo build --manifest-path "/build/Cargo.toml" --release
rm /build/.lock
