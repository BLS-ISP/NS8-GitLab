*** Settings ***
Library    SSHLibrary

*** Variables ***
${SCENARIO}         install
${IMAGE_URL}        ghcr.io/bls-isp/gitlab:latest
${STABLE_URL}       ghcr.io/bls-isp/gitlab:1.0.5

*** Keywords ***
Install module Fresh
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Install module From Stable
    ${output}  ${rc} =    Execute Command    add-module ${STABLE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Update module To Testing
    ${rc} =    Execute Command    api-cli run update-module --data '{"module_url":"${IMAGE_URL}","instances":["${module_id}"],"force":true}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

*** Test Cases ***
Check if gitlab is installed correctly
    IF    '${SCENARIO}' == 'update'
        Install module From Stable
    ELSE
        Install module Fresh
    END

Check if gitlab can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host": "git.example.org", "http2https": false, "lets_encrypt": false, "password": "Nethesis,1234", "ldap_domain": "", "registry_host": "registry.example.org", "runner_enabled": true}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab is updated correctly
    IF    '${SCENARIO}' == 'update'
        Update module To Testing
    END

Check if gitlab configuration is persisted
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    ${output}
    Should Be Equal As Strings    ${config.host}    git.example.org
    Should Be Equal As Strings    ${config.registry_host}    registry.example.org
    Should Be Equal    ${config.runner_enabled}    ${True}
    Should Be Equal    ${config.configured}    ${True}

Check if gitlab services are started
    ${rc} =    Execute Command    runagent -m ${module_id} systemctl --user is-active gitlab.service gitlab-app.service gitlab-runner.service
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
