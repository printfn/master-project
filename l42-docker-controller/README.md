# Running L42 as Docker container

## Commands

### Build

```bash
docker system prune -a -f
cp -f ../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar .
docker build --network=host --tag l42-docker-controller .
```

### Run

```bash
docker run --publish 8000:8000 -it l42-docker-controller
```

### Debug

```bash
docker run --publish 8000:8000 -v "$(pwd)/../l42-examples:/opt/app/examples" -it l42-docker-controller /bin/sh
```
