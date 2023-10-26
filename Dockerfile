# syntax=docker/dockerfile:1.4

FROM python:3.12-slim AS builder

ARG TARGETARCH
ARG VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'Dir::Cache::pkgcache "";\nDir::Cache::srcpkgcache "";' > /etc/apt/apt.conf.d/00_disable-cache-files
RUN apt-get update -qq
RUN apt-get install -y --no-install-recommends \
    git \
    gcc clang ccache \
    patchelf libnss3-dev
RUN if ! [ "$(uname -m)" = 'x86_64' ]; then apt-get install -y --no-install-recommends zlib1g-dev make; fi
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETARCH} \
    env MAKEFLAGS="-j$(nproc)" pip install --root-user-action=ignore -U scons wheel pip build
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETARCH} \
    --mount=type=cache,target=/root/.cache/ccache,id=ccache-${TARGETARCH} \
    env MAKEFLAGS="-j$(nproc)" CC='ccache gcc' \
      pip install --root-user-action=ignore -U pyinstaller staticx

RUN git clone --depth 1 -b ${VERSION} https://github.com/psf/black.git
WORKDIR black

RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETARCH} \
    --mount=type=cache,target=/root/.cache/ccache,id=ccache-${TARGETARCH} \
    --mount=type=cache,target=/black/.mypy_cache,id=mypy-${TARGETARCH} \
    env \
      MAKEFLAGS="-j$(nproc)" \
      SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION} \
      HATCH_BUILD_HOOKS_ENABLE=1 \
      MYPYC_OPT_LEVEL=3 MYPYC_DEBUG_LEVEL=0 CC='ccache clang' \
      python -m build --wheel
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETARCH} \
    --mount=type=cache,target=/root/.cache/ccache,id=ccache-${TARGETARCH} \
    env MAKEFLAGS="-j$(nproc)" CC='ccache gcc' \
      pip install --compile "$(ls dist/*.whl)"[d,uvloop]

WORKDIR /root
RUN --mount=type=cache,target=/root/.cache/pyinstaller,id=pyinstaller-${TARGETARCH} \
    --mount=type=cache,target=/root/build,id=mypy-build-${TARGETARCH}  \
    env MAKEFLAGS="-j$(nproc)" \
      pyinstaller \
        --clean  \
        --onefile \
        --strip \
        --name blackd \
        $(python -c "import sys,blackd;print(' '.join(map(lambda s: f'--hiddenimport {s}', filter(lambda s: s.endswith('__mypyc'), sys.modules.keys()))))") \
        --hiddenimport platformdirs  \
        --collect-submodules blackd  \
        --collect-submodules black  \
        --collect-submodules blib2to3  \
        --add-data '/black/src/blib2to3:blib2to3' \
        $(which blackd)
RUN env MAKEFLAGS="-j$(nproc)" staticx --strip dist/blackd dist/blackd_static


FROM gcr.io/distroless/static:nonroot
USER 65532:65532
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/blackd"]
CMD ["--bind-host", "0.0.0.0", "--bind-port", "80"]
MAINTAINER 'Byeonghoon Isac Yoo <bhyoo@bhyoo.com>'

COPY --link --from=builder --chown=65532:65532 /root/dist/blackd_static /usr/local/bin/blackd
