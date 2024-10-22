# Runsonlocal
Create ephemeral remote Buildkit instance that can accelerate local builds and destroyed when completed the job.

Utilises AWS infrastucture and takes advantage of its per-second billing.

## Get Started
Prerequisite:
 - Tailscale account
 - AWS account


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
5. Replace the `user_data` attribute in [ec2/main.tf](ec2/main.tf)'s aws_instance resource with the content inside [ec2/user_data.txt](ec2/user_data.txt). And also replace the `ami` attribute value with "ami-06b21ccaeff8cd686". Then run step 6 to create all the resources. Once you're done, come back here again.

When you come back:

    - Create an image snapshot of the running instance via AWS console. (Actions > Image and templates > Create image).

    - Record down the ami id, and replaced the `ami` attribute in [ec2/main.tf](ec2/main.tf).

    - Restore the content of `user_data` and `ami` attribute.

Why are we doing this? Installing docker, git and tailscale every time we create an instance is slow. Snapshotting them and use the AMI to launch is faster.

6. Run the following command in sequence,
```
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

10. To destroy everything, run `terraform destroy` inside the folder `ec2`, `s3`, `iam` in sequence.