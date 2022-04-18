ARG PYTHON_VERSION=3.9.7
ARG APP_FOLDER=/app

# --- STAGE builder: install python-slim-buster ---

FROM python:${PYTHON_VERSION}-slim-buster AS builder

ARG APP_FOLDER

ENV PATH="${PATH}:/root/.poetry/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-dev \
        curl \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# --- STAGE deps_install: install poetry wheels ---

FROM builder AS deps_install

ARG APP_FOLDER

WORKDIR ${APP_FOLDER}

COPY ["./requirements.txt", "./"]

RUN pip wheel \ 
            --no-cache-dir \
            --no-deps \
            --wheel-dir /wheels \
            -r requirements.txt


# --- STAGE user_env_builder: user unprivileged containers ---

FROM python:${PYTHON_VERSION}-slim-buster AS release

ARG APP_FOLDER
ARG APP_USER=gateway_user
ARG APP_GROUP=gateway_group
ARG APP_USER_UID=999
ARG LOG_FOLDER=${APP_FOLDER}/logs

ENV PYTHONPATH="${APP_FOLDER}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Europe/Moscow

RUN groupadd --gid ${APP_USER_UID} --system ${APP_GROUP} 
RUN useradd --uid ${APP_USER_UID} \
            --gid ${APP_GROUP} \
            --no-create-home \
            --system \
            --shell /bin/false \
            ${APP_USER}

WORKDIR ${APP_FOLDER}

COPY --from=deps_install \
     --chown=${APP_USER}:${APP_GROUP} /wheels /wheels
COPY --chown=${APP_USER}:${APP_GROUP} . .

RUN pip install --no-cache /wheels/* \
    && mkdir -p ${LOG_FOLDER} \
    && chown ${APP_USER}:${APP_GROUP} ${LOG_FOLDER}

USER ${APP_USER}

VOLUME ["${LOG_FOLDER}"]

