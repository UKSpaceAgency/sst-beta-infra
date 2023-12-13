# Monitor your satellites (infrastructure)

`sst-beta-infra` is the Terraform code for managing the Monitor your satellites infrastructure on AWS Cloud. Monitor your satellites is the collision avoidance service for UK registered satellites.

## Technical documentation

### Before you start
You will need an account on [AWS](https://aws.amazon.com/). You will also need to [install Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform).

### Initialising the infrastructure
Navigate to the `aws` folder and run `terraform init`. You can then run `terraform apply` to build the infrastructure.

You will need to ask the team for any secrets required (e.g. Auth0, etc)

### Additional docs
* [Tech docs website for Monitor your satellites - including further architecture information](https://mys-tech-docs.onrender.com/)

## Licence
[MIT Licence](LICENCE)

## Support
This software is maintained by the team at: `monitoryoursatellites [at] ukspaceagency [dot] gov [dot] uk`