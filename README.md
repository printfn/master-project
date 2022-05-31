# 42 Editor and Bug Bounty Programme

## Installation

* Create an AWS account at https://aws.amazon.com
* Install the [AWS CLI](https://aws.amazon.com/cli/) (e.g. `brew install awscli`)
* Run `aws configure` to set up the AWS credentials
* Download [Terraform](https://www.terraform.io/) using e.g. `brew install terraform`. Make sure it's added to the `PATH`.
* Other necessary programs: `git`, `make`, `curl`, `zip`, `mvn`, and Java 8 and 16

```sh
make safeNativeCode
make zip

# Terraform
cd lambda
# set the deployment region, e.g. ap-southeast-2 for Sydney, for other regions see
#   https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
echo 'aws_region = "ap-southeast-2"' > terraform.auto.tfvars
terraform init
terraform apply --auto-approve
```

* Set the deployed AWS Lambda URL (shown in the output of `terraform apply`) in `editor/urls.js`
* Deploy the `editor` folder to a web server as a static website (e.g. on GitHub Pages)

## Teardown

```sh
cd lambda
terraform destroy --auto-approve
```

Then you can remove the deployed static website.
