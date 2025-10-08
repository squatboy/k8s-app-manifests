{{- define "k8s-nodejs-app.fullname" -}}
{{ include "k8s-nodejs-app.name" . }}-{{ .Release.Name }}
{{- end -}}

{{- define "k8s-nodejs-app.name" -}}
{{ default .Chart.Name .Values.nameOverride }}
{{- end -}}
