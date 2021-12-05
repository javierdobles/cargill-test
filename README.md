# Welcome Cargill-Test

this repo is the test from Cargill Company, please read carefully all steps, don't skip any step for a successful setup

## Requirements

 - Terraform v1.0.11
 - Ansible 2.9.6
 - Packer 1.7.8
 - Ubuntu 20.04.3 LTS
 - envchain for credentials setup with MacOS (Optional)
 - aws-vault for credentials manage (Optional)

# Docker

if you want to create a new image based in my docker file, please run the next command:

    cd docker && docker image build -t cargill-nginx
 
then you need to tag the image:

    docker tag javierdobles/cargill-nginx:latest

 after the above command is completed now, you need to push your image to your hub:
 

    docker push javierdobles/cargill-nginx

## Packer
with our new docker image ready, we need to generate now our AWS AMI to be used in our repo, for that, you need to **${REPO_DIR}/packer** and edit the template.json with your aws credentials in **template.json** here: 

    "access_key": "access-here",
    "secret_key": "secret-here",
    
  then when you setup the correct credentials, run the command below:
  

    packer build -var subnet_id=SUBNET_ID template.json
where the subnet-id can the the default subnet from your aws account, this command is going to create the **AMI_ID** for our terraform setup, this AMI contains all the automation for docker, download the image and run it, also installed most of the packages used for our instances

## Prepare the Environment

this step to generate the ssh keys required for your terraform, please execute the command below:

    cd ${REPO_DIR}/terraform/ansible && ansible-playbook prepare-deployment.yml
the command above is going to generate a folder under **${REPO_DIR}/terraform/** with the name of ssh_key, those keys are going to be use by terraform for the keypair setup for ec2 instances.

for the aws credentials, please fill the file **${REPO_DIR}/terraform/main.tf** in the fields below:
 

       "access_key": "access-here",
       "secret_key": "secret-here",
also you need to change the ami-id to be used with the terraform repo in this file **${REPO_DIR}/terraform/deployments.auto.tfvars** in this field:

    "nginx"  =  "ami-0745a9330b2b76219"
when the above step is completed, now we can proceed with the run.

## Run IaaC
when all the steps above are now completed, now we can execute the last playbook which is **${REPO_DIR}/terraform/ansible/run_terraform.yml** with the command below:

    ansible-playbook run_terraform.yml

this playbook is going to run terraform plan as default, the only way to execute **terraform apply** is by adding a commit message: **#apply** as the last commit in the repo, this because we want to avoid apply from users without enough permissions in the repo, it created an script: **tf-wrapper** which is going to run all our terraform commands

