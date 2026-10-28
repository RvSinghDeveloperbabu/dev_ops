# syntax=docker/dockerfile:1
#
# Production image for the Rails API.
# The SAME image also runs Sidekiq and the migration Job (they override the command).
#
# Build:  docker build -t myapp/rails-api:1.0.0 .
#
# Set RUBY_VERSION to match your .ruby-version file.
#
# WHY WE ADD IT:
#   Kubernetes does not build code. It only RUNS images. So first you build an
#   image with this Dockerfile (you know this part), then the YAML files in k8s/
#   say "run this image". This Dockerfile is "production style" (not for development):
#   multi-stage = compilers are used to build gems, then thrown away, so the final
#   image is small and safer. It runs as a normal user (uid 1000), not root.
#   One image, three jobs: API (default CMD), Sidekiq and migration (k8s `command:`).
#
# WHAT IF YOU CHANGE THE APP NAME?
#   The Dockerfile itself has no app name. The name is chosen when you BUILD:
#     docker build -t myapp/rails-api:1.0.0 backend/
#   Example: you build with `-t shop/api:1.0.0` instead.
#     -> Kubernetes still looks for `myapp/rails-api:1.0.0`, does not find it,
#        and the pods show ImagePullBackOff.
#     -> FIX: set `image: shop/api:1.0.0` in 30-rails-api.yaml, 31-sidekiq.yaml
#        and 20-migrate-job.yaml (all three).
#   Local cluster note: with k3d, load the image first:
#     k3d image import shop/api:1.0.0 -c <your-cluster-name>
#   (A real cluster pulls from a registry such as Docker Hub or Amazon ECR, so
#    the name would also contain the registry, e.g. 123456.dkr.ecr.../shop/api:1.0.0.)
ARG RUBY_VERSION=3.3

# ---------- base: what every stage shares ----------
FROM ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails

# Runtime OS packages only. libpq5 lets the pg gem talk to Postgres.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 libyaml-0-2 && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

# ---------- build: compile gems, then throw the compilers away ----------
FROM base AS build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Copy only the Gemfiles first, so Docker caches the slow `bundle install`
# layer and reuses it until your gems change.
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Now copy the application code (filtered by .dockerignore).
COPY . .

# Speeds up boot if you use bootsnap (it is in the default Rails Gemfile).
# Delete this line if your app does not use bootsnap.
RUN bundle exec bootsnap precompile app/ lib/

# ---------- final: small runtime image, no compilers ----------
FROM base
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as a non-root user (uid 1000). The Kubernetes manifests enforce this too.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

EXPOSE 3000

# Default command = the web server (Puma).
# Sidekiq and the migration Job override this with `command:` in their manifests.
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
