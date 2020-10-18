#!/bin/bash 

echo "Starting gerrit"

java -jar /opt/gerrit/gerrit.war init \
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
          --install-plugin commit-message-length-validator

cp /opt/gerrit/plugins/* /var/lib/gerrit/plugins/
chown gerrit:gerrit /var/lib/gerrit/plugins -R

git config -f /var/lib/gerrit/etc/gerrit.config \
       	gerrit.canonicalWebUrl "https://${ServiceAlias}.${PrivateHostedZoneName}"

git config -f /var/lib/gerrit/etc/gerrit.config \
        sendemail.enable false

git config  -f /var/lib/gerrit/etc/gerrit.config \
       	gerrit.installCommitMsgHookCommand 'curl -b ~/.alpha/gitcookie -Lo `git rev-parse --git-dir`/hooks/commit-msg https://'"${ServiceAlias}.${PrivateHostedZoneName}"'/tools/hooks/commit-msg; chmod +x `git rev-parse --git-dir`/hooks/commit-msg'

systemctl start gerrit

curl -c cookie.txt http://127.0.0.1:8082/login \
        -H "A-User: admin" \
        -H "A-Email: admin@local" \
        -H "A-Name: Administrator"

# CSRF Token is sent on next request
curl -c cookie.txt -b cookie.txt http://127.0.0.1:8082/ \
        -H "A-User: admin" \
        -H "A-Email: admin@local" \
        -H "A-Name: Administrator"

auth_token=$(cat cookie.txt  | grep XSRF_TOKEN | awk '{printf $7}')

sudo cat /home/gerrit/.ssh/id_rsa.pub  | \
         curl --data @- \
         -b cookie.txt  \
         -H "Content-Type: text/plain" \
         -H "X-Gerrit-Auth: ${auth_token}" \
         http://127.0.0.1:8082/accounts/self/sshkeys


aws ssm get-parameter \
    --name "/$EnvironmentNameLower/public/jenkins/.ssh/id_rsa.pub" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text | base64 -d | su gerrit bash -c "tee /home/${Username}/.ssh/jenkins.id_rsa.pub"

ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 -oStrictHostKeyChecking=no \
            gerrit create-account \
              --group "'Non-Interactive Users'"  \
              --full-name "Jenkins" \
              --email "jenkins@${PrivateHostedZoneName}" jenkins || echo "User exits"


cat /home/${Username}/.ssh/jenkins.id_rsa.pub |
  ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 \
      gerrit set-account --add-ssh-key - jenkins

