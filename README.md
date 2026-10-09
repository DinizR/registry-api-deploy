# registry-api-deploy

Runtime home (`PORTO_API_HOME`) for the **registry** API. The Spring Boot host lives in [hexagonalboot-api](../hexagonalboot-api); plugin sources live in [porto-api-plugins](../porto-api-plugins). This tree is the product: config, plugin YAML, Liquibase, and Docker.

Product / plugin architecture: [`config/registry/registry-product.md`](config/registry/registry-product.md). HTTP contract: [`config/registry/openapi.yaml`](config/registry/openapi.yaml).

## Create `porto-workspace` and clone the projects

`porto-workspace` is a directory on disk, not a git repository. Create it, then clone each project into it:

```bash
mkdir -p ~/projects/porto-workspace
cd ~/projects/porto-workspace

git clone git@gitlab.com:shine-group114134/hexagonalboot-api.git
git clone git@gitlab.com:shine-group114134/porto-api-plugins.git
git clone git@gitlab.com:shine-group114134/shine-media-api-deploy.git
git clone git@gitlab.com:shine-group114134/registry-api-deploy.git
```

You should end up with:

```
~/projects/porto-workspace/hexagonalboot-api
~/projects/porto-workspace/porto-api-plugins
~/projects/porto-workspace/shine-media-api-deploy
~/projects/porto-workspace/registry-api-deploy
```

Do not `git init` inside `porto-workspace`. Each child stays its own repo. `porto-core` stays outside the workspace (`~/projects/porto-core`).

### direnv (local workspace `.envrc`)

The workspace folder is not a repo, so it has no committed `.envrc`. After cloning, copy the template from the host and allow direnv:

```bash
cd ~/projects/porto-workspace
cp hexagonalboot-api/docs/porto-workspace.envrc .envrc
# set PORTO_API_APPLICATION=registry to package/run this product
direnv allow
cd hexagonalboot-api && direnv allow
cd ../porto-api-plugins && direnv allow
cd ../shine-media-api-deploy && direnv allow
cd ../registry-api-deploy && direnv allow
```

That workspace file is yours only. Full write-up:
[hexagonalboot-api — Current app (direnv)](../hexagonalboot-api/README.md#current-app-direnv).

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

## IntelliJ: open `porto-workspace` (not a child repo)

Host, plugins, and both deploys live under **`~/projects/porto-workspace`**. That folder is the IntelliJ project (it has `.idea/`). The four trees stay independent — two Maven poms, two deploy homes, no parent `pom.xml`.

**Open this folder only:**

1. Close any old IntelliJ window that pointed at `~/projects`, `~/projects/porto-api`, `hexagonalboot-api`, or this deploy as its own project.
2. **File → Open** `~/projects/porto-workspace`.
3. If IntelliJ asks to import Maven, import **both** `hexagonalboot-api/pom.xml` and `porto-api-plugins/pom.xml` as **separate** Maven projects (not one aggregator). The workspace `.idea` already lists those two.
4. If it does not auto-import: Maven tool window → **+** → `hexagonalboot-api/pom.xml`, then **+** again → `porto-api-plugins/pom.xml`.
5. Project tool window → view mode **Project**. You should see `hexagonalboot-api`, `porto-api-plugins`, `shine-media-api-deploy`, and `registry-api-deploy`.
6. If IntelliJ asks to move or attach the project to `~/projects`, click **No**.

Do **not** **File → Open** this deploy, `hexagonalboot-api`, or `porto-api-plugins` on their own. Child trees may still have leftover `.idea/` folders from before `porto-workspace` existed — ignore those.

Do **not** add a deploy with the Maven **+** button. A deploy is `PORTO_API_HOME`, not a build.

You can keep both deploys in the window. Only **run** one at a time (both use port 9091 / H2 9092).

### Project settings

- **Project SDK / Language level:** Java 21 (same as hexagonalboot-api / Spring Boot 4.1.1).
- **Maven:** auto-import for hexagonalboot-api and porto-api-plugins only.
- **porto-core:** still lives outside the workspace. Install once so both Maven projects resolve: `cd ~/projects/porto-core && mvn install -DskipTests`.

### Copy plugin JARs into this home

IntelliJ compile of porto-api-plugins is not enough: the host loads JARs from `plugins/` in this directory.

From a terminal, or IntelliJ Maven tool window on **porto-api-plugins** → `package`:

```bash
cd ~/projects/porto-workspace/porto-api-plugins
mvn package -Dporto.api.home=$HOME/projects/porto-workspace/registry-api-deploy
```

Day-to-day, copy `porto-api-home.properties.example` to a gitignored `porto-api-home.properties` in porto-api-plugins and set:

```
porto.api.home=/Users/YOUR_USER/projects/porto-workspace/registry-api-deploy
```

Then a plain `mvn package` copies JARs here. `-Dporto.api.home=…` still wins when set.

## Run in IntelliJ

Create the run configuration in the **porto-workspace** window. The main class lives in `hexagonalboot-api`; this directory is only `PORTO_API_HOME`.

1. Package plugins into this home (previous section).
2. Open `systems.porto.api.HexagonalBoot` under **hexagonalboot-api**.
3. **Run → Edit Configurations… → + → Application** (or use the gutter run on `main`), then set:
   - **Name:** `registry-api`
   - **Use classpath of module:** `HexagonalBoot-API` (Maven `artifactId` of the host; IntelliJ may also show `hexagonalboot-api`)
   - **Main class:** `systems.porto.api.HexagonalBoot`
   - **Working directory:** `$USER_HOME$/projects/porto-workspace/hexagonalboot-api`  
     Use the host tree, not `porto-workspace` and not this deploy. Runtime files come from `PORTO_API_HOME`.
   - **Environment variables** (semicolon-separated in IntelliJ). IntelliJ expands `$USER_HOME$`; do **not** leave a `YOUR_USER` placeholder:

```
PORTO_API_HOME=$USER_HOME$/projects/porto-workspace/registry-api-deploy;API_ENV=dev;LOG_PATH=$USER_HOME$/projects/porto-workspace/registry-api-deploy/logs;LOG_LEVEL=INFO
```

If you prefer a literal path, paste the output of `echo $HOME` (for example `/Users/rodrigo/...`). A log path containing `/Users/YOUR_USER/` means the placeholder was copied as-is and the process cannot create the log directory.

Without `PORTO_API_HOME` the host treats the working directory as the runtime home and fails — `hexagonalboot-api` is not a product deploy.

4. Run or debug that configuration.

Do not create an Application configuration on this deploy folder. It has no host classpath.

Health: `GET http://localhost:9091/api/v1.0.0/health`

Dev H2 is in-process TCP on port **9092** (`jdbc:h2:tcp://127.0.0.1:9092/registry`). After changing a plugin, run `mvn package` on porto-api-plugins again so this home’s `plugins/` JARs update, then restart the run configuration.

## Run from the CLI

Package plugins, then start the host with `PORTO_API_HOME` pointing here:

```bash
cd ~/projects/porto-workspace/porto-api-plugins
mvn package -Dporto.api.home=$HOME/projects/porto-workspace/registry-api-deploy

export PORTO_API_HOME=$HOME/projects/porto-workspace/registry-api-deploy
export API_ENV=dev
export LOG_PATH=$PORTO_API_HOME/logs
cd ~/projects/porto-workspace/hexagonalboot-api && ./mvnw spring-boot:run
```

Or from this directory (uses a copied boot jar if present, otherwise `spring-boot:run` from `PORTO_API_SRC`, default `$HOME/projects/porto-workspace/hexagonalboot-api`):

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

`mvn package -Dporto.api.home=$HOME/projects/porto-workspace/registry-api-deploy` in porto-api-plugins copies each module jar to `plugins/{layer}/registry/`. Day-to-day, a gitignored `porto-api-home.properties` in the plugins repo can hold that path so you omit `-D`.
