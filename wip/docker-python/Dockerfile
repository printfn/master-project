# build: docker build --network=host --tag python-docker .
# run: docker run --publish 80:80 python-docker
# test: curl localhost:80
# get container name: docker ps
# remote: docker exec -u root -it <container name> bash

# syntax=docker/dockerfile:1
FROM python:3.9-slim-buster

WORKDIR /app

ENV FLASK_ENV=development
ENV FLASK_APP app.py
ENV FLASK_RUN_HOST 0.0.0.0
ENV FLASK_RUN_PORT 80

COPY requirements.txt requirements.txt

RUN pip3 --no-cache-dir install -r requirements.txt

COPY . .

CMD ["flask", "run"]
