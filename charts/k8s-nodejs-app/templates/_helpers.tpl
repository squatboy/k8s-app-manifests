{{- define "k8s-nodejs-app.fullname" -}}
{{ include "k8s-nodejs-app.name" . }}-{{ .Release.Name }}
{{- end -}}

{{- define "k8s-nodejs-app.name" -}}
{{ default .Chart.Name .Values.nameOverride }}
{{- end -}}

{{- define "k8s-nodejs-app.labels" -}}
app.kubernetes.io/name: {{ include "k8s-nodejs-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
