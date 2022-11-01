{{/*
    Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
    Create a default fully qualified app name.
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
    If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
    Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
    Common labels for all resources.
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.common.labels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
    Create the name of the service account to use.
*/}}
{{- define "common.serviceAccount.name" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
    Assemble partial image specs into name.
*/}}
{{- define "app.image" -}}
{{- printf "%s:%s" .Values.app.image.repository (default .Chart.AppVersion .Values.app.image.tag) }}
{{- end }}

{{/*
    Selenium Hub URL for application.
    By default, configured to use `selenium-grid` subchart.
*/}}
{{- define "app.config.seleniumHubURL" -}}
{{- if .Values.app.config.seleniumHubURL }}
{{- tpl .Values.app.config.seleniumHubURL $ }}
{{- else }}
{{- if index .Values "selenium-grid" "enabled" }}
{{- print "http://selenium-hub:4444" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
    Application crawler component full name.
*/}}
{{- define "app.components.crawler.fullname" -}}
{{- printf "%s-crawler" (include "common.fullname" .) }}
{{- end }}

{{/*
    Application crawler component labels.
*/}}
{{- define "app.components.crawler.labels" -}}
{{ include "common.labels" . }}
app.kubernetes.io/component: crawler
{{ include "app.components.crawler.selectorLabels" . }}
{{- end }}

{{/*
    Application crawler component labels.
*/}}
{{- define "app.components.crawler.selectorLabels" -}}
app.kubernetes.io/name: "{{ include "common.name" . }}-crawler"
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
