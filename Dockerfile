# syntax=docker/dockerfile:1
# Multi-stage production Dockerfile optimized for Kamal 2 deployment

ARG RUBY_VERSION=3.3.0
ARG NODE_VERSION=20

# Base image with Ruby and essential dependencies
FROM ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS="4" \
    BUNDLE_RETRY="3"

# Update gems and install essential packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    libpq5 \
    libjemalloc2 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    pkg-config \
    python3 \
    gnupg2 \
    wget

# Install Node.js and enable Corepack for Yarn
ARG NODE_VERSION
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    corepack enable && \
    corepack prepare yarn@4.2.2 --activate

# Copy Gemfile and Ruby version file, then install gems
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy package.json and Yarn configuration files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn .yarn
RUN yarn install --immutable

# Copy application code
COPY . .

# Precompile bootsnap and assets
RUN bundle exec bootsnap precompile --gemfile && \
    bundle exec bootsnap precompile app/ lib/

# Build assets manually to avoid jsbundling-rails issues
# Railway will provide these as build-time environment variables
ARG RAILS_MASTER_KEY
ARG SECRET_KEY_BASE

# Completely bypass jsbundling-rails and build assets manually
ENV JSBUNDLING_SKIP_BUILD=true
RUN RAILS_ENV=production yarn build && \
    RAILS_ENV=production yarn build:css && \
    mkdir -p public/assets && \
    RAILS_ENV=production bundle exec rake assets:precompile

# Clean up node_modules after asset compilation
RUN rm -rf node_modules

# Final production image
FROM base

# Install runtime dependencies for Active Storage and image processing
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    imagemagick \
    libvips \
    ffmpeg \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    chmod -R 755 /rails/bin

# Switch to non-root user
USER rails:rails

# Set environment variables for jemalloc (memory optimization)
ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"

# Ensure binaries are executable
RUN chmod +x /rails/bin/*

# Entrypoint prepares database and runs migrations
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose port 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Default command starts Puma server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]