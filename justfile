# Claude Code Sandbox

set dotenv-load

# Build and start the container
rebuild:
    docker compose up --detach --build --remove-orphans --force-recreate --pull always

# Shell into the container
shell *ARGS:
    docker compose -p ${COMPOSE_PROJECT_NAME} exec claude-sandbox zsh {{ARGS}}

# Stop the container
down:
    docker compose down

# Stop and remove volumes (wipes config and authentication)
reset:
    docker compose down -v
