# Use Ruby 3.2 as the base image
FROM ruby:3.2-slim

# Install essential Linux packages
RUN apt-get update -qq && \
    apt-get install -y build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install bundler and gems
RUN gem install bundler && \
    bundle install

# Copy the rest of the application
COPY . .

# Expose the port the app runs on
EXPOSE 4567

# Set the entrypoint to bundle exec
ENTRYPOINT ["bundle", "exec"]

# Default command to run the server
CMD ["rackup", "-o", "0.0.0.0", "-p", "4567"]
