{{/*
Expand the name of the chart.
*/}}

{{- define "gha-base-name" -}}
gha-rs
{{- end }}

{{- define "gha-runner-scale-set.name" -}}
{{- default (include "gha-base-name" .) .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "gha-runner-scale-set.scale-set-name" -}}
{{ .Values.runnerScaleSetName | default .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gha-runner-scale-set.fullname" -}}
{{- $name := default (include "gha-base-name" .) }}
{{- printf "%s-%s" (include "gha-runner-scale-set.scale-set-name" .) $name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gha-runner-scale-set.chart" -}}
{{- printf "%s-%s" (include "gha-base-name" .) .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels, as a JSON object.
*/}}
{{- define "gha-runner-scale-set.labels" -}}
{{- $labels := dict
      "helm.sh/chart" (include "gha-runner-scale-set.chart" .)
      "app.kubernetes.io/managed-by" .Release.Service
      "app.kubernetes.io/part-of" "gha-rs"
      "actions.github.com/scale-set-name" (include "gha-runner-scale-set.scale-set-name" .)
      "actions.github.com/scale-set-namespace" (include "gha-runner-scale-set.namespace" .) }}
{{- range $k, $v := include "gha-runner-scale-set.selectorLabels" . | fromJson }}
{{- $_ := set $labels $k $v }}
{{- end }}
{{- if .Chart.AppVersion }}
{{- $_ := set $labels "app.kubernetes.io/version" (.Chart.AppVersion | toString) }}
{{- end }}
{{- $labels | toJson }}
{{- end }}

{{/*
Selector labels, as a JSON object.
*/}}
{{- define "gha-runner-scale-set.selectorLabels" -}}
{{- dict
      "app.kubernetes.io/name" (include "gha-runner-scale-set.scale-set-name" .)
      "app.kubernetes.io/instance" (include "gha-runner-scale-set.scale-set-name" .)
  | toJson }}
{{- end }}

{{/*
Final metadata.labels for a resource, as a JSON object.
Args (dict): ctx (root context), component (optional fixed
app.kubernetes.io/component value), meta (optional resourceMeta sub-object),
strict (AutoscalingRunnerSet behavior: resourceMeta labels are filtered
against reserved keys and stringified, like user labels).
Reserved keys (common labels, component) always win over user/resourceMeta input.
*/}}
{{- define "gha-runner-scale-set.effective-labels" -}}
{{- $base := include "gha-runner-scale-set.labels" .ctx | fromJson }}
{{- $labels := dict }}
{{- $strict := .strict }}
{{- range $k, $v := .ctx.Values.labels }}
{{- if not (or (hasKey $base $k) (eq $k "app.kubernetes.io/component") (hasPrefix "actions.github.com/" $k)) }}
{{- $_ := set $labels $k ($v | toString) }}
{{- end }}
{{- end }}
{{- with .meta }}
{{- range $k, $v := .labels }}
{{- if $strict }}
{{- if not (or (hasKey $base $k) (eq $k "app.kubernetes.io/component") (hasPrefix "actions.github.com/" $k)) }}
{{- $_ := set $labels $k ($v | toString) }}
{{- end }}
{{- else }}
{{- $_ := set $labels $k $v }}
{{- end }}
{{- end }}
{{- end }}
{{- range $k, $v := $base }}
{{- $_ := set $labels $k $v }}
{{- end }}
{{- with .component }}
{{- $_ := set $labels "app.kubernetes.io/component" . }}
{{- end }}
{{- $labels | toJson }}
{{- end }}

{{/*
Final metadata.annotations for a resource, as a JSON object.
Args (dict): ctx, meta, strict (AutoscalingRunnerSet behavior: reserved
actions.github.com/cleanup-* and values-hash keys are filtered out and
values are stringified).
*/}}
{{- define "gha-runner-scale-set.effective-annotations" -}}
{{- $annotations := dict }}
{{- $strict := .strict }}
{{- range $k, $v := .ctx.Values.annotations }}
{{- if $strict }}
{{- if not (or (hasPrefix "actions.github.com/cleanup-" $k) (eq $k "actions.github.com/values-hash")) }}
{{- $_ := set $annotations $k ($v | toString) }}
{{- end }}
{{- else }}
{{- $_ := set $annotations $k $v }}
{{- end }}
{{- end }}
{{- with .meta }}
{{- range $k, $v := .annotations }}
{{- if $strict }}
{{- if not (or (hasPrefix "actions.github.com/cleanup-" $k) (eq $k "actions.github.com/values-hash")) }}
{{- $_ := set $annotations $k ($v | toString) }}
{{- end }}
{{- else }}
{{- $_ := set $annotations $k $v }}
{{- end }}
{{- end }}
{{- end }}
{{- $annotations | toJson }}
{{- end }}

{{/*
Render a ResourceMeta block for AutoscalingRunnerSet spec fields, as a JSON object.
*/}}
{{- define "gha-runner-scale-set.resourceMetaSpec" -}}
{{- $spec := dict }}
{{- with .labels }}
{{- $_ := set $spec "labels" . }}
{{- end }}
{{- with .annotations }}
{{- $_ := set $spec "annotations" . }}
{{- end }}
{{- $spec | toJson }}
{{- end }}

{{- define "gha-runner-scale-set.githubsecret" -}}
  {{- if kindIs "string" .Values.githubConfigSecret }}
    {{- if not (empty .Values.githubConfigSecret) }}
{{- .Values.githubConfigSecret }}
    {{- else}}
{{- fail "Values.githubConfigSecret is required for setting auth with GitHub server." }}
    {{- end }}
  {{- else }}
{{- include "gha-runner-scale-set.fullname" . | replace "_" "-" }}-github-secret
  {{- end }}
{{- end }}

{{- define "gha-runner-scale-set.noPermissionServiceAccountName" -}}
{{- include "gha-runner-scale-set.fullname" . | replace "_" "-" }}-no-permission
{{- end }}

{{- define "gha-runner-scale-set.kubeModeRoleName" -}}
{{- include "gha-runner-scale-set.fullname" . }}-kube-mode
{{- end }}

{{- define "gha-runner-scale-set.kubeModeRoleBindingName" -}}
{{- include "gha-runner-scale-set.fullname" . }}-kube-mode
{{- end }}

{{- define "gha-runner-scale-set.kubeModeServiceAccountName" -}}
{{- include "gha-runner-scale-set.fullname" . | replace "_" "-" }}-kube-mode
{{- end }}

{{/*
Container/volume builders below return JSON objects (single item) or a
sequence of JSON objects each followed by a trailing comma (list fragments),
for splicing into KYAML flow lists.
*/}}

{{- define "gha-runner-scale-set.dind-init-container" -}}
{{- $c := dict "name" "init-dind-externals" }}
{{- range $i, $val := .Values.template.spec.containers }}
{{- if eq $val.name "runner" }}
{{- $_ := set $c "image" $val.image }}
{{- $_ := set $c "command" (list "cp") }}
{{- $_ := set $c "args" (list "-r" "/home/runner/externals/." "/home/runner/tmpDir/") }}
{{- $_ := set $c "volumeMounts" (list (dict "name" "dind-externals" "mountPath" "/home/runner/tmpDir")) }}
{{- end }}
{{- end }}
{{- $c | toJson }}
{{- end }}

{{- define "gha-runner-scale-set.dind-container" -}}
{{- $c := dict
      "name" "dind"
      "image" "docker:dind"
      "args" (list "dockerd" "--host=unix:///var/run/docker.sock" "--group=$(DOCKER_GROUP_GID)")
      "env" (list (dict "name" "DOCKER_GROUP_GID" "value" "123"))
      "securityContext" (dict "privileged" true)
      "volumeMounts" (list
        (dict "name" "work" "mountPath" "/home/runner/_work")
        (dict "name" "dind-sock" "mountPath" "/var/run")
        (dict "name" "dind-externals" "mountPath" "/home/runner/externals")) }}
{{- if (ge (.Capabilities.KubeVersion.Minor | int) 29) }}
{{- $_ := set $c "restartPolicy" "Always" }}
{{- $_ := set $c "startupProbe" (dict
      "exec" (dict "command" (list "docker" "info"))
      "initialDelaySeconds" 0
      "failureThreshold" 24
      "periodSeconds" 5) }}
{{- end }}
{{- $c | toJson }}
{{- end }}

{{- define "gha-runner-scale-set.dind-volume" -}}
{{ dict "name" "dind-sock" "emptyDir" (dict) | toJson }},
{{ dict "name" "dind-externals" "emptyDir" (dict) | toJson }},
{{- end }}

{{- define "gha-runner-scale-set.tls-volume" -}}
{{ dict "name" "github-server-tls-cert" "configMap" (dict
      "name" .certificateFrom.configMapKeyRef.name
      "items" (list (dict
        "key" .certificateFrom.configMapKeyRef.key
        "path" .certificateFrom.configMapKeyRef.key))) | toJson }},
{{- end }}

{{- define "gha-runner-scale-set.dind-work-volume" -}}
{{- $createWorkVolume := true }}
{{- range $i, $volume := .Values.template.spec.volumes }}
{{- if eq $volume.name "work" }}
{{- $createWorkVolume = false }}
{{ $volume | toJson }},
{{- end }}
{{- end }}
{{- if $createWorkVolume }}
{{ dict "name" "work" "emptyDir" (dict) | toJson }},
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.kubernetes-mode-work-volume" -}}
{{- $createWorkVolume := true }}
{{- range $i, $volume := .Values.template.spec.volumes }}
{{- if eq $volume.name "work" }}
{{- $createWorkVolume = false }}
{{ $volume | toJson }},
{{- end }}
{{- end }}
{{- if $createWorkVolume }}
{{ dict "name" "work" "ephemeral" (dict "volumeClaimTemplate" (dict
      "spec" .Values.containerMode.kubernetesModeWorkVolumeClaim)) | toJson }},
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.non-work-volumes" -}}
{{- range $i, $volume := .Values.template.spec.volumes }}
{{- if ne $volume.name "work" }}
{{ $volume | toJson }},
{{- end }}
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.non-runner-containers" -}}
{{- range $i, $container := .Values.template.spec.containers }}
{{- if ne $container.name "runner" }}
{{ $container | toJson }},
{{- end }}
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.non-runner-non-dind-containers" -}}
{{- range $i, $container := .Values.template.spec.containers }}
{{- if and (ne $container.name "runner") (ne $container.name "dind") }}
{{ $container | toJson }},
{{- end }}
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.dind-runner-container" -}}
{{- $tlsConfig := (default (dict) .Values.githubServerTLS) }}
{{- $c := dict "name" "runner" }}
{{- range $i, $container := .Values.template.spec.containers }}
{{- if eq $container.name "runner" }}
{{- range $key, $val := omit $container "env" "volumeMounts" "name" }}
{{- $_ := set $c $key $val }}
{{- end }}
{{- $setDockerHost := true }}
{{- $setRunnerWaitDocker := true }}
{{- $setNodeExtraCaCerts := false }}
{{- $setRunnerUpdateCaCerts := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $setNodeExtraCaCerts = true }}
{{- $setRunnerUpdateCaCerts = true }}
{{- end }}
{{- $env := list }}
{{- range $container.env }}
{{- if eq .name "DOCKER_HOST" }}
{{- $setDockerHost = false }}
{{- end }}
{{- if eq .name "RUNNER_WAIT_FOR_DOCKER_IN_SECONDS" }}
{{- $setRunnerWaitDocker = false }}
{{- end }}
{{- if eq .name "NODE_EXTRA_CA_CERTS" }}
{{- $setNodeExtraCaCerts = false }}
{{- end }}
{{- if eq .name "RUNNER_UPDATE_CA_CERTS" }}
{{- $setRunnerUpdateCaCerts = false }}
{{- end }}
{{- $env = append $env . }}
{{- end }}
{{- if $setDockerHost }}
{{- $env = append $env (dict "name" "DOCKER_HOST" "value" "unix:///var/run/docker.sock") }}
{{- end }}
{{- if $setRunnerWaitDocker }}
{{- $env = append $env (dict "name" "RUNNER_WAIT_FOR_DOCKER_IN_SECONDS" "value" "120") }}
{{- end }}
{{- if $setNodeExtraCaCerts }}
{{- $env = append $env (dict "name" "NODE_EXTRA_CA_CERTS" "value" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))) }}
{{- end }}
{{- if $setRunnerUpdateCaCerts }}
{{- $env = append $env (dict "name" "RUNNER_UPDATE_CA_CERTS" "value" "1") }}
{{- end }}
{{- $_ := set $c "env" $env }}
{{- $mountWork := true }}
{{- $mountDindCert := true }}
{{- $mountGitHubServerTLS := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $mountGitHubServerTLS = true }}
{{- end }}
{{- $volumeMounts := list }}
{{- range $container.volumeMounts }}
{{- if eq .name "work" }}
{{- $mountWork = false }}
{{- end }}
{{- if eq .name "dind-sock" }}
{{- $mountDindCert = false }}
{{- end }}
{{- if eq .name "github-server-tls-cert" }}
{{- $mountGitHubServerTLS = false }}
{{- end }}
{{- $volumeMounts = append $volumeMounts . }}
{{- end }}
{{- if $mountWork }}
{{- $volumeMounts = append $volumeMounts (dict "name" "work" "mountPath" "/home/runner/_work") }}
{{- end }}
{{- if $mountDindCert }}
{{- $volumeMounts = append $volumeMounts (dict "name" "dind-sock" "mountPath" "/var/run") }}
{{- end }}
{{- if $mountGitHubServerTLS }}
{{- $volumeMounts = append $volumeMounts (dict
      "name" "github-server-tls-cert"
      "mountPath" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))
      "subPath" $tlsConfig.certificateFrom.configMapKeyRef.key) }}
{{- end }}
{{- $_ := set $c "volumeMounts" $volumeMounts }}
{{- end }}
{{- end }}
{{- $c | toJson }}
{{- end }}

{{- define "gha-runner-scale-set.kubernetes-mode-runner-container" -}}
{{- $tlsConfig := (default (dict) .Values.githubServerTLS) }}
{{- $c := dict "name" "runner" }}
{{- range $i, $container := .Values.template.spec.containers }}
{{- if eq $container.name "runner" }}
{{- range $key, $val := omit $container "env" "volumeMounts" "name" }}
{{- $_ := set $c $key $val }}
{{- end }}
{{- $setContainerHooks := true }}
{{- $setPodName := true }}
{{- $setRequireJobContainer := true }}
{{- $setNodeExtraCaCerts := false }}
{{- $setRunnerUpdateCaCerts := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $setNodeExtraCaCerts = true }}
{{- $setRunnerUpdateCaCerts = true }}
{{- end }}
{{- $env := list }}
{{- range $container.env }}
{{- if eq .name "ACTIONS_RUNNER_CONTAINER_HOOKS" }}
{{- $setContainerHooks = false }}
{{- end }}
{{- if eq .name "ACTIONS_RUNNER_POD_NAME" }}
{{- $setPodName = false }}
{{- end }}
{{- if eq .name "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER" }}
{{- $setRequireJobContainer = false }}
{{- end }}
{{- if eq .name "NODE_EXTRA_CA_CERTS" }}
{{- $setNodeExtraCaCerts = false }}
{{- end }}
{{- if eq .name "RUNNER_UPDATE_CA_CERTS" }}
{{- $setRunnerUpdateCaCerts = false }}
{{- end }}
{{- $env = append $env . }}
{{- end }}
{{- if $setContainerHooks }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_CONTAINER_HOOKS" "value" "/home/runner/k8s/index.js") }}
{{- end }}
{{- if $setPodName }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_POD_NAME" "valueFrom" (dict "fieldRef" (dict "fieldPath" "metadata.name"))) }}
{{- end }}
{{- if $setRequireJobContainer }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER" "value" "true") }}
{{- end }}
{{- if $setNodeExtraCaCerts }}
{{- $env = append $env (dict "name" "NODE_EXTRA_CA_CERTS" "value" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))) }}
{{- end }}
{{- if $setRunnerUpdateCaCerts }}
{{- $env = append $env (dict "name" "RUNNER_UPDATE_CA_CERTS" "value" "1") }}
{{- end }}
{{- $_ := set $c "env" $env }}
{{- $mountWork := true }}
{{- $mountGitHubServerTLS := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $mountGitHubServerTLS = true }}
{{- end }}
{{- $volumeMounts := list }}
{{- range $container.volumeMounts }}
{{- if eq .name "work" }}
{{- $mountWork = false }}
{{- end }}
{{- if eq .name "github-server-tls-cert" }}
{{- $mountGitHubServerTLS = false }}
{{- end }}
{{- $volumeMounts = append $volumeMounts . }}
{{- end }}
{{- if $mountWork }}
{{- $volumeMounts = append $volumeMounts (dict "name" "work" "mountPath" "/home/runner/_work") }}
{{- end }}
{{- if $mountGitHubServerTLS }}
{{- $volumeMounts = append $volumeMounts (dict
      "name" "github-server-tls-cert"
      "mountPath" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))
      "subPath" $tlsConfig.certificateFrom.configMapKeyRef.key) }}
{{- end }}
{{- $_ := set $c "volumeMounts" $volumeMounts }}
{{- end }}
{{- end }}
{{- $c | toJson }}
{{- end }}

{{- define "gha-runner-scale-set.kubernetes-novolume-mode-runner-container" -}}
{{- $tlsConfig := (default (dict) .Values.githubServerTLS) }}
{{- $c := dict "name" "runner" }}
{{- range $i, $container := .Values.template.spec.containers }}
{{- if eq $container.name "runner" }}
{{- $setRunnerImage := "" }}
{{- range $key, $val := omit $container "env" "volumeMounts" "name" }}
{{- if eq $key "image" }}
{{- $setRunnerImage = $val }}
{{- end }}
{{- $_ := set $c $key $val }}
{{- end }}
{{- $setContainerHooks := true }}
{{- $setPodName := true }}
{{- $setRequireJobContainer := true }}
{{- $setActionsRunnerImage := true }}
{{- $setNodeExtraCaCerts := false }}
{{- $setRunnerUpdateCaCerts := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $setNodeExtraCaCerts = true }}
{{- $setRunnerUpdateCaCerts = true }}
{{- end }}
{{- $env := list }}
{{- range $container.env }}
{{- if eq .name "ACTIONS_RUNNER_CONTAINER_HOOKS" }}
{{- $setContainerHooks = false }}
{{- end }}
{{- if eq .name "ACTIONS_RUNNER_IMAGE" }}
{{- $setActionsRunnerImage = false }}
{{- end }}
{{- if eq .name "ACTIONS_RUNNER_POD_NAME" }}
{{- $setPodName = false }}
{{- end }}
{{- if eq .name "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER" }}
{{- $setRequireJobContainer = false }}
{{- end }}
{{- if eq .name "NODE_EXTRA_CA_CERTS" }}
{{- $setNodeExtraCaCerts = false }}
{{- end }}
{{- if eq .name "RUNNER_UPDATE_CA_CERTS" }}
{{- $setRunnerUpdateCaCerts = false }}
{{- end }}
{{- $env = append $env . }}
{{- end }}
{{- if $setContainerHooks }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_CONTAINER_HOOKS" "value" "/home/runner/k8s-novolume/index.js") }}
{{- end }}
{{- if $setPodName }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_POD_NAME" "valueFrom" (dict "fieldRef" (dict "fieldPath" "metadata.name"))) }}
{{- end }}
{{- if $setRequireJobContainer }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER" "value" "true") }}
{{- end }}
{{- if $setActionsRunnerImage }}
{{- $env = append $env (dict "name" "ACTIONS_RUNNER_IMAGE" "value" ($setRunnerImage | toString)) }}
{{- end }}
{{- if $setNodeExtraCaCerts }}
{{- $env = append $env (dict "name" "NODE_EXTRA_CA_CERTS" "value" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))) }}
{{- end }}
{{- if $setRunnerUpdateCaCerts }}
{{- $env = append $env (dict "name" "RUNNER_UPDATE_CA_CERTS" "value" "1") }}
{{- end }}
{{- $_ := set $c "env" $env }}
{{- $mountGitHubServerTLS := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $mountGitHubServerTLS = true }}
{{- end }}
{{- $volumeMounts := list }}
{{- range $container.volumeMounts }}
{{- if eq .name "github-server-tls-cert" }}
{{- $mountGitHubServerTLS = false }}
{{- end }}
{{- $volumeMounts = append $volumeMounts . }}
{{- end }}
{{- if $mountGitHubServerTLS }}
{{- $volumeMounts = append $volumeMounts (dict
      "name" "github-server-tls-cert"
      "mountPath" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))
      "subPath" $tlsConfig.certificateFrom.configMapKeyRef.key) }}
{{- end }}
{{- $_ := set $c "volumeMounts" $volumeMounts }}
{{- end }}
{{- end }}
{{- $c | toJson }}
{{- end }}

{{- define "gha-runner-scale-set.default-mode-runner-containers" -}}
{{- $tlsConfig := (default (dict) .Values.githubServerTLS) }}
{{- range $i, $container := .Values.template.spec.containers }}
{{- if ne $container.name "runner" }}
{{ $container | toJson }},
{{- else }}
{{- $c := dict "name" $container.name }}
{{- range $key, $val := omit $container "env" "volumeMounts" "name" }}
{{- $_ := set $c $key $val }}
{{- end }}
{{- $setNodeExtraCaCerts := false }}
{{- $setRunnerUpdateCaCerts := false }}
{{- if $tlsConfig.runnerMountPath }}
{{- $setNodeExtraCaCerts = true }}
{{- $setRunnerUpdateCaCerts = true }}
{{- end }}
{{- $mountGitHubServerTLS := false }}
{{- if or $container.env $setNodeExtraCaCerts $setRunnerUpdateCaCerts }}
{{- $env := list }}
{{- range $container.env }}
{{- if eq .name "NODE_EXTRA_CA_CERTS" }}
{{- $setNodeExtraCaCerts = false }}
{{- end }}
{{- if eq .name "RUNNER_UPDATE_CA_CERTS" }}
{{- $setRunnerUpdateCaCerts = false }}
{{- end }}
{{- $env = append $env . }}
{{- end }}
{{- if $setNodeExtraCaCerts }}
{{- $env = append $env (dict "name" "NODE_EXTRA_CA_CERTS" "value" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))) }}
{{- end }}
{{- if $setRunnerUpdateCaCerts }}
{{- $env = append $env (dict "name" "RUNNER_UPDATE_CA_CERTS" "value" "1") }}
{{- end }}
{{- if $tlsConfig.runnerMountPath }}
{{- $mountGitHubServerTLS = true }}
{{- end }}
{{- $_ := set $c "env" $env }}
{{- end }}
{{- if or $container.volumeMounts $mountGitHubServerTLS }}
{{- $volumeMounts := list }}
{{- range $container.volumeMounts }}
{{- if eq .name "github-server-tls-cert" }}
{{- $mountGitHubServerTLS = false }}
{{- end }}
{{- $volumeMounts = append $volumeMounts . }}
{{- end }}
{{- if $mountGitHubServerTLS }}
{{- $volumeMounts = append $volumeMounts (dict
      "name" "github-server-tls-cert"
      "mountPath" (clean (print $tlsConfig.runnerMountPath "/" $tlsConfig.certificateFrom.configMapKeyRef.key))
      "subPath" $tlsConfig.certificateFrom.configMapKeyRef.key) }}
{{- end }}
{{- $_ := set $c "volumeMounts" $volumeMounts }}
{{- end }}
{{ $c | toJson }},
{{- end }}
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.managerRoleName" -}}
{{- include "gha-runner-scale-set.fullname" . }}-manager
{{- end }}

{{- define "gha-runner-scale-set.managerRoleBindingName" -}}
{{- include "gha-runner-scale-set.fullname" . }}-manager
{{- end }}

{{- define "gha-runner-scale-set.managerServiceAccountName" -}}
{{- $searchControllerDeployment := 1 }}
{{- if .Values.controllerServiceAccount }}
  {{- if .Values.controllerServiceAccount.name }}
    {{- $searchControllerDeployment = 0 }}
{{- .Values.controllerServiceAccount.name }}
  {{- end }}
{{- end }}
{{- if eq $searchControllerDeployment 1 }}
  {{- $multiNamespacesCounter := 0 }}
  {{- $singleNamespaceCounter := 0 }}
  {{- $controllerDeployment := dict }}
  {{- $singleNamespaceControllerDeployments := dict }}
  {{- $managerServiceAccountName := "" }}
  {{- range $index, $deployment := (lookup "apps/v1" "Deployment" "" "").items }}
    {{- if kindIs "map" $deployment.metadata.labels }}
      {{- if eq (get $deployment.metadata.labels "app.kubernetes.io/part-of") "gha-rs-controller" }}
        {{- if hasKey $deployment.metadata.labels "actions.github.com/controller-watch-single-namespace" }}
          {{- $singleNamespaceCounter = add $singleNamespaceCounter 1 }}
          {{- $_ := set $singleNamespaceControllerDeployments (get $deployment.metadata.labels "actions.github.com/controller-watch-single-namespace") $deployment}}
        {{- else }}
          {{- $multiNamespacesCounter = add $multiNamespacesCounter 1 }}
          {{- $controllerDeployment = $deployment }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if and (eq $multiNamespacesCounter 0) (eq $singleNamespaceCounter 0) }}
    {{- fail "No gha-rs-controller deployment found using label (app.kubernetes.io/part-of=gha-rs-controller). Consider setting controllerServiceAccount.name in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
  {{- if and (gt $multiNamespacesCounter 0) (gt $singleNamespaceCounter 0) }}
    {{- fail "Found both gha-rs-controller installed with flags.watchSingleNamespace set and unset in cluster, this is not supported. Consider setting controllerServiceAccount.name in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
  {{- if gt $multiNamespacesCounter 1 }}
    {{- fail "More than one gha-rs-controller deployment found using label (app.kubernetes.io/part-of=gha-rs-controller). Consider setting controllerServiceAccount.name in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
  {{- if eq $multiNamespacesCounter 1 }}
    {{- with $controllerDeployment.metadata }}
      {{- $managerServiceAccountName = (get $controllerDeployment.metadata.labels "actions.github.com/controller-service-account-name") }}
    {{- end }}
  {{- else if gt $singleNamespaceCounter 0 }}
    {{- if hasKey $singleNamespaceControllerDeployments (include "gha-runner-scale-set.namespace" .) }}
      {{- $controllerDeployment = get $singleNamespaceControllerDeployments (include "gha-runner-scale-set.namespace" .) }}
      {{- with $controllerDeployment.metadata }}
        {{- $managerServiceAccountName = (get $controllerDeployment.metadata.labels "actions.github.com/controller-service-account-name") }}
      {{- end }}
    {{- else }}
      {{- fail "No gha-rs-controller deployment that watch this namespace found using label (actions.github.com/controller-watch-single-namespace). Consider setting controllerServiceAccount.name in values.yaml to be explicit if you think the discovery is wrong." }}
    {{- end }}
  {{- end }}
  {{- if eq $managerServiceAccountName "" }}
    {{- fail "No service account name found for gha-rs-controller deployment using label (actions.github.com/controller-service-account-name), consider setting controllerServiceAccount.name in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
{{- $managerServiceAccountName }}
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.managerServiceAccountNamespace" -}}
{{- $searchControllerDeployment := 1 }}
{{- if .Values.controllerServiceAccount }}
  {{- if .Values.controllerServiceAccount.namespace }}
    {{- $searchControllerDeployment = 0 }}
{{- .Values.controllerServiceAccount.namespace }}
  {{- end }}
{{- end }}
{{- if eq $searchControllerDeployment 1 }}
  {{- $multiNamespacesCounter := 0 }}
  {{- $singleNamespaceCounter := 0 }}
  {{- $controllerDeployment := dict }}
  {{- $singleNamespaceControllerDeployments := dict }}
  {{- $managerServiceAccountNamespace := "" }}
  {{- range $index, $deployment := (lookup "apps/v1" "Deployment" "" "").items }}
    {{- if kindIs "map" $deployment.metadata.labels }}
      {{- if eq (get $deployment.metadata.labels "app.kubernetes.io/part-of") "gha-rs-controller" }}
        {{- if hasKey $deployment.metadata.labels "actions.github.com/controller-watch-single-namespace" }}
          {{- $singleNamespaceCounter = add $singleNamespaceCounter 1 }}
          {{- $_ := set $singleNamespaceControllerDeployments (get $deployment.metadata.labels "actions.github.com/controller-watch-single-namespace") $deployment}}
        {{- else }}
          {{- $multiNamespacesCounter = add $multiNamespacesCounter 1 }}
          {{- $controllerDeployment = $deployment }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if and (eq $multiNamespacesCounter 0) (eq $singleNamespaceCounter 0) }}
    {{- fail "No gha-rs-controller deployment found using label (app.kubernetes.io/part-of=gha-rs-controller). Consider setting controllerServiceAccount.namespace in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
  {{- if and (gt $multiNamespacesCounter 0) (gt $singleNamespaceCounter 0) }}
    {{- fail "Found both gha-rs-controller installed with flags.watchSingleNamespace set and unset in cluster, this is not supported. Consider setting controllerServiceAccount.namespace in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
  {{- if gt $multiNamespacesCounter 1 }}
    {{- fail "More than one gha-rs-controller deployment found using label (app.kubernetes.io/part-of=gha-rs-controller). Consider setting controllerServiceAccount.namespace in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
  {{- if eq $multiNamespacesCounter 1 }}
    {{- with $controllerDeployment.metadata }}
      {{- $managerServiceAccountNamespace = (get $controllerDeployment.metadata.labels "actions.github.com/controller-service-account-namespace") }}
    {{- end }}
  {{- else if gt $singleNamespaceCounter 0 }}
    {{- if hasKey $singleNamespaceControllerDeployments (include "gha-runner-scale-set.namespace" .) }}
      {{- $controllerDeployment = get $singleNamespaceControllerDeployments (include "gha-runner-scale-set.namespace" .) }}
      {{- with $controllerDeployment.metadata }}
        {{- $managerServiceAccountNamespace = (get $controllerDeployment.metadata.labels "actions.github.com/controller-service-account-namespace") }}
      {{- end }}
    {{- else }}
      {{- fail "No gha-rs-controller deployment that watch this namespace found using label (actions.github.com/controller-watch-single-namespace). Consider setting controllerServiceAccount.namespace in values.yaml to be explicit if you think the discovery is wrong." }}
    {{- end }}
  {{- end }}
  {{- if eq $managerServiceAccountNamespace "" }}
    {{- fail "No service account namespace found for gha-rs-controller deployment using label (actions.github.com/controller-service-account-namespace), consider setting controllerServiceAccount.namespace in values.yaml to be explicit if you think the discovery is wrong." }}
  {{- end }}
{{- $managerServiceAccountNamespace }}
{{- end }}
{{- end }}

{{- define "gha-runner-scale-set.namespace" -}}
{{- if .Values.namespaceOverride }}
  {{- .Values.namespaceOverride }}
{{- else }}
  {{- .Release.Namespace }}
{{- end }}
{{- end }}
