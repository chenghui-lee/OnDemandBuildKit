# Use an official base image from Docker Hub
FROM alpine:latest

# Set working directory
WORKDIR /app

# Copy a simple script into the container
COPY hello.sh .

# Make the script executable
RUN chmod +x hello.sh

# Set the default command to run the script
CMD ["./hello.sh"]
