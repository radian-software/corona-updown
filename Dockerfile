FROM radiansoftware/sleeping-beauty:v4.1.0 AS sleepingd

# EOL: April 2031
FROM ubuntu:26.04

RUN apt-get update && apt-get install -y --no-install-recommends python3-venv python3-poetry-plugin-export tini && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY pyproject.toml poetry.lock /src/
RUN poetry export > requirements.txt

RUN python3 -m venv /venv
ENV VIRTUAL_ENV=/venv
ENV PATH=/venv/bin:${PATH}
RUN pip3 install -r requirements.txt

COPY app.py auth.html index.html /src/

ENV SLEEPING_BEAUTY_COMMAND="gunicorn -b 127.0.0.1:5000 app:app"
ENV SLEEPING_BEAUTY_TIMEOUT_SECONDS=15
ENV SLEEPING_BEAUTY_COMMAND_PORT=5000
ENV SLEEPING_BEAUTY_LISTEN_PORT=8080

COPY --from=sleepingd /sleepingd /usr/local/bin/sleepingd
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleepingd"]
EXPOSE 8080
