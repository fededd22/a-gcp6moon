FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund
COPY server.ts tsconfig.json ./
RUN npm run build

FROM node:22-slim
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl unzip ca-certificates \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force
RUN mkdir -p bin data \
  && curl -fL -o /tmp/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/v5.14.1/v2ray-linux-64.zip \
  && unzip -o /tmp/v2ray.zip -d bin \
  && chmod +x bin/v2ray \
  && rm /tmp/v2ray.zip
COPY --from=build /app/dist ./dist
COPY server.ts config.json docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh \
  && useradd --uid 10014 --no-create-home --shell /usr/sbin/nologin app \
  && chown -R 10014:10014 /app
ENV DATA_DIR=/app/data
EXPOSE 3000
USER 10014
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "dist/server.cjs"]
