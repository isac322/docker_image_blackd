# syntax=docker/dockerfile:1.4

FROM python:3.11-slim AS builder

ARG VERSION
ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'Dir::Cache::pkgcache "";\nDir::Cache::srcpkgcache "";' > /etc/apt/apt.conf.d/00_disable-cache-files
RUN apt-get update -qq
RUN apt-get install -y --no-install-recommends \
    git \
    gcc clang \
    patchelf
RUN env MAKEFLAGS="-j$(nproc)" pip install --root-user-action=ignore -U scons wheel pip build
RUN env MAKEFLAGS="-j$(nproc)" pip install --root-user-action=ignore -U pyinstaller staticx

RUN git clone --depth 1 -b ${VERSION} https://github.com/psf/black.git
WORKDIR black

RUN env \
      MAKEFLAGS="-j$(nproc)" \
      HATCH_BUILD_HOOKS_ENABLE=1 HATCH_BUILD_CLEAN_HOOKS_AFTER=1 \
      MYPYC_OPT_LEVEL=3 MYPYC_DEBUG_LEVEL=0 AIOHTTP_NO_EXTENSIONS=1 CC=clang \
      python -m build --wheel
RUN env MAKEFLAGS="-j$(nproc)" pip install --compile "$(ls dist/*.whl)"[d,uvloop] 'click<8.1.0'
RUN env MAKEFLAGS="-j$(nproc)" \
    pyinstaller \
      --clean \
      --onefile \
      --strip \
      --name blackd \
      --add-data 'src/blib2to3:blib2to3' \
      src/blackd/__main__.py
RUN env MAKEFLAGS="-j$(nproc)" staticx --strip dist/blackd dist/blackd_static


FROM gcr.io/distroless/base-debian11
MAINTAINER 'Byeonghoon Isac Yoo <bhyoo@bhyoo.com>'

COPY --link=true --from=builder /black/dist/blackd_static /usr/local/bin/blackd
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/blackd"]
CMD ["--bind-host", "0.0.0.0", "--bind-port", "80"]
