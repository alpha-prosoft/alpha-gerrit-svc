# VPC First steps

- Create Internet Gateway and attach to VPC

## Build and run

Builds the AMI via `cbd-jenkins-pipeline/ext/build.sh`. Arguments are the resource name
(default `gerrit`) and the environment name (default `PIPELINE`):

```
./build-and-deploy.sh gerrit PIPELINE
```

The script then deploys the image via `cbd-jenkins-pipeline/ext/run.sh`. To only deploy an already built
image run `BUILD_ID=<id> target/run.sh gerrit PIPELINE`
(`target/run.sh` is downloaded by `build-and-deploy.sh`).
