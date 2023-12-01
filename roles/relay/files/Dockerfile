FROM python:3.11-slim-bullseye

WORKDIR /bot
COPY . .

RUN apt-get update && \
    apt-get upgrade -y

RUN pip install -r requirements.txt

ENTRYPOINT [ "python3", "__main__.py" ]
