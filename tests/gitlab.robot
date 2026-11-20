*** Settings ***
Library    SSHLibrary

*** Test Cases ***
Check if gitlab is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if gitlab can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "git.example.org", "http2https": false, "lets_encrypt": false, "password": "Nethesis,1234", "ldap_domain": "", "registry_host": "registry.example.org", "runner_enabled": true}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab configuration is persisted
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    json.loads($output)    modules=json
    Should Be Equal As Strings    ${config.host}    git.example.org
    Should Be Equal As Strings    ${config.registry_host}    registry.example.org
    Should Be True    ${config.runner_enabled}
    Should Be True    ${config.configured}

Check if gitlab services are started
    ${rc} =    Execute Command    runagent -m ${module_id} systemctl --user is-active gitlab.service gitlab-app.service gitlab-runner.service
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab SSO and custom configuration work
    ${sso_payload} =    Evaluate    shlex.quote(json.dumps({"host": "git.example.org", "http2https": False, "lets_encrypt": False, "ldap_domain": "", "registry_host": "registry.example.org", "runner_enabled": True, "sso_enabled": True, "oidc_enabled": True, "oidc_label": "Keycloak SSO", "oidc_issuer": "https://sso.example.org/realms/main", "oidc_client_id": "gitlab-client", "oidc_client_secret": "SuperSecretOIDC123", "saml_enabled": True, "saml_idp_sso_target_url": "https://idp.example.org/saml/sso", "saml_idp_cert_fingerprint": "AA:BB:CC:DD:EE:FF", "custom_gitlab_rb": "# custom test setting\\ngitlab_rails['time_zone'] = 'UTC'"}))    modules=json,shlex
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data ${sso_payload}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Not Contain    ${output}    SuperSecretOIDC123
    &{config} =    Evaluate    json.loads($output)    modules=json
    Should Be True    ${config.sso_enabled}
    Should Be True    ${config.oidc_enabled}
    Should Be Equal As Strings    ${config.oidc_label}    Keycloak SSO
    Should Be Equal As Strings    ${config.oidc_issuer}    https://sso.example.org/realms/main
    Should Be Equal As Strings    ${config.oidc_client_id}    gitlab-client
    Should Be True    ${config.oidc_client_secret_set}
    Should Be True    ${config.saml_enabled}
    Should Be Equal As Strings    ${config.saml_idp_sso_target_url}    https://idp.example.org/saml/sso
    Should Be Equal As Strings    ${config.saml_idp_cert_fingerprint}    AA:BB:CC:DD:EE:FF
    Should Contain    ${config.custom_gitlab_rb}    gitlab_rails['time_zone'] = 'UTC'

    ${passwords_env}  ${rc} =    Execute Command    runagent -m ${module_id} cat passwords.env
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${passwords_env}    OIDC_CLIENT_SECRET=

    ${env_file}  ${rc} =    Execute Command    runagent -m ${module_id} cat environment
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Not Contain    ${env_file}    SuperSecretOIDC123

    ${custom_mode}  ${rc} =    Execute Command    runagent -m ${module_id} stat -c %a gitlab-custom.rb
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Be Equal As Strings    ${custom_mode}    600

    ${custom_rb}  ${rc} =    Execute Command    runagent -m ${module_id} cat gitlab-custom.rb
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${custom_rb}    gitlab_rails['time_zone'] = 'UTC'

    ${gitlab_rb}  ${rc} =    Execute Command    runagent -m ${module_id} cat gitlab.rb
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    Should Contain    ${gitlab_rb}    omniauth_providers
    Should Contain    ${gitlab_rb}    from_file "/etc/gitlab/gitlab-custom.rb"

    ${ruby_out}  ${rc} =    Execute Command    runagent -m ${module_id} podman exec gitlab-app /opt/gitlab/embedded/bin/ruby -c /assets/ns8-gitlab.rb
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0

    ${rc} =    Execute Command    runagent -m ${module_id} systemctl --user is-active gitlab.service gitlab-app.service gitlab-runner.service
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
