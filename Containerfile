FROM archlinux:latest AS final

ARG DOTFILES_DEPLOY_KEY

COPY system_files /
COPY build_files /build/

# homebrew system files (PATH setup, etc.)
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /

RUN --mount=type=tmpfs,dst=/tmp \
    bash /build/00-base.sh && \
    bash /build/01-packages.sh && \
    bash /build/02-scripts.sh && \
    bash /build/03-systemd.sh && \
    bash /build/04-smoke-test.sh && \
    bash /build/05-finalize.sh

RUN bootc container lint

# rechunk image layers for efficient delta updates
FROM quay.io/coreos/chunkah AS chunkah
ARG CHUNKAH_CONFIG_STR
RUN --mount=from=final,src=/,target=/chunkah,ro \
    --mount=type=bind,target=/run/src,rw \
        chunkah build --skip-special-files > /run/src/out.ociarchive

FROM oci-archive:out.ociarchive
ENTRYPOINT ["git"]
