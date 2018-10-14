# Continuous Configuration Workshop - Berlin Pop-up Loft 2018

Here be workshops


### Prerequisites

### Create our VPC and our Nodes

Launch the `nodes-asg-cfn.yml` Cloudformation template in your account. This template will create the following:
- VPC
- Subnets
- Security Groups
- Internet Gateways
- Route Tables with its entries
- IAM Instance profiles
- Autoscaling Group
- Elastic Loadbalancer

### Launching a Chef Automate Server
We need to launch a Opsworks for Chef Automate server via the console or via CLI. 

Here is an example how we do it via the CLI:
```bash
aws opsworks-cm ...
```

But we will do it via the Web console: 

--Insert image here--

### Chef workstation
We will use AWS Cloud9 as our Workstation in order to communicate with the Chef Server. This is the simplest way we can have a workstation configured for managing our Chef Automate environment.

#### Create AWS Cloud9 Environment
- Log into the AWS Web Console (**as a NON root or federated user**) and search for Cloud 9. 
- Once on the Cloud9 Start page, click the `Create environment` button.
- Enter the name and description of your Environment - this can be anything. 
- When configuring settings we can keep everything as default - assuming you are creating it in the Default VPC. The important part is that your Cloud9 environment has access to the internet. 
![cloud9_configscreen](images/cloud9_configscreen.png)
- On the review page, review your settings and click the `Create` button.

It will take a few minutes for the environment to get created.

#### Configure the workstation

First off, what we need to install is the [Chef Development Kit](https://downloads.chef.io/chefdk). As our Cloud9 is running Amazon Linux under the hood we can use the RHEL 7 version of the ChefDK.
```bash
wget https://packages.chef.io/files/stable/chefdk/3.3.23/el/7/chefdk-3.3.23-1.el7.x86_64.rpm
sudo rpm -ivh chefdk-3.3.23-1.el7.x86_64.rpm
```
We should now have the `knife` command available if our ChefDK installed succesfully. 
