{{- define "etcdendpoints" -}}
{{- $count := .count -}}
{{- $servers := list -}}
{{- range $index := int $count | until -}}
{{- $nameprefix := .nameprefix -}}
{{- if $nameprefix -}}
{{- $servers = print ($nameprefix) ("-") ($index|toString) ("=http://") ($nameprefix) ("-") ($index|toString) ("._{HOST_DOMAIN_COMMAND}:2380") | append $servers -}}
{{- else }}
{{- $servers = print ("etcd-") ($index|toString) ("=http://etcd-") ($index|toString) ("._{HOST_DOMAIN_COMMAND}:2380") | append $servers -}}
{{- end -}}
{{- end -}}
{{- (join "," $servers) -}}
{{- end -}}

{{- define "etcdendpoints_v1" -}}
{{- $count := .count -}}
{{- $servers := list -}}
{{- $nameprefix := .nameprefix -}}
{{- range $index := int $count | until -}}
{{- if $nameprefix -}}
{{- $servers = print ($nameprefix) ("-") ($index|toString) ("=http://") ($nameprefix) ("-") ($index|toString) (".etcd.__ETCD_NAMESPACE.svc.__DOMAIN:2380") | append $servers -}}
{{- else }}
{{- $servers = print ("etcd-") ($index|toString) ("=http://etcd-") ($index|toString) (".etcd.__ETCD_NAMESPACE.svc.__DOMAIN:2380") | append $servers -}}
{{- end -}}
{{- end -}}
{{- (join "," $servers) -}}
{{- end -}}
