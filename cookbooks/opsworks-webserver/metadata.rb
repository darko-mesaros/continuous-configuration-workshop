name "opsworks-webserver"

maintainer "AWS"
maintainer_email "you_email@example.com"
license "Apache 2.0"
description "Installs/Configures OpsWorks Example Cookbook"
long_description "Installs/Configures delete_me"
version "0.1.0"
chef_version ">= 12.14" if respond_to?(:chef_version)
issues_url "https://github.com/<insert_org_here>/example/issues"
source_url "https://github.com/<insert_org_here>/example/issues"
supports "debian"

depends "nginx"
