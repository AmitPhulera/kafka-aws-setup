Extracts a part of commcare infra and runs it on backup-production env.

To setup infra on backup-production env:
1. The network settings have been copied from commcare-cloud to `terraform.tf`. Which have a module called `server__kafka_backup-production` and `server__control4-backup-production` which is copied from `path/to/commcare_cloud/environments/production/.generated-terraform/commcare-hq.tf` and then relevant settings were updated.

2. Commcare-hq.tf has different modules for each for each kafka machine but in this setup we are using count variable to setup instances in availablity zones. Currently we have a variable called `server_name` and `az` which help in generating these servers.

3. Run 

```
aws configure sso
```
To setup sso for aws cli. It will ask you for `sesion-name`, call it backup-production and will ask for sso_start_url and sso_region. Set the values to `https://dimagi.awsapps.com/start/` and `us-east-1`

It will open up SSO login screen in your browser. Login and allow access to the account.
It will ask you to select account and role, choose Commcare-Production-Backup click on next and then select AWSAdministratorRole. 

Set `aws-cli-region` as `us-east-2` 
Set `CLI profile` name as `backup-production`.

The terraform scripts are configured to look for `backup-proudction` profile. You can change that from `terraform.tf` file in provider section.

4. Ensure terraform is installed and switch to `terraform` directory run `cd terraform`.

5. Initialize terraform with `terraform init`.

5. Run `terraform plan`. It should give a list of all the things that it should add.

6. To create 3 terraform machines and 1 control machine -  run `terraform apply`

7. Add the following lines to your `~/.ssh/config` file
```
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --profile backup-production  --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```
What is does is that for any hosts starting with i-* or mi-* it will add the following ProxyCommand parameter which will ensure that you can ssh over SSM. If you have a different profile that backup-production you should update it here too.

For this test the instance ids and private IPs of the machines are:

| Instance   | Instance ID          | IP            |
|---|---|---|
| Control    | i-08f79b21c058d9495  | 10.203.10.115 |
| Kafka 0    | i-054f68f93a8973e53  | 10.203.40.211 |
| Kafka 1    | i-048420a5cc3ced4a2  | 10.203.41.91  |
| Kafka 2    | i-058a564d84cbec1c7  | 10.203.42.247 |

The above information can be extracted from AWS console or from `terraform.tfstate` file.

Upate `ansible/inventory.in` with the above values.

8. SSH into control machine - 

```
ssh -i ~/.ssh/ec2_kafka  ubuntu@i-08f79b21c058d9495
```

9. Setup control machine by installing required librariesnstall python-dev, ansible and required libraries

```
sudo apt update

sudo apt install python3-pip python3-dev python3-distutils python3-venv libffi-dev sshpass net-tools
```

If `which python` does not work run - 
```
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10
```

10. Install same ansible version which is present in commcare cloud using pip
```
pip install ansible==4.10.0
```

11. scp `ansible` directory and your private key which is `ec2_kafka` in this example from this repo to the control machine.
```
scp -i ~/.ssh/ec2_kafka ansible.zip ~/.ssh/ec2_kafka ubuntu@i-08adc2003ee8712b0:/home/ubuntu
```

12. From control machine run ansible-playbook `ansible-playbook -i ansible/inventory.ini ansible/playbooks/deploy_kafka.yml`
