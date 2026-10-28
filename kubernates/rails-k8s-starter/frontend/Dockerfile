# syntax=docker/dockerfile:1
#
# Stage 1 builds the React app into static files.
# Stage 2 serves those files with nginx. Node is not in the final image.
#
# Build:
#   docker build --build-arg VITE_API_URL=http://api.localhost:8080 -t myapp/frontend:1.0.0 .
#
# WHY WE ADD IT:
#   Same reason as the backend Dockerfile: Kubernetes only runs finished images.
#   Multi-stage: Node builds the React files, then only the plain files are copied
#   into a tiny nginx image. The final image has no Node, so it is small and safe.
#
# WHAT IF YOU CHANGE THE APP NAME?
#   - Image name is set by `-t` at build time. Example: `-t shop/web:1.0.0`
#     -> change `image:` in k8s/32-frontend.yaml to `shop/web:1.0.0`, or you get
#        ImagePullBackOff.
#   - VITE_API_URL is the address the BROWSER uses to call the API. It must match
#     the API host in k8s/40-ingress.yaml.
#     Example: you change the Ingress host from api.localhost to api.shop.localhost.
#       -> You must rebuild with --build-arg VITE_API_URL=http://api.shop.localhost:8080
#          and use a NEW tag (1.0.1). The old image still calls api.localhost,
#          because the URL is baked into the JavaScript file. The browser then shows
#          "Failed to fetch" / network errors.

# Match your project's Node version.
FROM node:22-alpine AS build
WORKDIR /app

# Install dependencies first for layer caching.
# (Using yarn or pnpm? Copy their lockfile and run their install command instead.)
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# React reads environment variables at BUILD time, not at runtime:
# the API URL is baked into the JavaScript bundle on the next line.
# Vite needs the VITE_ prefix. Create React App needs REACT_APP_ (rename both lines).
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

# ---------- final: nginx serving static files ----------
FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Vite outputs to dist/. Create React App outputs to build/ (change the path).
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
