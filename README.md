# Runsonlocal
Create ephemeral remote Buildkit instance that can accelerate local builds and destroyed when done.

Uses AWS infrastucture and takes advantage of its per-second billing.

## Get Started
Prerequisite:
 - [Tailscale](https://tailscale.com/) account
 - AWS account
 - [Terraform](https://developer.hashicorp.com/terraform/install) installed
 - [Packer](https://developer.hashicorp.com/packer/install) installed


1. Create an AWS IAM user that has permissions to create resources.
2. Modify Tailscale's ACL to create a tag. Assign owner and ip address pool for this tag.
```json
	"tagOwners": {
		"tag:ec2machine": ["your-tailscale-login@gmail.com"],
	},

	"nodeAttrs": [
		{"target": ["tag:ec2machine"], "ipPool": ["100.123.45.0/32"]},
	],
```
3. Create an auth key at Tailscale, check the "Ephemeral" flag and assign the tag.
4. Populate the `terraform.tfstate` file in each folder, following the example files given.
5. Create AMI using packer, you will get 2 AMI at the end of the output. Replace the `ami` attribute in [ec2/main.tf](ec2/main.tf).
```shell
cd ami/
packer init .
packer build buildkit.pkr.hcl
```

6. Run the following command in sequence,
```shell
cd iam/
terraform init
terraform plan
terraform apply

cd ../s3
terraform init
terraform plan
terraform apply

cd ../ec2
terraform init
terraform plan
terraform apply
```

7. In local docker buildx, run the following command to create a remote builder and use it.
```
docker buildx create --name remote-builder --driver remote tcp://100.123.45.0:9999
docker buildx use remote-builder
docker buildx build -t test \
  --cache-to type=s3,region=us-east-1,bucket=buildkit-cache-bucket,mode=max,name=test \
  --cache-from type=s3,region=us-east-1,bucket=buildkit-cache-bucket,name=test .

# to remove the remote builder
docker buildx rm remote-builder
```

8. To destroy the instance after use, run the following command
```
cd ec2/
terraform destroy --target=aws_instance.buildkit
```

9. This will leave the other resources except EC2 intact, saving time when building the instance next time.

10. To destroy everything except AMI, run `terraform destroy` inside the folder `ec2`, `s3`, `iam` in sequence.

11. To destroy AMI, head over to AWS console, EC2 > AMIs > Select the AMIs > Actions > Deregister AMI. Then head over to Snapshots > Select the snapshot > Actions > Delete snapshot.

## Total Cost of Ownership
The expected costs is as follow:
 - Cost for the snapshot used by 2 AMIs: (4518 + 4821 blocks) * 512KiB * 0.05 USD /GB = ~ $0.23 per month
 - Cost for the EC2 instances (billed by second), use `c7i-flex.4xlarge` spot instance as example, $0.2432/hour. It can be much cheaper if you choose to use older generation and smaller instance.
 - S3 storage cost and EBS volume cost, depending on the usage, can be vary.