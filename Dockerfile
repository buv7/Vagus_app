# Use the official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the app
RUN flutter build web

# Expose port
EXPOSE 3000

# Run the app
CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]
