{{- define "devops-sample-app.name" -}}
devops-sample-app
{{- end -}}

{{- define "devops-sample-app.fullname" -}}
{{ include "devops-sample-app.name" . }}
{{- end -}}
