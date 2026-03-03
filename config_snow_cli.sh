snow --config-file ./config.toml connection add \
   --connection-name default \
   --user deployment_user \
   --authenticator SNOWFLAKE_JWT \
   --private-key ./snowflake_rsa_key.p8 \
   --account THMMSGS-BV92046 \
   --no-interactive
