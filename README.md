# registry-api-deploy

Runtime home (`PORTO_API_HOME`) for the **registry** API. The Spring Boot host lives in [porto-api](../../projects/porto-api); plugin sources live in [porto-api-plugins](../../projects/porto-api-plugins). This tree is the product: config, plugin YAML, Liquibase, and Docker.

Product / plugin architecture: [`config/registry/registry-product.md`](config/registry/registry-product.md). HTTP contract: [`config/registry/openapi.yaml`](config/registry/openapi.yaml).

## Layout

```
registry-api-deploy/
├── config/
│   ├── api-dev.yml / api-prod.yml    # this product only
│   └── registry/                     # Spring YAML, adapter registries, Liquibase, OpenAPI
├── plugins/{layer}/registry/         # plugin YAML (tracked) + JARs (gitignored)
├── data/                             # H2 files (gitignored)
├── logs/
├── bin/start.sh
├── bin/start-docker.sh
├── Dockerfile
└── docker-compose.yml
```

## Run locally

Package plugins into this home, then start the host with `PORTO_API_HOME` pointing here:

```bash
cd ~/projects/porto-api-plugins
mvn package -Dporto.api.home=$HOME/sources/registry-api-deploy

export PORTO_API_HOME=$HOME/sources/registry-api-deploy
export API_ENV=dev
export LOG_PATH=$PORTO_API_HOME/logs
cd ~/projects/porto-api && ./mvnw spring-boot:run
```

Or from this directory (uses a copied boot jar if present, otherwise `spring-boot:run` from `PORTO_API_SRC`):

```bash
./bin/start.sh
```

Health: `GET http://localhost:9091/api/v1.0.0/health`

Dev H2 is in-process TCP on port **9092** (`jdbc:h2:tcp://127.0.0.1:9092/registry`).

## Docker

```bash
./bin/start-docker.sh
```

That packages porto-api and porto-api-plugins (`-Dporto.api.home=$PWD`), copies the boot jar as `porto-api.jar`, and runs `docker compose up --build`. The container mounts this directory at `/runtime`.

Prod Postgres (optional compose profile):

```bash
API_ENV=prod ./bin/start-docker.sh --profile prod
```

`registry-prod.yml` expects `REGISTRY_DB_*` (defaults in `docker-compose.yml` point at the `postgres` service).

Requires Docker Compose v2.20+ (`depends_on.required`).

## Plugin JARs

`mvn package -Dporto.api.home=$HOME/sources/registry-api-deploy` in porto-api-plugins copies each module jar to `plugins/{layer}/registry/`. Day-to-day, a gitignored `porto-api-home.properties` in the plugins repo can hold that path so you omit `-D`.
