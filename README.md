# Monitor Space Hazards (infrastructure)

`sst-beta-infra` is the Terraform code for managing the Monitor Space Hazards infrastructure on AWS Cloud. Monitor Space Hazards is the space hazards tracking service for UK operators and approved government employees. It includes the formerly Monitor your satellites collision avoidance service, as well as a re-entry and satellite activity monitoring service. 

## Technical documentation

### Before you start
You will need an account on [AWS](https://aws.amazon.com/). You will also need to [install Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform).

### Initialising the infrastructure
Navigate to the `aws` folder and run `terraform init`. You can then run `terraform apply` to build the infrastructure.

You will need to ask the team for any secrets required (e.g. Auth0, etc)

### Additional docs
* [Tech docs website for Monitor Space Hazards - including further architecture information](https://mys-tech-docs.onrender.com/)

## Licence
[MIT Licence](LICENCE)

## Support
This software is maintained by the team at: `monitorspacehazards [at] ukspaceagency [dot] gov [dot] uk`
