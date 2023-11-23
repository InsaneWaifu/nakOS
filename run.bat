cargo build --release
wsl --  mv target/target/release/libnakOS.a boot/
wsl --  bash run.sh %*