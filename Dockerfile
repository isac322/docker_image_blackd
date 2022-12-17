# syntax=docker/dockerfile:1.4

FROM python:3.11-slim AS builder

ARG TARGETOS
ARG TARGETARCH
ARG VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'Dir::Cache::pkgcache "";\nDir::Cache::srcpkgcache "";' > /etc/apt/apt.conf.d/00_disable-cache-files
RUN apt-get update -qq
RUN apt-get install -y --no-install-recommends \
    git \
    gcc clang ccache \
    patchelf
RUN if ! [ "$(uname -m)" = 'x86_64' ]; then apt-get install -y --no-install-recommends zlib1g-dev make; fi
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETOS} \
    env MAKEFLAGS="-j$(nproc)" pip install --root-user-action=ignore -U scons wheel pip build
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETOS} \
    --mount=type=cache,target=/root/.cache/ccache,id=ccache-${TARGETOS} \
    env MAKEFLAGS="-j$(nproc)" CC='ccache gcc' \
      pip install --root-user-action=ignore -U pyinstaller staticx

RUN git clone --depth 1 -b ${VERSION} https://github.com/psf/black.git
WORKDIR black
# FIXME: https://github.com/psf/black/pull/3416
RUN sed -iE 's/gitignore: Optional\[PathSpec\] = None/gitignore: Optional[Dict[Path, PathSpec]] = None/' src/black/__init__.py

# FIXME: https://github.com/psf/black/issues/3376
RUN if [ "$(getconf LONG_BIT)" -ne 64 ]; then sed -iE 's/mypy==0.971/mypy==0.981/' pyproject.toml; fi
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETOS} \
    --mount=type=cache,target=/root/.cache/ccache,id=ccache-${TARGETOS} \
    --mount=type=cache,target=/black/.mypy_cache,id=mypy-${TARGETOS} \
    env \
      MAKEFLAGS="-j$(nproc)" \
      SETUPTOOLS_SCM_PRETEND_VERSION=${VERSION} \
      HATCH_BUILD_HOOKS_ENABLE=1 \
      MYPYC_OPT_LEVEL=3 MYPYC_DEBUG_LEVEL=0 CC='ccache clang' \
      python -m build --wheel
RUN --mount=type=cache,target=/root/.cache/pip,id=pip-${TARGETOS} \
    --mount=type=cache,target=/root/.cache/ccache,id=ccache-${TARGETOS} \
    env MAKEFLAGS="-j$(nproc)" CC='ccache gcc' \
      pip install --compile "$(ls dist/*.whl)"[d,uvloop]

WORKDIR /root
RUN --mount=type=cache,target=/root/.cache/pyinstaller,id=pyinstaller-${TARGETOS} \
    --mount=type=cache,target=/root/build,id=mypy-build-${TARGETOS}  \
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
