#!/bin/sh

SERVICE="p.mysql"

HOSTNAME=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.hostname'`
PASSWORD=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.password'`
PORT=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.port'`
USERNAME=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.username'`
DATABASE=`echo $VCAP_SERVICES | jq -r '.["'$SERVICE'"][0].credentials.name'`

APP_URI=$(echo $VCAP_APPLICATION | jq -r '.application_uris[0]')

cat <<EOF > cf.hcl
ui = true
disable_mlock = true
storage "mysql" {
  username = "$USERNAME"
  password = "$PASSWORD"
  address = "$HOSTNAME:$PORT"
  database = "$DATABASE"
  table = "vault"
  max_parallel = "128"
}
listener "tcp" {
 address = "0.0.0.0:8080"
 tls_disable = 1
}
api_addr = "https://${APP_URI}:443"
EOF

cat cf.hcl

echo "#### Starting Vault..."

./vault server -config=cf.hcl &

if [ "$VAULT_UNSEAL_KEY1" != "" ];then
    export VAULT_ADDR='http://127.0.0.1:8080'
    echo "#### Waiting..."
    sleep 1
    echo "#### Unsealing..."
    if [ "$VAULT_UNSEAL_KEY1" != "" ];then
        ./vault operator unseal $VAULT_UNSEAL_KEY1
    fi
    if [ "$VAULT_UNSEAL_KEY2" != "" ];then
        ./vault operator unseal $VAULT_UNSEAL_KEY2
    fi
    if [ "$VAULT_UNSEAL_KEY3" != "" ];then
        ./vault operator unseal $VAULT_UNSEAL_KEY3
    fi
fi
