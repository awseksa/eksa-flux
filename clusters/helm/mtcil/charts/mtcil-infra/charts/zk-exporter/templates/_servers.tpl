{{- define "kafkazkconnectendpoints" -}}
{{- $count := .count -}}
{{- $domain := .domain -}}
{{- $namespace := .namespace -}}
{{- $servers := list -}}
{{- $nameprefix := .nameprefix -}}
{{- range $index := int $count | until -}}
{{- if $nameprefix -}}
{{- $servers = print ($nameprefix) ("-") ($index|toString) (".zk.") ($namespace) (".svc.") ($domain) (":2181") | append $servers -}}
{{- else }}
{{- $servers = print ("zk-") ($index|toString) (".zk.") ($namespace) (".svc.") ($domain) (":2181") | append $servers -}}
{{- end -}}
{{- end -}}
{{- (join "," $servers) -}}
{{- end -}}
