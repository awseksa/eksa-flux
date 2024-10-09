{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kruise.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kruise.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "kruise.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kruise.namespace" -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" . ) -}}
{{- printf "%s" ($cnfHdr.nfVariables.nfPrefix) -}}
{{- end }}

{{- define "kruise.metadata.annotatetmaasspec" -}}
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

{{- define "kruise.metadata.mtcilannotations" -}}
{{- $specOffset := .specOffset -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" .dot ) -}}
{{- printf "init: \"true\"" | indent (add $specOffset 0 | int) | trim -}}
{{- if $cnfHdr.nfVariables.root.Values.app_name_prefix -}}
{{- include "kruise.metadata.annotatetmaasspec" (dict "specOffset" $specOffset "cnfHdr" $cnfHdr "nfService" (printf "%s" $cnfHdr.nfVariables.root.Values.app_name_prefix )) -}}
{{- else }}
{{- include "kruise.metadata.annotatetmaasspec" (dict "specOffset" $specOffset "cnfHdr" $cnfHdr "nfService" (printf "%s-controller-manager" (include "kruise.fullname" .dot)) ) -}}
{{- end }}
{{- printf "svcVersion: \"%s\"" ($cnfHdr.nfVariables.svcVersion | toString) | nindent (add $specOffset 0 | int) -}}
{{- printf "topogw.fqdn: \"%s\"" ($cnfHdr.nfVariables.topogwFQDN | toString) | nindent (add $specOffset 0 | int) -}}
{{- printf "nwFnPrefix: \"%s\"" ($cnfHdr.nfVariables.nfPrefix) | nindent (add $specOffset 0 | int) -}}
{{- end -}}

{{- define "kruise.metadata.mtcillabels" -}}
{{- $specOffset := .specOffset -}}
{{- $cnfHdr := (dict "" "") -}}
{{- include "cnfTplHeader_2_27" (dict "cnfHdr" $cnfHdr "dot" .dot ) -}}
{{- printf "microSvcName: %s" ($cnfHdr.nfVariables.svcname) | indent (add $specOffset 0 | int) | trim -}}
{{- printf "mtcilId: %s" ($cnfHdr.nfVariables.mtcilId) | nindent (add $specOffset 0 | int) -}}
{{- printf "component: %s" ($cnfHdr.nfVariables.component) | nindent (add $specOffset 0 | int) -}}
{{- printf "app.kubernetes.io/name: %s" ($cnfHdr.nfVariables.svcname) | nindent (add $specOffset 0 | int) -}}
{{- printf "app.kubernetes.io/instance: %s" ($cnfHdr.nfVariables.release_name) | nindent (add $specOffset 0 | int) -}}
{{- printf "nfType: %s" ($cnfHdr.nfVariables.nfType) | nindent (add $specOffset 0 | int) -}}
{{- printf "nfId: %s" ($cnfHdr.nfVariables.nfId) | nindent (add $specOffset 0 | int) -}}
{{- end -}}

