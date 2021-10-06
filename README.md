# run-latest-build

1. Run `./install-service.sh`.
2. Copy file `run-latest-build.env.template` to file `run-latest-build-NAME.env`,
   where `NAME` must be the same as the name of the service that will be checking
   for new builds.
3. Run `./start-service.sh NAME`, where name is the same as in step 2.
