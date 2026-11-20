<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row v-if="ssh_port">
      <cv-column>
        <NsInlineNotification
          kind="info"
          :title="$t('settings.ssh_port_title')"
          :description="
            $t('settings.ssh_port_description', {
              port: ssh_port,
              host: effectiveHost,
            })
          "
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <NsTile :light="true">
          <cv-form @submit.prevent="configureModule">
            <NsTextInput
              :label="$t('settings.host')"
              v-model.trim="host"
              placeholder="git.example.org"
              :disabled="isFormDisabled"
              :invalid-message="error.host"
              ref="host"
            ></NsTextInput>
            <NsToggle
              :label="$t('settings.lets_encrypt')"
              value="lets_encrypt"
              :form-item="true"
              v-model="lets_encrypt"
              :disabled="isFormDisabled"
              ref="lets_encrypt"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <NsToggle
              :label="$t('settings.http2https')"
              value="http2https"
              :form-item="true"
              v-model="http2https"
              :disabled="isFormDisabled"
              ref="http2https"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <NsTextInput
              :label="$t('settings.password')"
              type="password"
              v-model.trim="password"
              :helper-text="$t('settings.password_helper')"
              :disabled="isFormDisabled"
              :invalid-message="error.password"
              ref="password"
            ></NsTextInput>
            <NsComboBox
              v-model.trim="ldap_domain"
              :autoFilter="true"
              :autoHighlight="true"
              :title="$t('settings.ldap_domain')"
              :label="$t('settings.choose_ldap_domain')"
              :options="ldap_domain_list"
              :clearFilterLabel="$t('settings.clear_selection')"
              :acceptUserInput="false"
              :showItemType="true"
              :invalid-message="error.ldap_domain"
              :disabled="isFormDisabled"
              tooltipAlignment="start"
              tooltipDirection="top"
              ref="ldap_domain"
            >
              <template slot="tooltip">
                {{
                  $t("settings.choose_the_ldap_domain_to_authenticate_users")
                }}
              </template>
            </NsComboBox>
            <NsTextInput
              :label="$t('settings.registry_host')"
              v-model.trim="registry_host"
              placeholder="registry.example.org"
              :helper-text="$t('settings.registry_host_helper')"
              :disabled="isFormDisabled"
              :invalid-message="error.registry_host"
              ref="registry_host"
            ></NsTextInput>
            <NsToggle
              :label="$t('settings.runner_enabled')"
              value="runner_enabled"
              :form-item="true"
              v-model="runner_enabled"
              :disabled="isFormDisabled"
              ref="runner_enabled"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>

            <cv-accordion
              ref="accordion"
              class="accordion-sections"
              @change="onAccordionChange"
            >
              <!-- Single Sign-On (SSO / OmniAuth) -->
              <cv-accordion-item
                ref="ssoAccordionItem"
                :open="isSsoAccordionOpen"
              >
                <template slot="title">{{
                  $t("settings.sso_section_title")
                }}</template>
                <template slot="content">
                  <NsToggle
                    :label="$t('settings.sso_enabled')"
                    value="sso_enabled"
                    :form-item="true"
                    v-model="sso_enabled"
                    :disabled="isFormDisabled"
                    ref="sso_enabled"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>

                  <div v-if="sso_enabled" class="sso-container">
                    <!-- Global OmniAuth Policy & Certificates -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.sso_policy_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.sso_allow_single_sign_on')"
                        value="sso_allow_single_sign_on"
                        :form-item="true"
                        v-model="sso_allow_single_sign_on"
                        :disabled="isFormDisabled"
                        tooltipAlignment="start"
                        tooltipDirection="top"
                        ref="sso_allow_single_sign_on"
                      >
                        <template slot="tooltip">
                          {{ $t("settings.sso_allow_single_sign_on_tooltip") }}
                        </template>
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsToggle
                        :label="$t('settings.sso_block_auto_created_users')"
                        value="sso_block_auto_created_users"
                        :form-item="true"
                        v-model="sso_block_auto_created_users"
                        :disabled="isFormDisabled"
                        tooltipAlignment="start"
                        tooltipDirection="top"
                        ref="sso_block_auto_created_users"
                      >
                        <template slot="tooltip">
                          {{
                            $t("settings.sso_block_auto_created_users_tooltip")
                          }}
                        </template>
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsToggle
                        :label="$t('settings.sso_allow_bypass_two_factor')"
                        value="sso_allow_bypass_two_factor"
                        :form-item="true"
                        v-model="sso_allow_bypass_two_factor"
                        :disabled="isFormDisabled"
                        ref="sso_allow_bypass_two_factor"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsToggle
                        :label="$t('settings.sso_auto_link_user')"
                        value="sso_auto_link_user"
                        :form-item="true"
                        v-model="sso_auto_link_user"
                        :disabled="isFormDisabled"
                        ref="sso_auto_link_user"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsToggle
                        :label="$t('settings.sso_auto_link_ldap_user')"
                        value="sso_auto_link_ldap_user"
                        :form-item="true"
                        v-model="sso_auto_link_ldap_user"
                        :disabled="isFormDisabled"
                        ref="sso_auto_link_ldap_user"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsToggle
                        :label="$t('settings.sso_auto_link_saml_user')"
                        value="sso_auto_link_saml_user"
                        :form-item="true"
                        v-model="sso_auto_link_saml_user"
                        :disabled="isFormDisabled"
                        ref="sso_auto_link_saml_user"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsToggle
                        :label="$t('settings.sso_sync_profile')"
                        value="sso_sync_profile"
                        :form-item="true"
                        v-model="sso_sync_profile"
                        :disabled="isFormDisabled"
                        ref="sso_sync_profile"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <NsComboBox
                        v-model.trim="sso_auto_sign_in_provider"
                        :autoFilter="true"
                        :autoHighlight="true"
                        :title="$t('settings.sso_auto_sign_in_provider')"
                        :label="$t('settings.choose_auto_sign_in_provider')"
                        :options="autoSignInProviderOptions"
                        :clearFilterLabel="$t('settings.clear_selection')"
                        :acceptUserInput="false"
                        :helper-text="
                          $t('settings.sso_auto_sign_in_provider_helper')
                        "
                        :invalid-message="error.sso_auto_sign_in_provider"
                        :disabled="isFormDisabled"
                        ref="sso_auto_sign_in_provider"
                      ></NsComboBox>
                      <NsInlineNotification
                        v-if="sso_auto_sign_in_provider"
                        kind="info"
                        :title="$t('settings.sso_emergency_bypass_title')"
                        :description="
                          $t('settings.sso_emergency_bypass_description', {
                            url: emergencyBypassUrl,
                          })
                        "
                        :showCloseButton="false"
                      />
                      <cv-text-area
                        v-model.trim="custom_ca_cert"
                        class="monospace-textarea"
                        :rows="5"
                        :label="$t('settings.custom_ca_cert')"
                        :helper-text="
                          custom_ca_cert_set
                            ? $t('settings.custom_ca_cert_helper_set')
                            : $t('settings.custom_ca_cert_helper')
                        "
                        :invalid-message="error.custom_ca_cert"
                        placeholder="-----BEGIN CERTIFICATE-----&#10;...&#10;-----END CERTIFICATE-----"
                        :disabled="isFormDisabled"
                        ref="custom_ca_cert"
                      ></cv-text-area>
                      <NsCheckbox
                        v-if="custom_ca_cert_set"
                        v-model="clear_custom_ca_cert"
                        :label="$t('settings.clear_custom_ca_cert')"
                        value="clear_custom_ca_cert"
                        :disabled="isFormDisabled"
                        ref="clear_custom_ca_cert"
                      />
                    </div>

                    <!-- NS8 Cluster Single Sign-On (openid_connect_ns8) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.ns8_sso_section_title") }}</h5>
                      <p class="section-description">
                        {{ $t("settings.ns8_sso_section_description") }}
                      </p>
                      <NsInlineNotification
                        v-if="!ldap_domain"
                        kind="info"
                        :title="$t('settings.ns8_sso_ldap_required_title')"
                        :description="
                          $t('settings.ns8_sso_ldap_required_description')
                        "
                        :showCloseButton="false"
                      />
                      <NsComboBox
                        v-model.trim="ns8_sso_provider"
                        :autoFilter="true"
                        :autoHighlight="true"
                        :title="$t('settings.ns8_sso_provider')"
                        :label="$t('settings.choose_ns8_sso_provider')"
                        :options="filteredSsoProviders"
                        :clearFilterLabel="$t('settings.clear_selection')"
                        :acceptUserInput="false"
                        :helper-text="ns8SsoProviderHelperText"
                        :invalid-message="error.ns8_sso_provider"
                        :disabled="isFormDisabled || !ldap_domain"
                        ref="ns8_sso_provider"
                      ></NsComboBox>
                      <div v-if="ns8_sso_provider" class="provider-fields">
                        <NsTextInput
                          :label="$t('settings.ns8_sso_label')"
                          v-model.trim="ns8_sso_label"
                          placeholder="Single Sign-On"
                          :disabled="isFormDisabled"
                          :invalid-message="error.ns8_sso_label"
                          ref="ns8_sso_label"
                        ></NsTextInput>
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ ns8SsoCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                      </div>
                    </div>

                    <!-- External OpenID Connect (openid_connect) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.oidc_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.oidc_enabled')"
                        value="oidc_enabled"
                        :form-item="true"
                        v-model="oidc_enabled"
                        :disabled="isFormDisabled"
                        ref="oidc_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div v-if="oidc_enabled" class="provider-fields">
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ oidcCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.oidc_label')"
                          v-model.trim="oidc_label"
                          placeholder="OpenID Connect"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oidc_label"
                          ref="oidc_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oidc_issuer')"
                          v-model.trim="oidc_issuer"
                          placeholder="https://sso.example.org/realms/main"
                          :helper-text="$t('settings.oidc_issuer_helper')"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oidc_issuer"
                          ref="oidc_issuer"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oidc_client_id')"
                          v-model.trim="oidc_client_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oidc_client_id"
                          ref="oidc_client_id"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oidc_client_secret')"
                          type="password"
                          v-model.trim="oidc_client_secret"
                          :helper-text="
                            oidc_client_secret_set
                              ? $t('settings.secret_stored_helper')
                              : $t('settings.secret_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.oidc_client_secret"
                          ref="oidc_client_secret"
                        ></NsTextInput>
                        <NsToggle
                          :label="$t('settings.oidc_pkce')"
                          value="oidc_pkce"
                          :form-item="true"
                          v-model="oidc_pkce"
                          :disabled="isFormDisabled"
                          ref="oidc_pkce"
                        >
                          <template slot="text-left">{{
                            $t("settings.disabled")
                          }}</template>
                          <template slot="text-right">{{
                            $t("settings.enabled")
                          }}</template>
                        </NsToggle>
                        <NsComboBox
                          v-model.trim="oidc_client_auth_method"
                          :autoFilter="true"
                          :autoHighlight="true"
                          :title="$t('settings.oidc_client_auth_method')"
                          :label="$t('settings.choose_oidc_auth_method')"
                          :options="oidcAuthMethodOptions"
                          :clearFilterLabel="$t('settings.clear_selection')"
                          :acceptUserInput="false"
                          :invalid-message="error.oidc_client_auth_method"
                          :disabled="isFormDisabled"
                          ref="oidc_client_auth_method"
                        ></NsComboBox>
                        <NsTextInput
                          :label="$t('settings.oidc_uid_field')"
                          v-model.trim="oidc_uid_field"
                          placeholder="preferred_username"
                          :helper-text="$t('settings.oidc_uid_field_helper')"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oidc_uid_field"
                          ref="oidc_uid_field"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oidc_scopes')"
                          v-model.trim="oidc_scopes"
                          placeholder="openid,profile,email"
                          :helper-text="$t('settings.oidc_scopes_helper')"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oidc_scopes"
                          ref="oidc_scopes"
                        ></NsTextInput>
                      </div>
                    </div>

                    <!-- SAML 2.0 (saml) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.saml_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.saml_enabled')"
                        value="saml_enabled"
                        :form-item="true"
                        v-model="saml_enabled"
                        :disabled="isFormDisabled"
                        ref="saml_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div v-if="saml_enabled" class="provider-fields">
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.saml_acs_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ samlCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.saml_metadata_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ samlMetadataUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.saml_label')"
                          v-model.trim="saml_label"
                          placeholder="SAML 2.0"
                          :disabled="isFormDisabled"
                          :invalid-message="error.saml_label"
                          ref="saml_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.saml_idp_sso_target_url')"
                          v-model.trim="saml_idp_sso_target_url"
                          placeholder="https://idp.example.org/saml/sso"
                          :disabled="isFormDisabled"
                          :invalid-message="error.saml_idp_sso_target_url"
                          ref="saml_idp_sso_target_url"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.saml_idp_slo_target_url')"
                          v-model.trim="saml_idp_slo_target_url"
                          placeholder="https://idp.example.org/saml/slo"
                          :disabled="isFormDisabled"
                          :invalid-message="error.saml_idp_slo_target_url"
                          ref="saml_idp_slo_target_url"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.saml_issuer')"
                          v-model.trim="saml_issuer"
                          :placeholder="samlDefaultIssuer"
                          :helper-text="$t('settings.saml_issuer_helper')"
                          :disabled="isFormDisabled"
                          :invalid-message="error.saml_issuer"
                          ref="saml_issuer"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.saml_idp_cert_fingerprint')"
                          v-model.trim="saml_idp_cert_fingerprint"
                          placeholder="AA:BB:CC:DD:EE:FF"
                          :helper-text="
                            $t('settings.saml_idp_cert_fingerprint_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.saml_idp_cert_fingerprint"
                          ref="saml_idp_cert_fingerprint"
                        ></NsTextInput>
                        <cv-text-area
                          v-model.trim="saml_idp_cert"
                          class="monospace-textarea"
                          :rows="5"
                          :label="$t('settings.saml_idp_cert')"
                          :helper-text="
                            saml_idp_cert_set
                              ? $t('settings.saml_idp_cert_helper_set')
                              : $t('settings.saml_idp_cert_helper')
                          "
                          :invalid-message="error.saml_idp_cert"
                          placeholder="-----BEGIN CERTIFICATE-----&#10;...&#10;-----END CERTIFICATE-----"
                          :disabled="isFormDisabled"
                          ref="saml_idp_cert"
                        ></cv-text-area>
                        <NsCheckbox
                          v-if="saml_idp_cert_set"
                          v-model="clear_saml_idp_cert"
                          :label="$t('settings.clear_saml_idp_cert')"
                          value="clear_saml_idp_cert"
                          :disabled="isFormDisabled"
                          ref="clear_saml_idp_cert"
                        />
                        <NsTextInput
                          :label="$t('settings.saml_name_identifier_format')"
                          v-model.trim="saml_name_identifier_format"
                          placeholder="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
                          :disabled="isFormDisabled"
                          :invalid-message="error.saml_name_identifier_format"
                          ref="saml_name_identifier_format"
                        ></NsTextInput>
                      </div>
                    </div>

                    <!-- Microsoft Entra ID (azure_activedirectory_v2) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.azure_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.azure_enabled')"
                        value="azure_enabled"
                        :form-item="true"
                        v-model="azure_enabled"
                        :disabled="isFormDisabled"
                        ref="azure_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div v-if="azure_enabled" class="provider-fields">
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ azureCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.azure_label')"
                          v-model.trim="azure_label"
                          placeholder="Microsoft Entra ID"
                          :disabled="isFormDisabled"
                          :invalid-message="error.azure_label"
                          ref="azure_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.azure_client_id')"
                          v-model.trim="azure_client_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.azure_client_id"
                          ref="azure_client_id"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.azure_client_secret')"
                          type="password"
                          v-model.trim="azure_client_secret"
                          :helper-text="
                            azure_client_secret_set
                              ? $t('settings.secret_stored_helper')
                              : $t('settings.secret_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.azure_client_secret"
                          ref="azure_client_secret"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.azure_tenant_id')"
                          v-model.trim="azure_tenant_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.azure_tenant_id"
                          ref="azure_tenant_id"
                        ></NsTextInput>
                      </div>
                    </div>

                    <!-- GitHub (github) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.github_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.github_enabled')"
                        value="github_enabled"
                        :form-item="true"
                        v-model="github_enabled"
                        :disabled="isFormDisabled"
                        ref="github_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div v-if="github_enabled" class="provider-fields">
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ githubCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.github_label')"
                          v-model.trim="github_label"
                          placeholder="GitHub"
                          :disabled="isFormDisabled"
                          :invalid-message="error.github_label"
                          ref="github_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.github_app_id')"
                          v-model.trim="github_app_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.github_app_id"
                          ref="github_app_id"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.github_app_secret')"
                          type="password"
                          v-model.trim="github_app_secret"
                          :helper-text="
                            github_app_secret_set
                              ? $t('settings.secret_stored_helper')
                              : $t('settings.secret_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.github_app_secret"
                          ref="github_app_secret"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.github_url')"
                          v-model.trim="github_url"
                          placeholder="https://github.example.com"
                          :helper-text="$t('settings.github_url_helper')"
                          :disabled="isFormDisabled"
                          :invalid-message="error.github_url"
                          ref="github_url"
                        ></NsTextInput>
                      </div>
                    </div>

                    <!-- GitLab.com / External GitLab (gitlab) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.gitlab_oauth_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.gitlab_oauth_enabled')"
                        value="gitlab_oauth_enabled"
                        :form-item="true"
                        v-model="gitlab_oauth_enabled"
                        :disabled="isFormDisabled"
                        ref="gitlab_oauth_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div v-if="gitlab_oauth_enabled" class="provider-fields">
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ gitlabOauthCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.gitlab_oauth_label')"
                          v-model.trim="gitlab_oauth_label"
                          placeholder="GitLab.com"
                          :disabled="isFormDisabled"
                          :invalid-message="error.gitlab_oauth_label"
                          ref="gitlab_oauth_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.gitlab_oauth_app_id')"
                          v-model.trim="gitlab_oauth_app_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.gitlab_oauth_app_id"
                          ref="gitlab_oauth_app_id"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.gitlab_oauth_app_secret')"
                          type="password"
                          v-model.trim="gitlab_oauth_app_secret"
                          :helper-text="
                            gitlab_oauth_app_secret_set
                              ? $t('settings.secret_stored_helper')
                              : $t('settings.secret_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.gitlab_oauth_app_secret"
                          ref="gitlab_oauth_app_secret"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.gitlab_oauth_url')"
                          v-model.trim="gitlab_oauth_url"
                          placeholder="https://gitlab.com"
                          :helper-text="$t('settings.gitlab_oauth_url_helper')"
                          :disabled="isFormDisabled"
                          :invalid-message="error.gitlab_oauth_url"
                          ref="gitlab_oauth_url"
                        ></NsTextInput>
                      </div>
                    </div>

                    <!-- Google Workspace (google_oauth2) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.google_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.google_enabled')"
                        value="google_enabled"
                        :form-item="true"
                        v-model="google_enabled"
                        :disabled="isFormDisabled"
                        ref="google_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div v-if="google_enabled" class="provider-fields">
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ googleCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.google_label')"
                          v-model.trim="google_label"
                          placeholder="Google"
                          :disabled="isFormDisabled"
                          :invalid-message="error.google_label"
                          ref="google_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.google_client_id')"
                          v-model.trim="google_client_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.google_client_id"
                          ref="google_client_id"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.google_client_secret')"
                          type="password"
                          v-model.trim="google_client_secret"
                          :helper-text="
                            google_client_secret_set
                              ? $t('settings.secret_stored_helper')
                              : $t('settings.secret_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.google_client_secret"
                          ref="google_client_secret"
                        ></NsTextInput>
                      </div>
                    </div>

                    <!-- Generic OAuth2 (oauth2_generic) -->
                    <div class="sso-section">
                      <h5>{{ $t("settings.oauth2_generic_section_title") }}</h5>
                      <NsToggle
                        :label="$t('settings.oauth2_generic_enabled')"
                        value="oauth2_generic_enabled"
                        :form-item="true"
                        v-model="oauth2_generic_enabled"
                        :disabled="isFormDisabled"
                        ref="oauth2_generic_enabled"
                      >
                        <template slot="text-left">{{
                          $t("settings.disabled")
                        }}</template>
                        <template slot="text-right">{{
                          $t("settings.enabled")
                        }}</template>
                      </NsToggle>
                      <div
                        v-if="oauth2_generic_enabled"
                        class="provider-fields"
                      >
                        <div class="snippet-wrapper">
                          <label class="bx--label">{{
                            $t("settings.callback_url")
                          }}</label>
                          <NsCodeSnippet
                            :copyTooltip="$t('common.copy_to_clipboard')"
                            :copyFeedback="$t('common.copied_to_clipboard')"
                            :feedbackAriaLabel="
                              $t('common.copied_to_clipboard')
                            "
                            :wrapText="true"
                            :hideExpandButton="true"
                          >
                            <span>{{ oauth2GenericCallbackUrl }}</span>
                          </NsCodeSnippet>
                        </div>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_label')"
                          v-model.trim="oauth2_generic_label"
                          placeholder="OAuth2"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_label"
                          ref="oauth2_generic_label"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_app_id')"
                          v-model.trim="oauth2_generic_app_id"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_app_id"
                          ref="oauth2_generic_app_id"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_app_secret')"
                          type="password"
                          v-model.trim="oauth2_generic_app_secret"
                          :helper-text="
                            oauth2_generic_app_secret_set
                              ? $t('settings.secret_stored_helper')
                              : $t('settings.secret_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_app_secret"
                          ref="oauth2_generic_app_secret"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_site')"
                          v-model.trim="oauth2_generic_site"
                          placeholder="https://auth.example.org"
                          :helper-text="
                            $t('settings.oauth2_generic_site_helper')
                          "
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_site"
                          ref="oauth2_generic_site"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_authorize_url')"
                          v-model.trim="oauth2_generic_authorize_url"
                          placeholder="/oauth2/v1/authorize"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_authorize_url"
                          ref="oauth2_generic_authorize_url"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_token_url')"
                          v-model.trim="oauth2_generic_token_url"
                          placeholder="/oauth2/v1/token"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_token_url"
                          ref="oauth2_generic_token_url"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_user_info_url')"
                          v-model.trim="oauth2_generic_user_info_url"
                          placeholder="/oauth2/v1/userinfo"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_user_info_url"
                          ref="oauth2_generic_user_info_url"
                        ></NsTextInput>
                        <NsTextInput
                          :label="$t('settings.oauth2_generic_uid_field')"
                          v-model.trim="oauth2_generic_uid_field"
                          placeholder="sub"
                          :disabled="isFormDisabled"
                          :invalid-message="error.oauth2_generic_uid_field"
                          ref="oauth2_generic_uid_field"
                        ></NsTextInput>
                      </div>
                    </div>
                  </div>
                </template>
              </cv-accordion-item>

              <!-- Custom GitLab Omnibus Configuration (gitlab-custom.rb) -->
              <cv-accordion-item
                ref="customConfigAccordionItem"
                :open="isCustomConfigAccordionOpen"
              >
                <template slot="title">{{
                  $t("settings.custom_gitlab_rb_section_title")
                }}</template>
                <template slot="content">
                  <cv-text-area
                    v-model="custom_gitlab_rb"
                    class="monospace-textarea"
                    :rows="10"
                    :label="$t('settings.custom_gitlab_rb')"
                    :helper-text="$t('settings.custom_gitlab_rb_helper')"
                    :invalid-message="error.custom_gitlab_rb"
                    placeholder="# gitlab_rails['time_zone'] = 'UTC'"
                    :disabled="isFormDisabled"
                    ref="custom_gitlab_rb"
                  ></cv-text-area>
                </template>
              </cv-accordion-item>
            </cv-accordion>

            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="isFormDisabled"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </NsTile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

const SSO_ERROR_FIELDS = new Set([
  "sso_enabled",
  "sso_allow_single_sign_on",
  "sso_block_auto_created_users",
  "sso_allow_bypass_two_factor",
  "sso_auto_link_user",
  "sso_auto_link_ldap_user",
  "sso_auto_link_saml_user",
  "sso_sync_profile",
  "sso_auto_sign_in_provider",
  "custom_ca_cert",
  "clear_custom_ca_cert",
  "ns8_sso_provider",
  "ns8_sso_label",
  "oidc_enabled",
  "oidc_label",
  "oidc_issuer",
  "oidc_client_id",
  "oidc_client_secret",
  "oidc_pkce",
  "oidc_uid_field",
  "oidc_scopes",
  "oidc_client_auth_method",
  "saml_enabled",
  "saml_label",
  "saml_idp_sso_target_url",
  "saml_idp_slo_target_url",
  "saml_issuer",
  "saml_idp_cert_fingerprint",
  "saml_idp_cert",
  "clear_saml_idp_cert",
  "saml_name_identifier_format",
  "azure_enabled",
  "azure_label",
  "azure_client_id",
  "azure_client_secret",
  "azure_tenant_id",
  "github_enabled",
  "github_label",
  "github_app_id",
  "github_app_secret",
  "github_url",
  "gitlab_oauth_enabled",
  "gitlab_oauth_label",
  "gitlab_oauth_app_id",
  "gitlab_oauth_app_secret",
  "gitlab_oauth_url",
  "google_enabled",
  "google_label",
  "google_client_id",
  "google_client_secret",
  "oauth2_generic_enabled",
  "oauth2_generic_label",
  "oauth2_generic_app_id",
  "oauth2_generic_app_secret",
  "oauth2_generic_site",
  "oauth2_generic_authorize_url",
  "oauth2_generic_token_url",
  "oauth2_generic_user_info_url",
  "oauth2_generic_uid_field",
]);

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      isSsoAccordionOpen: false,
      isCustomConfigAccordionOpen: false,
      host: "",
      lets_encrypt: false,
      http2https: true,
      password: "",
      ldap_domain: "",
      ldap_domain_list: [],
      registry_host: "",
      runner_enabled: true,
      ssh_port: "",
      // Global SSO policy & custom CA
      sso_enabled: false,
      sso_allow_single_sign_on: true,
      sso_block_auto_created_users: false,
      sso_allow_bypass_two_factor: true,
      sso_auto_link_user: true,
      sso_auto_link_ldap_user: true,
      sso_auto_link_saml_user: true,
      sso_sync_profile: true,
      sso_auto_sign_in_provider: "",
      custom_ca_cert: "",
      custom_ca_cert_set: false,
      clear_custom_ca_cert: false,
      // NS8 Cluster SSO (openid_connect_ns8)
      sso_providers_list: [],
      ns8_sso_provider: "",
      ns8_sso_label: "Single Sign-On",
      // External OpenID Connect (openid_connect)
      oidc_enabled: false,
      oidc_label: "OpenID Connect",
      oidc_issuer: "",
      oidc_client_id: "",
      oidc_client_secret: "",
      oidc_client_secret_set: false,
      oidc_pkce: true,
      oidc_uid_field: "preferred_username",
      oidc_scopes: "openid,profile,email",
      oidc_client_auth_method: "basic",
      // SAML 2.0 (saml)
      saml_enabled: false,
      saml_label: "SAML 2.0",
      saml_idp_sso_target_url: "",
      saml_idp_slo_target_url: "",
      saml_issuer: "",
      saml_idp_cert_fingerprint: "",
      saml_idp_cert: "",
      saml_idp_cert_set: false,
      clear_saml_idp_cert: false,
      saml_name_identifier_format:
        "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
      // Microsoft Entra ID (azure_activedirectory_v2)
      azure_enabled: false,
      azure_label: "Microsoft Entra ID",
      azure_client_id: "",
      azure_client_secret: "",
      azure_client_secret_set: false,
      azure_tenant_id: "",
      // GitHub (github)
      github_enabled: false,
      github_label: "GitHub",
      github_app_id: "",
      github_app_secret: "",
      github_app_secret_set: false,
      github_url: "",
      // External GitLab (gitlab)
      gitlab_oauth_enabled: false,
      gitlab_oauth_label: "GitLab.com",
      gitlab_oauth_app_id: "",
      gitlab_oauth_app_secret: "",
      gitlab_oauth_app_secret_set: false,
      gitlab_oauth_url: "",
      // Google Workspace (google_oauth2)
      google_enabled: false,
      google_label: "Google",
      google_client_id: "",
      google_client_secret: "",
      google_client_secret_set: false,
      // Generic OAuth2 (oauth2_generic)
      oauth2_generic_enabled: false,
      oauth2_generic_label: "OAuth2",
      oauth2_generic_app_id: "",
      oauth2_generic_app_secret: "",
      oauth2_generic_app_secret_set: false,
      oauth2_generic_site: "",
      oauth2_generic_authorize_url: "/oauth2/v1/authorize",
      oauth2_generic_token_url: "/oauth2/v1/token",
      oauth2_generic_user_info_url: "/oauth2/v1/userinfo",
      oauth2_generic_uid_field: "sub",
      // Custom GitLab Omnibus configuration
      custom_gitlab_rb: "",
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        password: "",
        ldap_domain: "",
        ldap_domain_list: "",
        registry_host: "",
        runner_enabled: "",
        sso_enabled: "",
        sso_allow_single_sign_on: "",
        sso_block_auto_created_users: "",
        sso_allow_bypass_two_factor: "",
        sso_auto_link_user: "",
        sso_auto_link_ldap_user: "",
        sso_auto_link_saml_user: "",
        sso_sync_profile: "",
        sso_auto_sign_in_provider: "",
        custom_ca_cert: "",
        clear_custom_ca_cert: "",
        ns8_sso_provider: "",
        ns8_sso_label: "",
        oidc_enabled: "",
        oidc_label: "",
        oidc_issuer: "",
        oidc_client_id: "",
        oidc_client_secret: "",
        oidc_pkce: "",
        oidc_uid_field: "",
        oidc_scopes: "",
        oidc_client_auth_method: "",
        saml_enabled: "",
        saml_label: "",
        saml_idp_sso_target_url: "",
        saml_idp_slo_target_url: "",
        saml_issuer: "",
        saml_idp_cert_fingerprint: "",
        saml_idp_cert: "",
        clear_saml_idp_cert: "",
        saml_name_identifier_format: "",
        azure_enabled: "",
        azure_label: "",
        azure_client_id: "",
        azure_client_secret: "",
        azure_tenant_id: "",
        github_enabled: "",
        github_label: "",
        github_app_id: "",
        github_app_secret: "",
        github_url: "",
        gitlab_oauth_enabled: "",
        gitlab_oauth_label: "",
        gitlab_oauth_app_id: "",
        gitlab_oauth_app_secret: "",
        gitlab_oauth_url: "",
        google_enabled: "",
        google_label: "",
        google_client_id: "",
        google_client_secret: "",
        oauth2_generic_enabled: "",
        oauth2_generic_label: "",
        oauth2_generic_app_id: "",
        oauth2_generic_app_secret: "",
        oauth2_generic_site: "",
        oauth2_generic_authorize_url: "",
        oauth2_generic_token_url: "",
        oauth2_generic_user_info_url: "",
        oauth2_generic_uid_field: "",
        custom_gitlab_rb: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    isFormDisabled() {
      return this.loading.getConfiguration || this.loading.configureModule;
    },
    effectiveHost() {
      return this.host || "git.example.org";
    },
    filteredSsoProviders() {
      const noneOption = {
        name: "none",
        label: this.$t("settings.no_ns8_sso_provider"),
        value: "",
      };
      if (!this.ldap_domain) {
        return [noneOption];
      }
      const matchingProviders = this.sso_providers_list
        .filter(
          (provider) => !provider.domain || provider.domain === this.ldap_domain
        )
        .map((provider) => ({
          name: String(provider.name || provider.value || ""),
          label: String(provider.label || provider.value || ""),
          value: String(provider.value || ""),
        }));
      return [noneOption, ...matchingProviders];
    },
    ns8SsoProviderHelperText() {
      if (!this.ldap_domain) {
        return "";
      }
      if (this.filteredSsoProviders.length <= 1) {
        return this.$t("settings.ns8_sso_no_providers_available");
      }
      return this.$t("settings.ns8_sso_provider_helper");
    },
    autoSignInProviderOptions() {
      return [
        {
          name: "none",
          label: this.$t("settings.auto_sign_in_none"),
          value: "",
        },
        {
          name: "openid_connect_ns8",
          label: this.$t("settings.provider_openid_connect_ns8"),
          value: "openid_connect_ns8",
        },
        {
          name: "openid_connect",
          label: this.$t("settings.provider_openid_connect"),
          value: "openid_connect",
        },
        {
          name: "saml",
          label: this.$t("settings.provider_saml"),
          value: "saml",
        },
        {
          name: "azure_activedirectory_v2",
          label: this.$t("settings.provider_azure"),
          value: "azure_activedirectory_v2",
        },
        {
          name: "github",
          label: this.$t("settings.provider_github"),
          value: "github",
        },
        {
          name: "gitlab",
          label: this.$t("settings.provider_gitlab"),
          value: "gitlab",
        },
        {
          name: "google_oauth2",
          label: this.$t("settings.provider_google"),
          value: "google_oauth2",
        },
        {
          name: "oauth2_generic",
          label: this.$t("settings.provider_oauth2_generic"),
          value: "oauth2_generic",
        },
      ];
    },
    oidcAuthMethodOptions() {
      return [
        {
          name: "basic",
          label: this.$t("settings.oidc_auth_method_basic"),
          value: "basic",
        },
        {
          name: "query",
          label: this.$t("settings.oidc_auth_method_query"),
          value: "query",
        },
        {
          name: "jwt_bearer",
          label: this.$t("settings.oidc_auth_method_jwt_bearer"),
          value: "jwt_bearer",
        },
        {
          name: "mtls",
          label: this.$t("settings.oidc_auth_method_mtls"),
          value: "mtls",
        },
      ];
    },
    ns8SsoCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/openid_connect_ns8/callback`;
    },
    oidcCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/openid_connect/callback`;
    },
    samlCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/saml/callback`;
    },
    samlMetadataUrl() {
      return `https://${this.effectiveHost}/users/auth/saml/metadata`;
    },
    samlDefaultIssuer() {
      return `https://${this.effectiveHost}`;
    },
    azureCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/azure_activedirectory_v2/callback`;
    },
    githubCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/github/callback`;
    },
    gitlabOauthCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/gitlab/callback`;
    },
    googleCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/google_oauth2/callback`;
    },
    oauth2GenericCallbackUrl() {
      return `https://${this.effectiveHost}/users/auth/oauth2_generic/callback`;
    },
    emergencyBypassUrl() {
      return `https://${this.effectiveHost}/users/sign_in?auto_sign_in=false`;
    },
  },
  watch: {
    ldap_domain(newDomain) {
      if (!newDomain) {
        this.ns8_sso_provider = "";
        return;
      }
      if (this.ns8_sso_provider && !this.loading.getConfiguration) {
        const providerMatches = this.sso_providers_list.some(
          (provider) =>
            provider.value === this.ns8_sso_provider &&
            (!provider.domain || provider.domain === newDomain)
        );
        if (!providerMatches) {
          this.ns8_sso_provider = "";
        }
      }
    },
    custom_ca_cert(newCert) {
      if (newCert) {
        this.clear_custom_ca_cert = false;
      }
    },
    saml_idp_cert(newCert) {
      if (newCert) {
        this.clear_saml_idp_cert = false;
      }
    },
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    onAccordionChange(ev) {
      if (ev && Array.isArray(ev.state)) {
        this.isSsoAccordionOpen = Boolean(ev.state[0]);
        this.isCustomConfigAccordionOpen = Boolean(ev.state[1]);
      }
    },
    openSsoAccordion() {
      this.isSsoAccordionOpen = true;
      if (
        this.$refs.ssoAccordionItem &&
        !this.$refs.ssoAccordionItem.dataOpen
      ) {
        this.$refs.ssoAccordionItem.toggle(true);
      }
    },
    openCustomConfigAccordion() {
      this.isCustomConfigAccordionOpen = true;
      if (
        this.$refs.customConfigAccordionItem &&
        !this.$refs.customConfigAccordionItem.dataOpen
      ) {
        this.$refs.customConfigAccordionItem.toggle(true);
      }
    },
    focusField(fieldRef) {
      if (SSO_ERROR_FIELDS.has(fieldRef)) {
        this.openSsoAccordion();
      } else if (fieldRef === "custom_gitlab_rb") {
        this.openCustomConfigAccordion();
      }
      this.$nextTick(() => {
        const element = this.$refs[fieldRef];
        if (element && typeof element.focus === "function") {
          element.focus();
        }
      });
    },
    syncComboBoxLabels() {
      this.$nextTick(() => {
        const comboRefs = [
          ["ldap_domain", this.ldap_domain],
          ["ns8_sso_provider", this.ns8_sso_provider],
          ["sso_auto_sign_in_provider", this.sso_auto_sign_in_provider],
          ["oidc_client_auth_method", this.oidc_client_auth_method],
        ];
        for (const [refName, val] of comboRefs) {
          const comp = this.$refs[refName];
          if (comp && typeof comp.internalUpdateValue === "function" && val) {
            comp.internalUpdateValue(val);
          }
        }
      });
    },
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;

      this.host = config.host || "";
      this.lets_encrypt = Boolean(config.lets_encrypt);
      this.http2https =
        config.http2https !== undefined ? Boolean(config.http2https) : true;
      this.password = "";

      const domains = Array.isArray(config.ldap_domain_list)
        ? config.ldap_domain_list
        : [];
      this.ldap_domain_list = [
        {
          name: "none",
          label: this.$t("settings.no_ldap_domain"),
          value: "",
        },
        ...domains,
      ];
      this.sso_providers_list = Array.isArray(config.sso_providers_list)
        ? config.sso_providers_list
        : [];
      this.ldap_domain = config.ldap_domain || "";

      this.registry_host = config.registry_host || "";
      this.runner_enabled =
        config.runner_enabled !== undefined
          ? Boolean(config.runner_enabled)
          : true;
      this.ssh_port = config.ssh_port || "";

      // Global SSO policy & custom CA
      this.sso_enabled = Boolean(config.sso_enabled);
      this.sso_allow_single_sign_on =
        config.sso_allow_single_sign_on !== undefined
          ? Boolean(config.sso_allow_single_sign_on)
          : true;
      this.sso_block_auto_created_users = Boolean(
        config.sso_block_auto_created_users
      );
      this.sso_allow_bypass_two_factor =
        config.sso_allow_bypass_two_factor !== undefined
          ? Boolean(config.sso_allow_bypass_two_factor)
          : true;
      this.sso_auto_link_user =
        config.sso_auto_link_user !== undefined
          ? Boolean(config.sso_auto_link_user)
          : true;
      this.sso_auto_link_ldap_user =
        config.sso_auto_link_ldap_user !== undefined
          ? Boolean(config.sso_auto_link_ldap_user)
          : true;
      this.sso_auto_link_saml_user =
        config.sso_auto_link_saml_user !== undefined
          ? Boolean(config.sso_auto_link_saml_user)
          : true;
      this.sso_sync_profile =
        config.sso_sync_profile !== undefined
          ? Boolean(config.sso_sync_profile)
          : true;
      this.sso_auto_sign_in_provider = config.sso_auto_sign_in_provider || "";
      this.custom_ca_cert = "";
      this.custom_ca_cert_set = Boolean(config.custom_ca_cert_set);
      this.clear_custom_ca_cert = false;

      // NS8 Cluster SSO
      this.ns8_sso_provider = this.ldap_domain
        ? config.ns8_sso_provider || ""
        : "";
      this.ns8_sso_label = config.ns8_sso_label || "Single Sign-On";

      // External OpenID Connect
      this.oidc_enabled = Boolean(config.oidc_enabled);
      this.oidc_label = config.oidc_label || "OpenID Connect";
      this.oidc_issuer = config.oidc_issuer || "";
      this.oidc_client_id = config.oidc_client_id || "";
      this.oidc_client_secret = "";
      this.oidc_client_secret_set = Boolean(config.oidc_client_secret_set);
      this.oidc_pkce =
        config.oidc_pkce !== undefined ? Boolean(config.oidc_pkce) : true;
      this.oidc_uid_field = config.oidc_uid_field || "preferred_username";
      this.oidc_scopes = config.oidc_scopes || "openid,profile,email";
      this.oidc_client_auth_method = config.oidc_client_auth_method || "basic";

      // SAML 2.0
      this.saml_enabled = Boolean(config.saml_enabled);
      this.saml_label = config.saml_label || "SAML 2.0";
      this.saml_idp_sso_target_url = config.saml_idp_sso_target_url || "";
      this.saml_idp_slo_target_url = config.saml_idp_slo_target_url || "";
      this.saml_issuer = config.saml_issuer || "";
      this.saml_idp_cert_fingerprint = config.saml_idp_cert_fingerprint || "";
      this.saml_idp_cert = "";
      this.saml_idp_cert_set = Boolean(config.saml_idp_cert_set);
      this.clear_saml_idp_cert = false;
      this.saml_name_identifier_format =
        config.saml_name_identifier_format ||
        "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent";

      // Microsoft Entra ID
      this.azure_enabled = Boolean(config.azure_enabled);
      this.azure_label = config.azure_label || "Microsoft Entra ID";
      this.azure_client_id = config.azure_client_id || "";
      this.azure_client_secret = "";
      this.azure_client_secret_set = Boolean(config.azure_client_secret_set);
      this.azure_tenant_id = config.azure_tenant_id || "";

      // GitHub
      this.github_enabled = Boolean(config.github_enabled);
      this.github_label = config.github_label || "GitHub";
      this.github_app_id = config.github_app_id || "";
      this.github_app_secret = "";
      this.github_app_secret_set = Boolean(config.github_app_secret_set);
      this.github_url = config.github_url || "";

      // External GitLab
      this.gitlab_oauth_enabled = Boolean(config.gitlab_oauth_enabled);
      this.gitlab_oauth_label = config.gitlab_oauth_label || "GitLab.com";
      this.gitlab_oauth_app_id = config.gitlab_oauth_app_id || "";
      this.gitlab_oauth_app_secret = "";
      this.gitlab_oauth_app_secret_set = Boolean(
        config.gitlab_oauth_app_secret_set
      );
      this.gitlab_oauth_url = config.gitlab_oauth_url || "";

      // Google Workspace
      this.google_enabled = Boolean(config.google_enabled);
      this.google_label = config.google_label || "Google";
      this.google_client_id = config.google_client_id || "";
      this.google_client_secret = "";
      this.google_client_secret_set = Boolean(config.google_client_secret_set);

      // Generic OAuth2
      this.oauth2_generic_enabled = Boolean(config.oauth2_generic_enabled);
      this.oauth2_generic_label = config.oauth2_generic_label || "OAuth2";
      this.oauth2_generic_app_id = config.oauth2_generic_app_id || "";
      this.oauth2_generic_app_secret = "";
      this.oauth2_generic_app_secret_set = Boolean(
        config.oauth2_generic_app_secret_set
      );
      this.oauth2_generic_site = config.oauth2_generic_site || "";
      this.oauth2_generic_authorize_url =
        config.oauth2_generic_authorize_url || "/oauth2/v1/authorize";
      this.oauth2_generic_token_url =
        config.oauth2_generic_token_url || "/oauth2/v1/token";
      this.oauth2_generic_user_info_url =
        config.oauth2_generic_user_info_url || "/oauth2/v1/userinfo";
      this.oauth2_generic_uid_field = config.oauth2_generic_uid_field || "sub";

      // Custom GitLab Omnibus configuration
      this.custom_gitlab_rb = config.custom_gitlab_rb || "";

      this.loading.getConfiguration = false;
      this.syncComboBoxLabels();
      this.focusField("host");
    },
    setValidationError(field, message, isValidationOk) {
      this.error[field] = message;
      if (SSO_ERROR_FIELDS.has(field)) {
        this.openSsoAccordion();
      } else if (field === "custom_gitlab_rb") {
        this.openCustomConfigAccordion();
      }
      if (isValidationOk) {
        this.focusField(field);
      }
      return false;
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

      if (!this.host) {
        isValidationOk = this.setValidationError(
          "host",
          this.$t("common.required"),
          isValidationOk
        );
      } else if (!this.host.includes(".")) {
        isValidationOk = this.setValidationError(
          "host",
          this.$t("settings.invalid_fqdn"),
          isValidationOk
        );
      }

      if (this.password && this.password.length < 8) {
        isValidationOk = this.setValidationError(
          "password",
          this.$t("settings.password_too_short"),
          isValidationOk
        );
      }

      if (this.registry_host) {
        if (!this.registry_host.includes(".")) {
          isValidationOk = this.setValidationError(
            "registry_host",
            this.$t("settings.invalid_fqdn"),
            isValidationOk
          );
        } else if (
          this.host &&
          this.registry_host.toLowerCase() === this.host.toLowerCase()
        ) {
          isValidationOk = this.setValidationError(
            "registry_host",
            this.$t("settings.registry_host_must_differ_from_host"),
            isValidationOk
          );
        }
      }

      if (this.sso_enabled) {
        if (this.ns8_sso_provider) {
          if (!this.ldap_domain) {
            isValidationOk = this.setValidationError(
              "ns8_sso_provider",
              this.$t("settings.ns8_sso_requires_ldap_domain"),
              isValidationOk
            );
          } else {
            const selectedProv = this.sso_providers_list.find(
              (p) => p.value === this.ns8_sso_provider
            );
            if (
              selectedProv &&
              selectedProv.domain &&
              selectedProv.domain !== this.ldap_domain
            ) {
              isValidationOk = this.setValidationError(
                "ns8_sso_provider",
                this.$t("settings.ns8_sso_domain_mismatch"),
                isValidationOk
              );
            }
          }
        }

        if (this.oidc_enabled) {
          if (!this.oidc_issuer) {
            isValidationOk = this.setValidationError(
              "oidc_issuer",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.oidc_client_id) {
            isValidationOk = this.setValidationError(
              "oidc_client_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.oidc_client_secret && !this.oidc_client_secret_set) {
            isValidationOk = this.setValidationError(
              "oidc_client_secret",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
        }

        if (this.saml_enabled) {
          if (!this.saml_idp_sso_target_url) {
            isValidationOk = this.setValidationError(
              "saml_idp_sso_target_url",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          const hasStoredSamlCert =
            this.saml_idp_cert_set && !this.clear_saml_idp_cert;
          if (
            !this.saml_idp_cert_fingerprint &&
            !this.saml_idp_cert &&
            !hasStoredSamlCert
          ) {
            isValidationOk = this.setValidationError(
              "saml_idp_cert",
              this.$t("settings.saml_cert_or_fingerprint_required"),
              isValidationOk
            );
          }
        }

        if (this.azure_enabled) {
          if (!this.azure_client_id) {
            isValidationOk = this.setValidationError(
              "azure_client_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.azure_client_secret && !this.azure_client_secret_set) {
            isValidationOk = this.setValidationError(
              "azure_client_secret",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.azure_tenant_id) {
            isValidationOk = this.setValidationError(
              "azure_tenant_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
        }

        if (this.github_enabled) {
          if (!this.github_app_id) {
            isValidationOk = this.setValidationError(
              "github_app_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.github_app_secret && !this.github_app_secret_set) {
            isValidationOk = this.setValidationError(
              "github_app_secret",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
        }

        if (this.gitlab_oauth_enabled) {
          if (!this.gitlab_oauth_app_id) {
            isValidationOk = this.setValidationError(
              "gitlab_oauth_app_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (
            !this.gitlab_oauth_app_secret &&
            !this.gitlab_oauth_app_secret_set
          ) {
            isValidationOk = this.setValidationError(
              "gitlab_oauth_app_secret",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
        }

        if (this.google_enabled) {
          if (!this.google_client_id) {
            isValidationOk = this.setValidationError(
              "google_client_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.google_client_secret && !this.google_client_secret_set) {
            isValidationOk = this.setValidationError(
              "google_client_secret",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
        }

        if (this.oauth2_generic_enabled) {
          if (!this.oauth2_generic_app_id) {
            isValidationOk = this.setValidationError(
              "oauth2_generic_app_id",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (
            !this.oauth2_generic_app_secret &&
            !this.oauth2_generic_app_secret_set
          ) {
            isValidationOk = this.setValidationError(
              "oauth2_generic_app_secret",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
          if (!this.oauth2_generic_site) {
            isValidationOk = this.setValidationError(
              "oauth2_generic_site",
              this.$t("settings.required_when_provider_enabled"),
              isValidationOk
            );
          }
        }
      }

      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        const i18nKey = "settings." + validationError.error;
        this.$set(
          this.error,
          param,
          this.$te(i18nKey)
            ? this.$t(i18nKey)
            : this.$t("error.validation_error")
        );

        if (SSO_ERROR_FIELDS.has(param)) {
          this.openSsoAccordion();
        } else if (param === "custom_gitlab_rb") {
          this.openCustomConfigAccordion();
        }

        if (!focusAlreadySet) {
          this.focusField(param);
          focusAlreadySet = true;
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            http2https: Boolean(this.http2https),
            lets_encrypt: Boolean(this.lets_encrypt),
            password: this.password || "",
            ldap_domain: this.ldap_domain || "",
            registry_host: this.registry_host || "",
            runner_enabled: Boolean(this.runner_enabled),
            // Global SSO policy & custom CA
            sso_enabled: Boolean(this.sso_enabled),
            sso_allow_single_sign_on: Boolean(this.sso_allow_single_sign_on),
            sso_block_auto_created_users: Boolean(
              this.sso_block_auto_created_users
            ),
            sso_allow_bypass_two_factor: Boolean(
              this.sso_allow_bypass_two_factor
            ),
            sso_auto_link_user: Boolean(this.sso_auto_link_user),
            sso_auto_link_ldap_user: Boolean(this.sso_auto_link_ldap_user),
            sso_auto_link_saml_user: Boolean(this.sso_auto_link_saml_user),
            sso_sync_profile: Boolean(this.sso_sync_profile),
            sso_auto_sign_in_provider: this.sso_auto_sign_in_provider || "",
            custom_ca_cert: this.custom_ca_cert || "",
            clear_custom_ca_cert: Boolean(this.clear_custom_ca_cert),
            // NS8 Cluster SSO
            ns8_sso_provider: this.ns8_sso_provider || "",
            ns8_sso_label: this.ns8_sso_label || "Single Sign-On",
            // External OpenID Connect
            oidc_enabled: Boolean(this.oidc_enabled),
            oidc_label: this.oidc_label || "OpenID Connect",
            oidc_issuer: this.oidc_issuer || "",
            oidc_client_id: this.oidc_client_id || "",
            oidc_client_secret: this.oidc_client_secret || "",
            oidc_pkce: Boolean(this.oidc_pkce),
            oidc_uid_field: this.oidc_uid_field || "preferred_username",
            oidc_scopes: this.oidc_scopes || "openid,profile,email",
            oidc_client_auth_method: this.oidc_client_auth_method || "basic",
            // SAML 2.0
            saml_enabled: Boolean(this.saml_enabled),
            saml_label: this.saml_label || "SAML 2.0",
            saml_idp_sso_target_url: this.saml_idp_sso_target_url || "",
            saml_idp_slo_target_url: this.saml_idp_slo_target_url || "",
            saml_issuer: this.saml_issuer || "",
            saml_idp_cert_fingerprint: this.saml_idp_cert_fingerprint || "",
            saml_idp_cert: this.saml_idp_cert || "",
            clear_saml_idp_cert: Boolean(this.clear_saml_idp_cert),
            saml_name_identifier_format:
              this.saml_name_identifier_format ||
              "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
            // Microsoft Entra ID
            azure_enabled: Boolean(this.azure_enabled),
            azure_label: this.azure_label || "Microsoft Entra ID",
            azure_client_id: this.azure_client_id || "",
            azure_client_secret: this.azure_client_secret || "",
            azure_tenant_id: this.azure_tenant_id || "",
            // GitHub
            github_enabled: Boolean(this.github_enabled),
            github_label: this.github_label || "GitHub",
            github_app_id: this.github_app_id || "",
            github_app_secret: this.github_app_secret || "",
            github_url: this.github_url || "",
            // External GitLab
            gitlab_oauth_enabled: Boolean(this.gitlab_oauth_enabled),
            gitlab_oauth_label: this.gitlab_oauth_label || "GitLab.com",
            gitlab_oauth_app_id: this.gitlab_oauth_app_id || "",
            gitlab_oauth_app_secret: this.gitlab_oauth_app_secret || "",
            gitlab_oauth_url: this.gitlab_oauth_url || "",
            // Google Workspace
            google_enabled: Boolean(this.google_enabled),
            google_label: this.google_label || "Google",
            google_client_id: this.google_client_id || "",
            google_client_secret: this.google_client_secret || "",
            // Generic OAuth2
            oauth2_generic_enabled: Boolean(this.oauth2_generic_enabled),
            oauth2_generic_label: this.oauth2_generic_label || "OAuth2",
            oauth2_generic_app_id: this.oauth2_generic_app_id || "",
            oauth2_generic_app_secret: this.oauth2_generic_app_secret || "",
            oauth2_generic_site: this.oauth2_generic_site || "",
            oauth2_generic_authorize_url:
              this.oauth2_generic_authorize_url || "/oauth2/v1/authorize",
            oauth2_generic_token_url:
              this.oauth2_generic_token_url || "/oauth2/v1/token",
            oauth2_generic_user_info_url:
              this.oauth2_generic_user_info_url || "/oauth2/v1/userinfo",
            oauth2_generic_uid_field: this.oauth2_generic_uid_field || "sub",
            // Custom GitLab Omnibus configuration
            custom_gitlab_rb: this.custom_gitlab_rb || "",
          },
          extra: {
            title: this.$t("settings.configure_instance", {
              instance: this.instanceName,
            }),
            description: this.$t("common.processing"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";

.accordion-sections {
  margin-top: 1.5rem;
  margin-bottom: 2rem;
}

.sso-container {
  margin-top: 1rem;
}

.sso-section {
  padding-top: 1rem;
  margin-top: 1rem;
  border-top: 1px solid #e0e0e0;

  h5 {
    margin-bottom: 0.75rem;
    font-weight: 600;
  }
}

.section-description {
  margin-bottom: 1rem;
  color: #525252;
  font-size: 0.875rem;
}

.provider-fields {
  margin-top: 0.75rem;
  padding-left: 1rem;
  border-left: 2px solid #e0e0e0;
}

.snippet-wrapper {
  margin-bottom: 1.25rem;
}

.monospace-textarea ::v-deep textarea {
  font-family: "IBM Plex Mono", "SFMono-Regular", Consolas, "Liberation Mono",
    Menlo, monospace;
  font-size: 0.875rem;
}
</style>
