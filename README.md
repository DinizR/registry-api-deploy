# registry-api-deploy

Runtime home (`PORTO_API_HOME`) for the **registry** API. The Spring Boot host lives in [porto-api](../porto-api); plugin sources live in [porto-api-plugins](../porto-api-plugins). This tree is the product: config, plugin YAML, Liquibase, and Docker.

Product / plugin architecture: [`config/registry/registry-product.md`](config/registry/registry-product.md). HTTP contract: [`config/registry/openapi.yaml`](config/registry/openapi.yaml).

Clone the three trees next to each other (default layout used below):

```
~/projects/porto-api
~/projects/porto-api-plugins
~/projects/registry-api-deploy
```

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

## IntelliJ: one window for host, plugins, and this deploy

Keep **porto-api**, **porto-api-plugins**, and **this deploy** in the same IntelliJ window so you can jump from a Java plugin to YAML, Liquibase, and OpenAPI. Add **this** product only — do not also add `shine-media-api-deploy` if you run the API here (both use port 9091 / H2 9092).

Do **not** use **File → Open…** on this deploy. IntelliJ only offers **Attach** for another Maven/Gradle/IntelliJ project. This repo has no `pom.xml`, so that button never appears (and Open would replace or split the window you already have).

### If porto-api is already open (and plugins may already be added)

This is the usual case.

**porto-api-plugins** (skip if the Maven tool window already lists it):

1. Open the **Maven** tool window.
2. Click **+** (Add Maven Project) and choose `~/projects/porto-api-plugins/pom.xml`.

**This deploy** (not Maven — a different action):

1. **File → New → Module from Existing Sources…**
2. Select the folder `/Users/YOUR_USER/projects/registry-api-deploy` → **Open**.
3. Choose **Create module from existing sources**.
4. On the next screen, set the module directory to `/Users/YOUR_USER/projects/registry-api-deploy` (leave the files in this repo; do not copy them into porto-api).
5. **Create**.

You should see `registry-api-deploy` as its own module in the **Project** tool window (view mode **Project**, not Packages). IntelliJ may write a local `.iml` here; it is gitignored.

### Project settings

- **Project SDK / Language level:** Java 17 (same as porto-api).
- **Maven:** auto-import for porto-api and porto-api-plugins only.
- **porto-core:** install once so both Maven projects resolve: `cd ~/projects/porto-core && mvn install -DskipTests`.
- Do **not** add this deploy with the Maven **+** button. It is `PORTO_API_HOME`, not a build.

### Copy plugin JARs into this home

IntelliJ compile of porto-api-plugins is not enough: the host loads JARs from `plugins/` in this directory.

From a terminal, or IntelliJ Maven tool window on **porto-api-plugins** → `package`:

```bash
cd ~/projects/porto-api-plugins
mvn package -Dporto.api.home=$HOME/projects/registry-api-deploy
```

Day-to-day, copy `porto-api-home.properties.example` to a gitignored `porto-api-home.properties` in porto-api-plugins and set:

```
porto.api.home=/Users/YOUR_USER/projects/registry-api-deploy
```

Then a plain `mvn package` copies JARs here. `-Dporto.api.home=…` still wins when set.

## Run in IntelliJ

1. Package plugins into this home (previous section).
2. Open `systems.porto.api.PortoApiApplication` in the **porto-api** tree.
3. **Run → Edit Configurations… → + → Application** (or use the gutter run on `main`):
   - **Name:** `registry-api`
   - **Module / classpath:** `porto-api`
   - **Main class:** `systems.porto.api.PortoApiApplication`
   - **Working directory:** `~/projects/porto-api` (host tree; runtime files come from `PORTO_API_HOME`)
   - **Environment variables** (semicolon-separated):

```
PORTO_API_HOME=/Users/YOUR_USER/projects/registry-api-deploy;API_ENV=dev;LOG_PATH=/Users/YOUR_USER/projects/registry-api-deploy/logs;LOG_LEVEL=INFO
```

Replace `YOUR_USER` with your home directory name. Without `PORTO_API_HOME` the host fails on start — the porto-api working tree is not a runtime home.

4. Run or debug that configuration.

Health: `GET http://localhost:9091/api/v1.0.0/health`

Dev H2 is in-process TCP on port **9092** (`jdbc:h2:tcp://127.0.0.1:9092/registry`). After changing a plugin, run `mvn package` on porto-api-plugins again so this home’s `plugins/` JARs update, then restart the run configuration.

## Run from the CLI

Package plugins, then start the host with `PORTO_API_HOME` pointing here:

```bash
cd ~/projects/porto-api-plugins
mvn package -Dporto.api.home=$HOME/projects/registry-api-deploy

export PORTO_API_HOME=$HOME/projects/registry-api-deploy
export API_ENV=dev
export LOG_PATH=$PORTO_API_HOME/logs
cd ~/projects/porto-api && ./mvnw spring-boot:run
```

Or from this directory (uses a copied boot jar if present, otherwise `spring-boot:run` from `PORTO_API_SRC`, default `$HOME/projects/porto-api`):

```bash
./bin/start.sh
```

Same health URL and H2 port as IntelliJ.

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

`mvn package -Dporto.api.home=$HOME/projects/registry-api-deploy` in porto-api-plugins copies each module jar to `plugins/{layer}/registry/`. Day-to-day, a gitignored `porto-api-home.properties` in the plugins repo can hold that path so you omit `-D`.
