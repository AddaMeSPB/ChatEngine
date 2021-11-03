# ================================
# Build image
# ================================
FROM swift:5.4-focal as build

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libsqlite3-dev nano \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build everything, with optimizations and test discovery
RUN swift build --enable-test-discovery -c release

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Run" ./

# Uncomment the next line if you need to load resources from the `Public` directory.
# Ensure that by default, neither the directory nor any of its contents are writable.
#RUN mv /build/Public ./Public && chmod -R a-w ./Public

# ================================
# Run image
# ================================
FROM swift:5.4-focal-slim

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q dist-upgrade -y && rm -r /var/lib/apt/lists/*

# Create a vapor user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vapor:vapor /staging /app
COPY --from=build --chown=vapor:vapor /build/.build/release /app
# Uncomment the next line if you need to load resources from the `Public` directory
#COPY --from=build --chown=vapor:vapor /build/Public /app/Public

# Copy dotenv files
COPY --from=build --chown=vapor:vapor /build/.env /app/.env
#COPY --from=build --chown=vapor:vapor /build/.env.production /app/.env.production
#COPY --from=build --chown=vapor:vapor /build/.env.development /app/.env.development
#COPY --from=build --chown=vapor:vapor /build/.env.test /app/.env.test
# Uncomment the next line if you need to load resources from the `Public` directory
#COPY --from=build --chown=vapor:vapor /build/Public /app/Public
# Uncomment the next line if you need to load resources from the `Resources` directory
#COPY --from=build --chown=vapor:vapor /build/Resources /app/Resources

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Let Docker bind to port 6060
EXPOSE 6060

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "6060"]
