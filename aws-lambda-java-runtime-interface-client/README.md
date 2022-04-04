Prerequisites:
 * maven (`mvn` binary)
 * Docker must be installed and running

Run these commands to build the AWS Lambda Java Runtime Interface Client library:

```
git clone git@github.com:aws/aws-lambda-java-libs.git
cd aws-lambda-java-libs
cd aws-lambda-java-runtime-interface-client
mvn package -Dmaven.test.skip
```

The build took approx. 63 minutes on my machine.

The build output files are placed in `./target`, and that folder
has been copied into this repository (built from commit
2448acca33d04b2aa3d3ca8d3f6b366b8a59fb40, from 2022-04-04).
