# Docker image preinstalled the Python package `black[d]`

[1]: https://hub.docker.com/r/isac322/blackd
[2]: https://pypi.org/project/black/
[3]: https://github.com/isac322/docker_image_blackd

[![Docker Pulls](https://img.shields.io/docker/pulls/isac322/blackd?logo=docker&style=flat-square)][1]
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/isac322/blackd?logo=docker&style=flat-square)][1]
[![PyPI](https://img.shields.io/pypi/v/black?label=black&logo=python&style=flat-square)][2]
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/black?logo=python&style=flat-square)][2]
[![GitHub last commit (branch)](https://img.shields.io/github/last-commit/isac322/docker_image_blackd/master?logo=github&style=flat-square)][3]
[![GitHub Workflow Status (branch)](https://img.shields.io/github/actions/workflow/status/isac322/docker_image_blackd/publish.yaml?branch=master&logo=github&style=flat-square)][3]
[![Dependabpt Status](https://flat.badgen.net/github/dependabot/isac322/docker_image_blackd?icon=github)][3]

> ### Images automatically follow upstream via dependabot.

Supported platform: `linux/amd64`, `linux/arm64/8`, `linux/arm/v7`, `linux/ppc64le`, `linux/s390x`

Based on [distroless](https://github.com/GoogleContainerTools/distroless) and compiled with mypyc.

## Tag format

`isac322/blackd:<black_version>`

## Command

Default Entrypoint of image is `blackd`.

And Command are `--bind-host 0.0.0.0 --bind-port 80`.

## How to run

`docker run -p 80:80 -ti isac322/blackd` will launch blackd server inside and expose it to host machine.

Visit http://localhost . If you see `405: Method Not Allowed` error then it succeed.

Please refer [official blackd document](https://github.com/psf/black#blackd)
