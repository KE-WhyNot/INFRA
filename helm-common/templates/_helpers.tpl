{{/*
Common labels
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/component: {{ .Values.component | default "service" }}
app.kubernetes.io/part-of: {{ .Values.partOf | default "microservices" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common name
*/}}
{{- define "common.name" -}}
{{- .Values.name | default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Common fullname
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "common.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Common chart
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Common image
*/}}
{{- define "common.image" -}}
{{- $registry := .Values.image.registry | default "" -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Common service account name
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- include "common.fullname" . -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end }}

{{/*
Common ingress class
*/}}
{{- define "common.ingressClass" -}}
{{- .Values.ingress.class | default "nginx" -}}
{{- end }}

{{/*
Common environment variables
*/}}
{{- define "common.env" -}}
{{- range $key, $value := .Values.env -}}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end }}

{{/*
Common resources
*/}}
{{- define "common.resources" -}}
{{- if .Values.resources -}}
resources:
  {{- toYaml .Values.resources | nindent 2 }}
{{- end -}}
{{- end }}

{{/*
Common node selector
*/}}
{{- define "common.nodeSelector" -}}
{{- if .Values.nodeSelector -}}
nodeSelector:
  {{- toYaml .Values.nodeSelector | nindent 2 }}
{{- end -}}
{{- end }}

{{/*
Common tolerations
*/}}
{{- define "common.tolerations" -}}
{{- if .Values.tolerations -}}
tolerations:
  {{- toYaml .Values.tolerations | nindent 2 }}
{{- end -}}
{{- end }}

{{/*
Common affinity
*/}}
{{- define "common.affinity" -}}
{{- if .Values.affinity -}}
affinity:
  {{- toYaml .Values.affinity | nindent 2 }}
{{- end -}}
{{- end }}
