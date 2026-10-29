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
    &{config} =    Evaluate    ${output}
    Should Be Equal As Strings    ${config.host}    git.example.org
    Should Be Equal As Strings    ${config.registry_host}    registry.example.org
    Should Be Equal    ${config.runner_enabled}    ${True}
    Should Be Equal    ${config.configured}    ${True}

Check if gitlab services are started
    ${rc} =    Execute Command    runagent -m ${module_id} systemctl --user is-active gitlab.service gitlab-app.service gitlab-runner.service
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab backup and restore works
    ${output}  ${rc} =    Execute Command    api-cli run add-backup-repository --data '{"name": "local-test", "provider": "local", "url": "/var/lib/nethserver/backup-test", "password": "testpassword", "parameters": {}}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{repo} =    Evaluate    ${output}
    Set Suite Variable    ${repo_id}    ${repo.id}

    ${output}  ${rc} =    Execute Command    api-cli run add-backup --data '{"name": "gitlab-backup", "repository": "${repo_id}", "schedule": "0 0 * * *", "schedule_hint": {}, "retention": 1, "instances": ["${module_id}"], "enabled": true}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{bkp} =    Evaluate    ${output}
    Set Suite Variable    ${bkp_id}    ${bkp.id}

    ${rc} =    Execute Command    api-cli run run-backup --data '{"id": ${bkp_id}}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

    ${output}  ${rc} =    Execute Command    api-cli run list-backup-snapshots --data '{"repository": "${repo_id}", "path": "gitlab/${module_id}"}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    @{snapshots} =    Evaluate    ${output}
    ${snapshot_id} =    Set Variable    ${snapshots[0]["id"]}

    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

    ${output}  ${rc} =    Execute Command    api-cli run restore-module --data '{"repository": "${repo_id}", "path": "gitlab/${module_id}", "snapshot": "${snapshot_id}", "node": 1, "replace": false}'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{restored} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${restored.module_id}

    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    ${output}
    Should Be Equal As Strings    ${config.host}    git.example.org
    Should Be Equal As Strings    ${config.registry_host}    registry.example.org
    Should Be Equal    ${config.runner_enabled}    ${True}

    ${rc} =    Execute Command    runagent -m ${module_id} systemctl --user is-active gitlab.service gitlab-app.service gitlab-runner.service
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

    ${rc} =    Execute Command    api-cli run remove-backup --data '{"id": ${bkp_id}}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

    ${rc} =    Execute Command    api-cli run remove-backup-repository --data '{"id": "${repo_id}"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if gitlab is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
