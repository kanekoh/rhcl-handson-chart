{{/*
クラスタドメインの自動検出
優先順位: deployer.domain > ingresses.config.openshift.io/cluster から lookup
*/}}
{{- define "rhcl.clusterDomain" -}}
{{- if .Values.deployer.domain -}}
  {{- .Values.deployer.domain -}}
{{- else -}}
  {{- $ingress := (lookup "config.openshift.io/v1" "Ingress" "" "cluster") -}}
  {{- if and $ingress $ingress.spec $ingress.spec.domain -}}
    {{- $ingress.spec.domain -}}
  {{- else -}}
    {{- fail "クラスタドメインを自動検出できませんでした。--set deployer.domain=apps.xxx を指定するか、helm install でクラスタ上で実行してください。" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Gateway hostname
*/}}
{{- define "rhcl.gatewayHostname" -}}
{{- .Values.components.app.hostname | default (printf "echo.%s" (include "rhcl.clusterDomain" .)) -}}
{{- end -}}

{{/*
Keycloak の外部 URL
*/}}
{{- define "rhcl.keycloakUrl" -}}
https://keycloak-{{ .Values.components.keycloak.namespace }}.{{ include "rhcl.clusterDomain" . }}
{{- end -}}

{{/*
GatewayClass 名
*/}}
{{- define "rhcl.gatewayClassName" -}}
{{- if eq .Values.gatewayProvider "istio" -}}istio{{- else -}}openshift-default{{- end -}}
{{- end -}}

{{/*
Gateway の Namespace
*/}}
{{- define "rhcl.gatewayNamespace" -}}
{{- if eq .Values.gatewayProvider "istio" -}}istio-system{{- else -}}{{ .Values.components.app.namespace }}{{- end -}}
{{- end -}}
