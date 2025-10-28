{{- define "cloudwave-api.name" -}}
cloudwave-api
{{- end -}}

{{- define "cloudwave-api.fullname" -}}
{{ include "cloudwave-api.name" . }}
{{- end -}}
