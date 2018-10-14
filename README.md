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

### First steps on our Chef Automate server

#### Accessing our Chef Automate server for the first time

What we need now is the starter kit we hav acquired during the launch of our Opsworks for Chef Automate server. Unzip that starter kit somewhere on your Chef workstaiton. 
And lets see if we can communicate with our chef server:
```
cd starter_kit_directory
knife ssl fetch
```
If we get no errors - we should be able to start installing our first cookbook to the Chef server.

#### Installing the `chef-client` cookbook

One of the key cookbooks we will use is the [chef-client]() cookbook. This cookbook configures the chef-client service on the node and we can use the cookbooks attributes to configure the default behavior of the service.

The easiest way of installing this is via the use of `Berkshelf`. So, lets do so:
- Edit the `Berksfile` in your starter kit directory and make sure that there are only the following lines(remove the rest):
```
source "https://supermarket.chef.io"
cookbook "chef-client"
```
- Save the file and run `berks vendor cookbooks` from the root of your starter kit directory. The output should be something like this:
```
Resolving cookbook dependencies...
Fetching cookbook index from https://supermarket.chef.io...
Installing chef-client (11.0.1)
Installing cron (6.2.1)
Installing logrotate (2.2.0)
Vendoring chef-client (11.0.1) to cookbooks/chef-client
Vendoring cron (6.2.1) to cookbooks/cron
Vendoring logrotate (2.2.0) to cookbooks/logrotate
```
- Time to upload those cookbooks! Run `knife upload cookbooks`

If everything was succesfull we should be able to see the `chef-client` cookbook (and its dependencies) on our chef server by running the command `knife cookbook list`
```
chef-client   11.0.1
cron          6.2.1
logrotate     2.2.0
```

#### Lets create a role

Time to create a role that will be assigned to our nodes - and in which we can define the cookbooks and attributes to be used. 

To do this - lets create a role in the `roles` directory in our starter kit. Create a file named `popup-role.rb`, with the following contents:
```ruby
name "popup-role"
description "This is an example role"

run_list(
  "recipe[chef-client]"
)
default_attributes "chef_client" => { "interval" => "60", "splay"=> "10" }
```

After this it is time to create the role. We can do that by running the following command:

```
knife role from file roles/popup-role.rb
```

### Bootstrapping nodes

So, we need to bootstrap our nodes! Let's first make some changes to our `userdata.sh` file which has come with out starter kit. In that file we need to change the runlist to contain the role we just created. 

To make this change, replace the following line:
```bash
RUN_LIST="role[opsworks-example-role]"
```
With:
```bash
RUN_LIST="role[popup-role]"
```

To bootstrap our node, lets modify the cloudformation template we used at the beginning - and add the contents of `userdata.sh` from the starter kit.

### Modifying the `userdata` in our Autoscaling group

Lets add the modified `userdata.sh` to our Cloudformation template. Roughly on line 135 find the `LaunchConfig` resource. Here we will replace the `UserData` property from this: 
```yaml
...
  LaunchConfig:
    Type: 'AWS::AutoScaling::LaunchConfiguration'
    Properties:
      ...    
      UserData: 
        'Fn::Base64': !Sub |
          #!/bin/bash
          yum -y update
          yum -y install nginx
          service nginx start
...
```
To something like this (please note, most user data is ommited in this example):
```yaml
...
  LaunchConfig:
    Type: 'AWS::AutoScaling::LaunchConfiguration'
    Properties:
      ...    
      UserData: 
        'Fn::Base64': |
          #!/bin/bash

          # required settings
          NODE_NAME="$(curl --silent --show-error --retry 3 http://169.254.169.254/latest/meta-data/instance-id)" # this uses the EC2 instance ID as the node name
          CHEF_SERVER_NAME="my-opsworks" # The name of your Chef Server
          CHEF_SERVER_ENDPOINT="my-opsworks-wqtxjqwwrazsvrjp.eu-west-1.opsworks-cm.io" # The FQDN of your Chef Server
          REGION="eu-west-1" # Region of your Chef Server (Choose one of our supported regions - us-east-1, us-east-2, us-west-1, us-west-2, eu-central-1, eu-west-1, ap-northeast-1, ap-southeast-1, ap-southeast-2)
        
          # optional
          CHEF_ORGANIZATION="default"    # AWS OpsWorks for Chef Server always creates the organization "default"
          NODE_ENVIRONMENT=""            # E.g. development, staging, onebox ...
          CHEF_CLIENT_VERSION="13.8.5" # latest if empty
        
          # recommended: upload the chef-client cookbook from the chef supermarket  https://supermarket.chef.io/cookbooks/chef-client
          # Use this to apply sensible default settings for your chef-client config like logrotate and running as a service
          # you can add more cookbooks in the run list, based on your needs
          # Compliance runs require recipe[audit] to be added to the runlist.
        
          RUN_LIST="role[opsworks-example-role]" # Use tVhis role when following the starter kit example or specify recipes like recipe[chef-client],recipe[apache2] etc.
        
          # ---------------------------
          ...
...
```
Now, its time to update our CloudFormaton template from the web console with the latest template. 

#### Update Cloudformation stack

Once that is done - to ensure our nodes are running the latest userdata. You need to *terminate* the existing instance launched by the ASG. Once that is performed, the ASG will create a new instance with the new userdata. 
A few minutes after a new ASG instance has been launched, it should show up on our Chef Automate server under 'Nodes'. 

One more way we can check is with the `knife` command from our workstation.

Log into your Chef Workstation, and enter the root of your starterkit. To check the current node list, run the following command:
```bash
knife node list
```
Once the node is bootstrapped - it should show up there as a node (an instance ID should be shown *i-xxxxx*).

