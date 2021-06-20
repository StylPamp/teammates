FROM gradle:6.5-jdk8

# Install Node 12 in the container

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

# Cache dependencies

COPY build.gradle build.gradle
COPY gradle.docker.properties gradle.properties
RUN gradle downloadDependencies

COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm ci

# Generate type definitions

COPY src/main/java src/main/java
COPY src/web/environments src/web/environments
RUN gradle generateTypes

# Build front-end files

COPY src/web src/web
COPY angular.json angular.json
COPY tsconfig.json tsconfig.json
COPY tsconfig.app.json tsconfig.app.json
COPY ngsw-config.json ngsw-config.json
COPY browserslist browserslist
RUN node --max-old-space-size=4096 $(which npm) run build

COPY src/main src/main
RUN gradle assemble

ENTRYPOINT ["gradle", "serverRun"]

HEALTHCHECK --interval=5s --timeout=3s --retries=10 CMD curl -f http://localhost:8080 || exit 1
