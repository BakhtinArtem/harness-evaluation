FROM ubuntu:22.04 AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libssl-dev git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/giltene/wrk2.git /wrk2 && \
    cd /wrk2 && make -j"$(nproc)"

FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends libssl3 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /wrk2/wrk /usr/local/bin/wrk2

ENTRYPOINT ["wrk2"]
