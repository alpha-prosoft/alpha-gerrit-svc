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

su - gerrit -s /bin/sh \
  -c "git config -f /var/lib/gerrit/etc/gerrit.config \
                   sendemail.enable false"

ls -la /var/lib/gerrit/etc/gerrit.config

echo "Configuring Cognito OAuth authentication"
CLIENT_ID=$(jq -r '.AuthUserPoolClientId' /etc/environment.json)
CLIENT_SECRET=$(jq -r '.AuthUserPoolClientSecret' /etc/environment.json)
ROOT_URL="https://${AuthUserPoolDomain}"

gc() { su - gerrit -s /bin/sh -c "git config -f /var/lib/gerrit/etc/gerrit.config $*"; }
gc auth.type OAUTH
gc --unset-all auth.httpHeader || true
gc --unset-all auth.httpEmailHeader || true
gc --unset-all auth.httpDisplaynameHeader || true
gc --unset-all auth.trustContainerAuth || true
gc "plugin.gerrit-oauth-provider-cognito-oauth.root-url" "${ROOT_URL}"
gc "plugin.gerrit-oauth-provider-cognito-oauth.client-id" "${CLIENT_ID}"
gc "plugin.gerrit-oauth-provider-cognito-oauth.client-secret" "${CLIENT_SECRET}"
gc "plugin.gerrit-oauth-provider-cognito-oauth.link-to-existing-gerrit-accounts" "true"

systemctl restart gerrit

echo "Waiting for gerrit SSH endpoint"
for i in $(seq 1 30); do
  ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 -oStrictHostKeyChecking=no -oConnectTimeout=5 \
    gerrit version && break
  echo "gerrit not ready yet ($i)"; sleep 5
done

if ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 -oStrictHostKeyChecking=no gerrit version; then
  echo "Admin SSH available - provisioning service users from SSM public keys"
  parameter_names=$(aws ssm get-parameters-by-path \
    --path "/${EnvironmentNameLower}/keys/public/" \
    --recursive \
    --query 'Parameters[*].[Name]' \
    --output text)

  for parameter_name in $parameter_names; do
    echo "Processing ${parameter_name}"
    param_path="$(dirname ${parameter_name})"
    service="$(basename ${param_path})"
    key_file=$(mktemp)
    echo "Key file $key_file for service ${service}"
    aws ssm get-parameter \
      --name ${parameter_name} \
      --with-decryption \
      --query 'Parameter.Value' \
      --output text >$key_file

    ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 -oStrictHostKeyChecking=no \
      gerrit create-account \
      --group "'Service Users'" \
      --full-name "${service^}" \
      --email "${service}@${PrivateHostedZoneName}" ${service} || echo "User exists"

    echo "Updating public key for ${service}"
    cat $key_file |
      ssh -i /home/${Username}/.ssh/id_rsa admin@127.0.0.1 -p 29418 \
        gerrit set-account --add-ssh-key - ${service} || echo "Key already set for ${service}"
    rm -f $key_file
  done
else
  echo "WARNING: admin SSH not available on this volume."
  echo "First human Cognito login will create a regular account; promote it to Administrators via the admin SSH key."
fi
