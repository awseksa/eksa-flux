{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "traefik.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "traefik.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "traefik.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The name of the service account to use
*/}}
{{- define "traefik.serviceAccountName" -}}
{{- default (include "traefik.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}

{{/*
Construct the path for the providers.kubernetesingress.ingressendpoint.publishedservice.
By convention this will simply use the <namespace>/<service-name> to match the name of the
service generated.
Users can provide an override for an explicit service they want bound via `.Values.providers.kubernetesIngress.publishedService.pathOverride`
*/}}
{{- define "providers.kubernetesIngress.publishedServicePath" -}}
{{- $defServiceName := printf "%s/%s" (include "traefik.namespace" .) (include "traefik.fullname" .) -}}
{{- $servicePath := default $defServiceName .Values.providers.kubernetesIngress.publishedService.pathOverride }}
{{- print $servicePath | trimSuffix "-" -}}
{{- end -}}

{{- define "traefik.namespace" -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" . ) -}}
{{- printf "%s" ($cnfHdr.nfVariables.nfPrefix) -}}
{{- end }}

{{/*
Construct a comma-separated list of whitelisted namespaces
*/}}
{{- define "providers.kubernetesIngress.namespaces" -}}
{{- default (include "traefik.namespace" .) (join "," .Values.providers.kubernetesIngress.namespaces) }}
{{- end -}}
{{- define "providers.kubernetesCRD.namespaces" -}}
{{- default (include "traefik.namespace" .) (join "," .Values.providers.kubernetesCRD.namespaces) }}
{{- end -}}

{{/*
Construct a comma-separated list of whitelisted namespaces
*/}}
{{- define "scope.namespaceList" -}}
{{- default (include "traefik.namespace" .) (join "," .Values.global.mtcil.scope.namespaceList) }}
{{- end -}}

{{- define "traefik.metadata1" -}}
{{- $specOffset := .specOffset -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" .dot ) -}}
{{- printf "metadata: " | nindent (add $specOffset 0 | int) -}}
{{- printf "name: %s" (include "traefik.fullname" .dot) | nindent (add $specOffset 2 | int) -}}
{{- printf "namespace: %s" ($cnfHdr.nfVariables.nfPrefix) | nindent (add $specOffset 2 | int) -}}
{{- printf "annotations:" | nindent (add $specOffset 2 | int) -}}
{{- printf "init: \"true\"" | nindent (add $specOffset 4 | int) -}}
{{- include "tmaasSpec_2_27" (merge (dict "specOffset" (add $specOffset 4 | int) ) (dict "nfVariables" $cnfHdr.nfVariables)) -}}
{{- printf "svcVersion: \"%s\"" ($cnfHdr.nfVariables.svcVersion | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "topogw.fqdn: \"%s\"" ($cnfHdr.nfVariables.topogwFQDN | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "nwFnPrefix: \"%s\"" ($cnfHdr.nfVariables.nfPrefix) | nindent (add $specOffset 4 | int) -}}
{{- with .dot.Values.deployment.annotations -}}
{{- toYaml . | nindent (add $specOffset 4 | int) }}
{{- end }}
{{- printf "labels:" | nindent (add $specOffset 2 | int) }}
{{- printf "microSvcName: %s" ($cnfHdr.nfVariables.svcname) | nindent (add $specOffset 4 | int) -}}
{{- printf "mtcilId: %s" ($cnfHdr.nfVariables.mtcilId) | nindent (add $specOffset 4 | int) -}}
{{- printf "nfType: %s" ($cnfHdr.nfVariables.nfType) | nindent (add $specOffset 4 | int) -}}
{{- printf "nfId: %s" ($cnfHdr.nfVariables.nfId) | nindent (add $specOffset 4 | int) -}}
{{- printf "app.kubernetes.io/name: %s" (include "traefik.name" .dot) | nindent (add $specOffset 4 | int) -}}
{{- printf "helm.sh/chart: %s" (include "traefik.chart" .dot) | nindent (add $specOffset 4 | int) -}}
{{- printf "app.kubernetes.io/managed-by: %s" .dot.Release.Service | nindent (add $specOffset 4 | int) -}}
{{- printf "app.kubernetes.io/instance: %s" .dot.Release.Name | nindent (add $specOffset 4 | int) -}}
{{- with .dot.Values.deployment.labels }}
{{- toYaml . | nindent (add $specOffset 4 | int) }}
{{- end }}
{{- end -}}

{{- define "traefik.metadata.annotatetmaasspec" -}}
{{- $specOffset := .specOffset -}}
{{- $nfService := .nfService -}}
{{- printf "mtcil.com/tmaas: '{" | nindent (add $specOffset 0 | int) -}}
{{- printf "\"vendorId\": \"%s\"," (.cnfHdr.nfVariables.root.Values.nf.vendorId | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "\"mtcilId\": \"%s\"," (.cnfHdr.nfVariables.root.Values.global.nf.mtcilId | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "\"nfClass\": \"%s\"," (.cnfHdr.nfVariables.root.Values.nf.nfClass | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "\"nfType\": \"%s\"," (.cnfHdr.nfVariables.root.Values.nf.nfType | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "\"nfId\": \"%s\"," (.cnfHdr.nfVariables.root.Values.global.nf.nfId | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "\"nfServiceId\": \"%s\"," ( $nfService | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "\"nfServiceType\": \"%s\"" ($nfService | toString) | nindent (add $specOffset 4 | int) -}}
{{- printf "}'" | nindent (add $specOffset 2 | int) -}}
{{- end -}}


{{- define "traefik.metadata.mtcilannotations" -}}
{{- $specOffset := .specOffset -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" .dot ) -}}
{{- printf "init: \"true\"" | indent (add $specOffset 0 | int) | trim -}}
{{- if $cnfHdr.nfVariables.root.Values.app_name_prefix -}}
{{- include "traefik.metadata.annotatetmaasspec" (dict "specOffset" $specOffset "cnfHdr" $cnfHdr "nfService" $cnfHdr.nfVariables.root.Values.app_name_prefix ) -}}
{{- else }}
{{- include "traefik.metadata.annotatetmaasspec" (dict "specOffset" $specOffset "cnfHdr" $cnfHdr "nfService" (include "traefik.fullname" .dot) ) -}}
{{- end }}
{{- printf "svcVersion: \"%s\"" ($cnfHdr.nfVariables.svcVersion | toString) | nindent (add $specOffset 0 | int) -}}
{{- printf "topogw.fqdn: \"%s\"" ($cnfHdr.nfVariables.topogwFQDN | toString) | nindent (add $specOffset 0 | int) -}}
{{- printf "nwFnPrefix: \"%s\"" ($cnfHdr.nfVariables.nfPrefix) | nindent (add $specOffset 0 | int) -}}
{{- end -}}

{{- define "traefik.metadata.mtcillabels" -}}
{{- $specOffset := .specOffset -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" .dot ) -}}
{{- printf "microSvcName: %s" ($cnfHdr.nfVariables.svcname) | indent (add $specOffset 0 | int) | trim -}}
{{- printf "mtcilId: %s" ($cnfHdr.nfVariables.mtcilId) | nindent (add $specOffset 0 | int) -}}
{{- printf "component: %s" ($cnfHdr.nfVariables.component) | nindent (add $specOffset 0 | int) -}}
{{- printf "nfType: %s" ($cnfHdr.nfVariables.nfType) | nindent (add $specOffset 0 | int) -}}
{{- printf "nfId: %s" ($cnfHdr.nfVariables.nfId) | nindent (add $specOffset 0 | int) -}}
{{- end -}}

