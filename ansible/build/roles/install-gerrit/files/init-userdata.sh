#!/bin/bash 

set -euo pipefail 

echo "Starting gerrit startup"

echo "###########################################"
echo "We will be extra permission chaging here!"
echo "because we had bugs and sometimes happened that files had wrong permission"
echo "So for existing instalations we will fix permissions and for new ones"
echo "we will make sure that gerrit owns all files"

if [[ ! -f /var/lib/gerrit/is-initialized ]]; then
  echo "Seems like first start so fixing permissions after init just in case"
  chown gerrit:gerrit /var/lib/gerrit -R
  touch /var/lib/gerrit/is-initialized
  chown gerrit:gerrit /var/lib/gerrit/is-initialized
fi

echo "Fix permissions for gerrit.config before edit"
chown gerrit:gerrit /var/lib/gerrit/etc/gerrit.config

su - gerrit -s /bin/sh \
  -c "java -jar /opt/gerrit/gerrit.war init \
           --batch \
           --dev \
           --no-auto-start \
           -d /var/lib/gerrit \
           --install-plugin reviewnotes \
           --install-plugin replication \
           --install-plugin download-commands \
           --install-plugin delete-project \
           --install-plugin gitiles \
           --install-plugin singleusergroup \
           --install-plugin commit-message-length-validator"

cp /opt/gerrit/plugins/* /var/lib/gerrit/plugins/
chown gerrit:gerrit /var/lib/gerrit/plugins -R



su - gerrit -s /bin/sh \
     -c "git config -f /var/lib/gerrit/etc/gerrit.config \
                   gerrit.canonicalWebUrl \"https://${ServiceAlias}.${PrivateHostedZoneName}\""

su - gerrit  -s /bin/sh \
     -c "git config -f /var/lib/gerrit/etc/gerrit.config \
                   sendemail.enable false"

ls -la /var/lib/gerrit/etc/gerrit.config

systemctl start gerrit

echo "Usefull for first login to setup propper admin"
echo "We configured gerrit to trust A-User header as propper login"
curl --fail -c cookie.txt http://127.0.0.1:8082/login \
        -H "A-User: admin" \
        -H "A-Email: admin@${PrivateHostedZoneName}" \
        -H "A-Name: Administrator"

# CSRF Token is sent on next request
curl --fail -c cookie.txt -b cookie.txt http://127.0.0.1:8082/ \
        -H "A-User: admin" \
        -H "A-Email: admin@${PrivateHostedZoneName}" \
        -H "A-Name: Administrator"

auth_token=$(cat cookie.txt  | grep XSRF_TOKEN | awk '{printf $7}')

sudo cat /home/${Username}/.ssh/id_rsa.pub  | \
         curl --fail  --data @- \
         -b cookie.txt  \
         -H "Content-Type: text/plain" \
         -H "X-Gerrit-Auth: ${auth_token}" \
         http://127.0.0.1:8082/accounts/self/sshkeys


echo "Loading custom certificates"
parameter_names=$(aws ssm get-parameters-by-path \
                     --path "/${EnvironmentNameLower}/keys/public/" \
                     --recursive \
                     --query 'Parameters[*].[Name]' \
                     --output text)
                     
for parameter_name in $parameter_names; do \
   echo "Processing ${parameter_name}"; \
   param_path="$(dirname ${parameter_name})"
   service="$(basename ${param_path})"
   key_file=$(mktemp)
   echo "Key file $key_file for service ${service}"
   aws ssm get-parameter \
     --name ${parameter_name} \
     --with-decryption \
     --query 'Parameter.Value' \
     --output text > $key_file

   ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 -oStrictHostKeyChecking=no \
            gerrit create-account \
              --group "'Service Users'"  \
              --full-name "${service^}" \
              --email "${service}@${PrivateHostedZoneName}" ${service} || echo "User exits"

   echo "Updating public key for ${service}"
   cat $key_file |
     ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 \
       gerrit set-account --add-ssh-key - ${service}
   rm -f $key_file
done


