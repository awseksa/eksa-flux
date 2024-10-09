{{- define "kubernetes.cronjob.apiVersion" -}}
{{- if semverCompare "<1.20-0" .Capabilities.KubeVersion.Version -}}
{{- print "batch/v1beta1" -}}
{{- else if semverCompare ">=1.20-0" .Capabilities.KubeVersion.Version -}}
{{- print "batch/v1" -}}
{{- end -}}
{{- end -}}
