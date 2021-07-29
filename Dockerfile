FROM python:alpine AS builder

COPY requirements.txt /tmp/requirements.txt
RUN apk add --update gcc musl-dev make && \
    pip wheel -r /tmp/requirements.txt --wheel-dir /tmp/wheels

FROM python:alpine

MAINTAINER 'Byeonghoon Isac Yoo <bh322yoo@gmail.com>'

COPY --from=builder /tmp/wheels/* /tmp/wheels/
RUN pip install /tmp/wheels/*.whl && rm -rf /tmp

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/blackd"]
CMD ["--bind-host", "0.0.0.0", "--bind-port", "80"]