# Docker image preinstalled the Python package `black[d]`

![Docker Pulls](https://img.shields.io/docker/pulls/isac322/blackd?logo=docker&style=flat-square)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/isac322/blackd/latest?logo=docker&style=flat-square)
![PyPI](https://img.shields.io/pypi/v/black?label=black&logo=python&style=flat-square)
![PyPI - Python Version](https://img.shields.io/pypi/pyversions/black?logo=python&style=flat-square)
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/isac322/docker_image_blackd/master?logo=github&style=flat-square)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/isac322/docker_image_blackd/ci/master?logo=github&style=flat-square)
![Dependabpt Status](https://flat.badgen.net/github/dependabot/isac322/docker_image_blackd?icon=github)

Supported platform: `linux/amd64`, `linux/arm64/v8`, `linux/386`, `linux/arm/v7`

## Tag format

`isac322/blackd:<black_version>`

## Command

Default Entrypoint of image is `blackd`.

And Command are `--bind-host 0.0.0.0 --bind-port 80`.

## How to run

`docker run -p 80:80 -ti isac322/blackd` will launch blackd server inside and expose it to host machine.

Visit http://localhost . If you see `405: Method Not Allowed` error then it succeed.

Please refer [official blackd document](https://github.com/psf/black#blackd)
