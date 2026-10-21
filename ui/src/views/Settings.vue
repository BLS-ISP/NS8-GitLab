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
              host: host || 'git.example.org',
            })
          "
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.host')"
              v-model.trim="host"
              placeholder="git.example.org"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.host"
              ref="host"
            ></cv-text-input>
            <NsToggle
              :label="$t('settings.lets_encrypt')"
              value="lets_encrypt"
              :form-item="true"
              v-model="lets_encrypt"
              :disabled="loading.getConfiguration || loading.configureModule"
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
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="http2https"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <cv-text-input
              :label="$t('settings.password')"
              type="password"
              v-model.trim="password"
              :helper-text="$t('settings.password_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.password"
              ref="password"
            ></cv-text-input>
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
              :disabled="loading.getConfiguration || loading.configureModule"
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
            <cv-text-input
              :label="$t('settings.registry_host')"
              v-model.trim="registry_host"
              placeholder="registry.example.org"
              :helper-text="$t('settings.registry_host_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.registry_host"
              ref="registry_host"
            ></cv-text-input>
            <NsToggle
              :label="$t('settings.runner_enabled')"
              value="runner_enabled"
              :form-item="true"
              v-model="runner_enabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="runner_enabled"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
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
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
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
      host: "",
      lets_encrypt: false,
      http2https: true,
      password: "",
      ldap_domain: "",
      ldap_domain_list: [],
      registry_host: "",
      runner_enabled: true,
      ssh_port: "",
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
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
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
      this.loading.getConfiguration = false;
      const config = taskResult.output;

      this.host = config.host || "";
      this.lets_encrypt = Boolean(config.lets_encrypt);
      this.http2https =
        config.http2https !== undefined ? Boolean(config.http2https) : true;
      this.password = "";
      this.ldap_domain = config.ldap_domain || "";
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
      this.registry_host = config.registry_host || "";
      this.runner_enabled =
        config.runner_enabled !== undefined
          ? Boolean(config.runner_enabled)
          : true;
      this.ssh_port = config.ssh_port || "";

      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

      if (!this.host) {
        this.error.host = this.$t("common.required");
        if (isValidationOk) {
          this.focusElement("host");
          isValidationOk = false;
        }
      } else if (!this.host.includes(".")) {
        this.error.host = this.$t("settings.invalid_fqdn");
        if (isValidationOk) {
          this.focusElement("host");
          isValidationOk = false;
        }
      }

      if (this.password && this.password.length < 8) {
        this.error.password = this.$t("settings.password_too_short");
        if (isValidationOk) {
          this.focusElement("password");
          isValidationOk = false;
        }
      }

      if (this.registry_host) {
        if (!this.registry_host.includes(".")) {
          this.error.registry_host = this.$t("settings.invalid_fqdn");
          if (isValidationOk) {
            this.focusElement("registry_host");
            isValidationOk = false;
          }
        } else if (
          this.host &&
          this.registry_host.toLowerCase() === this.host.toLowerCase()
        ) {
          this.error.registry_host = this.$t(
            "settings.registry_host_must_differ_from_host"
          );
          if (isValidationOk) {
            this.focusElement("registry_host");
            isValidationOk = false;
          }
        }
      }

      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        this.error[param] = this.$t("settings." + validationError.error);
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
            http2https: this.http2https,
            lets_encrypt: this.lets_encrypt,
            password: this.password || "",
            ldap_domain: this.ldap_domain || "",
            registry_host: this.registry_host || "",
            runner_enabled: this.runner_enabled,
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
</style>
