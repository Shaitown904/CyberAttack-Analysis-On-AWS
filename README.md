# CyberAttack-Analysis-On-AWS
This repository is for the Cyberattack-Analysis Project(hosted on AWS) 

# Table of Contents
  - Project Objectives
  - Prerequisites
  - Project Fetures/Topology
  - Project Steps
  - Findings/Outcomes
  - Conclusion/Remeidiation Statagies based on Data collected
  - Contributers

# Project objectives
In this project, I deployed an AWS envoinment I could use as a HoneyPot/Net to analyis cyberattack patterns to stay updated on current trends and new forms of attack if any.

# Prerequisites 
  1. An AWS free tier account
  2. A host machine(Windows, Linux, MacOS)
  3. Terraform installed for IaC
  4. VSCode or any code editor of your choice

# Project Fetures/Topology
In this project I used the following tools: 
  - AWS services such as ec2 and VPC to host the HoneyPot/Net envionrment
  - 2 Ubuntu Servers from ec2 hosted in the VPC
  - Cowrie for HoneyPot Creation
  - Splunk for Log analyis

# Project Steps

###Deploying the AWS enviornment
  1. Create a project folder
  2. Open VS code and open a terminal window
  3. Navigate to the project folder `cd /path/to/project_folder`
  4. Run the command `git clone https://github.com/Shaitown904/Cyberattack-Analysis-with-AWS` to clone repository files
  5. Open deploy.tf and use your own AWS access keys for CLI
  6. Edit the deploy.tf file to meet your needs
  7. In the terminal, run Terraform init to initilaize Terraform
  8. Next, run Terraform plan to check what resources will be built
  9. Lastly, run Terraform apply to deploy the infrastructure
  10. You should have 2 Ubuntu instances with the Tags `HoneyPot` and `Splunk_Server`
      ![Screenshot 2025-06-01 112031](https://github.com/user-attachments/assets/a8700ac8-1398-4649-9d53-661e2bf8238e)

###Install Splunk 
  1. SSH into the Splunk_Server instance
  2. Use the `Install-Splunk.sh` script to update the system and install Splunk
     ![Screenshot 2025-06-01 104111](https://github.com/user-attachments/assets/70f81a3d-fd7b-4a24-8cac-114910c12a7d)
  3. After the installation you need to add admin credentals to log into Splunk

     i. navigate to `/opt/splunk/etc/system/local` and create the file `user-seed.conf`

     ii. add the following to the file  
         ![Screenshot 2025-06-01 103941](https://github.com/user-attachments/assets/9f7e81ec-fc71-42f6-86dc-cc7c89d524cf)
     iii. Restart Splunk with `sudo /opt/splunk/bin/splunk restart`

     iv. Verify if Splunk is running
         ![Screenshot 2025-06-01 104230](https://github.com/user-attachments/assets/2bc16c5c-5975-4f57-8d10-5c995671374a)
     v. Visit `http://<your_instance_publicIP>:8000`
         You should get to your Splunk login screen
         ![Screenshot 2025-06-01 104520](https://github.com/user-attachments/assets/69db1620-e65f-4ab2-8f6e-0b2e925350a2)

         
