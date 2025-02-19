# Node (pnpm) ------------------------------------------------------------------
FROM node:20-slim AS ui
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
COPY . /usr/src/yt-dlp-webui

WORKDIR /usr/src/yt-dlp-webui/frontend

RUN rm -rf node_modules

RUN pnpm install
RUN pnpm run build
# -----------------------------------------------------------------------------

# Go --------------------------------------------------------------------------
FROM golang AS build

WORKDIR /usr/src/yt-dlp-webui

COPY . .
COPY --from=ui /usr/src/yt-dlp-webui/frontend /usr/src/yt-dlp-webui/frontend

RUN CGO_ENABLED=0 GOOS=linux go build -o yt-dlp-webui
# -----------------------------------------------------------------------------

# dependencies ----------------------------------------------------------------
FROM cgr.dev/chainguard/wolfi-base

RUN apk update && \
apk add ffmpeg ca-certificates python3 py3-pip wget

VOLUME /downloads /config

RUN python3 -m pip install yt-dlp

WORKDIR /app

COPY --from=build /usr/src/yt-dlp-webui/yt-dlp-webui /app

ENV JWT_SECRET=secret

EXPOSE 3033
ENTRYPOINT [ "./yt-dlp-webui" , "--out", "/downloads", "--conf", "/config/config.yml", "--db", "/config/local.db" ]