# Stage 1: Build Flutter web app
FROM dart:3.0 AS build

# Create a non-root user
RUN useradd -ms /bin/bash flutteruser

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter channel stable
RUN flutter upgrade
RUN flutter doctor

# Set working directory and change ownership
WORKDIR /app
RUN chown -R flutteruser:flutteruser /app /flutter

# Switch to non-root user
USER flutteruser

# Copy pubspec files
COPY --chown=flutteruser:flutteruser frontend/pubspec.yaml frontend/pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY --chown=flutteruser:flutteruser frontend/ .

# Build web app
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY docker/frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
