#!/bin/bash
# Start the backend server directly
docker-compose run -d -e DB_USER=user -e DB_PASSWORD=password -e DB_NAME=ptchampion -e DB_SSL_MODE=disable -e DB_HOST=db -e DB_PORT=5432 --name ptchampion_backend --entrypoint "/app/server_binary" backend 