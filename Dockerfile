FROM radiansoftware/sleeping-beauty:v4.1.0 AS sleepingd

# EOL: April 2027
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y curl python3 python3-pip tini && rm -rf /var/lib/apt/lists/*
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH=/root/.local/bin:$PATH
ENV POETRY_VIRTUALENVS_CREATE=false

WORKDIR /src

COPY pyproject.toml poetry.lock /src/
RUN poetry install

COPY app.py auth.html index.html /src/

ENV SLEEPING_BEAUTY_COMMAND="gunicorn -b 127.0.0.1:5000 app:app"
ENV SLEEPING_BEAUTY_TIMEOUT_SECONDS=15
ENV SLEEPING_BEAUTY_COMMAND_PORT=5000
ENV SLEEPING_BEAUTY_LISTEN_PORT=8080

COPY --from=sleepingd /sleepingd /usr/local/bin/sleepingd
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleepingd"]
EXPOSE 8080
