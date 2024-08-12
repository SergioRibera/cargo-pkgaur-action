# Using the `rust-musl-builder` as base image, instead of 
# the official Rust toolchain
#* ================== Stage 1: 🦀 Recipe =======================
FROM clux/muslrust:1.80.1-stable AS builder
WORKDIR /app

#* ===================== Stage 2: 🏗️ Build =============
RUN git clone https://github.com/SergioRibera/cargo-pkgbuild -b dev /app && \
    cargo build --release --target x86_64-unknown-linux-musl

#* ===================== Stage 3: ✅ Runtime =====================
FROM archlinux:base-devel-20240721.0.248532 AS runtime
# copy binary
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/cargo-aur /

# Install dependencies
RUN pacman --needed --noconfirm -Syu \
    cargo \
    git \
    openssh

# Create non-root user
RUN groupadd --gid 1001 builder && \
    useradd --uid 1001 --gid 1001 -m builder && \
    echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -a -G wheel builder

# Make ssh directory for non-root user and add known_hosts
RUN mkdir -p /home/builder/.ssh && mkdir -p /home/builder/.cargo && \
    touch /home/builder/.ssh/known_hosts

# Copy ssh_config
COPY ssh_config /home/builder/.ssh/config

# Set permissions
RUN chown -R builder:builder /home/builder/.ssh && \
    chmod 600 /home/builder/.ssh/* -R

COPY entrypoint.sh cred-helper.sh utils.sh /

# Switch to non-root user and set workdir
USER builder

ENTRYPOINT ["/entrypoint.sh"]
