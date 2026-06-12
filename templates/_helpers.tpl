{{/*
クラスタドメインの自動検出
優先順位: deployer.domain (RHDP 注入 / 手動指定) > ingresses.config.openshift.io/cluster から lookup
helm template 時は lookup が空を返すため、deployer.domain の指定が必要
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
Gateway hostname: 指定があればそれを使い、なければ echo.<domain> を自動生成
*/}}
{{- define "rhcl.gatewayHostname" -}}
{{- .Values.app.hostname | default (printf "echo.%s" (include "rhcl.clusterDomain" .)) -}}
{{- end -}}

{{/*
Keycloak の外部 URL
*/}}
{{- define "rhcl.keycloakUrl" -}}
https://keycloak-{{ .Values.keycloak.namespace }}.{{ include "rhcl.clusterDomain" . }}
{{- end -}}

{{/*
GatewayClass 名: provider に応じて切替
*/}}
{{- define "rhcl.gatewayClassName" -}}
{{- if eq .Values.gatewayProvider "istio" -}}
istio
{{- else -}}
openshift-default
{{- end -}}
{{- end -}}

{{/*
Gateway の Namespace
*/}}
{{- define "rhcl.gatewayNamespace" -}}
{{- if eq .Values.gatewayProvider "istio" -}}
istio-system
{{- else -}}
{{ .Values.app.namespace }}
{{- end -}}
{{- end -}}

{{/*
ArgoCD sync-wave アノテーション
*/}}
{{- define "rhcl.syncWave" -}}
argocd.argoproj.io/sync-wave: {{ . | quote }}
{{- end -}}

{{/*
echo-server のイメージ参照
*/}}
{{- define "rhcl.appImage" -}}
{{- if .Values.app.image.buildFromSource -}}
image-registry.openshift-image-registry.svc:5000/{{ .Values.app.namespace }}/{{ .Values.app.name }}:latest
{{- else -}}
{{ .Values.app.image.prebuilt }}
{{- end -}}
{{- end -}}

{{/*
RHDP application ラベル
*/}}
{{- define "rhcl.rhdpLabel" -}}
{{- if .Values.rhdp.enabled -}}
demo.redhat.com/application: {{ .Values.rhdp.applicationLabel | quote }}
{{- end -}}
{{- end -}}
