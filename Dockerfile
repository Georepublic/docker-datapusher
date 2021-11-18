ARG DATAPUSHER_USER=datapusher


FROM python:3.8-slim as datapusher
ARG DATAPUSHER_USER

RUN apt update
RUN apt install -y git build-essential

RUN useradd -m ${DATAPUSHER_USER}
USER ${DATAPUSHER_USER}

RUN pip install --user uwsgi xlrd==1.2.0
RUN pip install --user -r "https://raw.githubusercontent.com/Georepublic/datapusher/master/requirements.txt"
RUN pip install --user "git+https://github.com/Georepublic/datapusher.git@for_docker#egg=datapusher"


FROM python:3.8-slim

ARG DATAPUSHER_USER
ENV PYTHONUNBUFFERED 1
ENV PATH /home/${DATAPUSHER_USER}/.local/bin:${PATH}
ENV GITHUB_URL https://raw.githubusercontent.com/Georepublic/datapusher/feature/for_docker

RUN apt update \
 && apt install -y \
    locales \
    libxslt1-dev \
    libxml2-dev \
    libffi-dev \
    libmagic-dev \
 && rm -rf /var/lib/apt/lists/*
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen

RUN useradd -m ${DATAPUSHER_USER}

USER ${DATAPUSHER_USER}

COPY --from=datapusher --chown=${DATAPUSHER_USER}:${DATAPUSHER_USER} /home/${DATAPUSHER_USER}/.local /home/${DATAPUSHER_USER}/.local

COPY --chown=${DATAPUSHER_USER}:${DATAPUSHER_USER} datapusher-uwsgi.ini /home/${DATAPUSHER_USER}

ADD --chown=${DATAPUSHER_USER}:${DATAPUSHER_USER} \
  ${GITHUB_URL}/deployment/datapusher.wsgi \
  ${GITHUB_URL}/deployment/datapusher_settings.py \
  /home/${DATAPUSHER_USER}/

EXPOSE 8800

CMD [ "uwsgi", "--http", "0.0.0.0:8800", "-i", "/home/datapusher/datapusher-uwsgi.ini" ]
