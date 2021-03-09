FROM python:latest AS builder

COPY requirements.txt /tmp/requirements.txt
RUN pip wheel --no-binary :all: -r /tmp/requirements.txt --wheel-dir /tmp/wheels

FROM python:alpine
COPY --from=builder /tmp/wheels/* /tmp/wheels/
RUN pip install /tmp/wheels/*.whl

ENTRYPOINT ["/usr/local/bin/blackd"]
CMD ["--bind-host", "0.0.0.0", "--bind-port", "80"]