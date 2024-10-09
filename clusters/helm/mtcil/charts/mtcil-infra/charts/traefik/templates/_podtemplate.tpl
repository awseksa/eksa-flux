{{- define "traefik.podTemplate" }}
    metadata:
      namespace: {{ template "traefik.namespace" . }}
      annotations:
        {{ template "traefik.metadata.mtcilannotations" (dict "specOffset" 8 "dot" .) }}
      {{- with .Values.deployment.podAnnotations }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- $custom_extensions := .Values.global.custom_extensions | default dict -}}
      {{- $pod_metaspec := .Values.componentSpec | default dict -}}
      {{- if $custom_extensions.annotations -}}
      {{- range $key, $value := .Values.global.custom_extensions.annotations }}
        {{ $key }}: {{ $value | quote }}
      {{- end }}
      {{- end }}
      labels:
        {{ template "traefik.metadata.mtcillabels" (dict "specOffset" 8 "dot" .) }}
        app.kubernetes.io/name: {{ template "traefik.name" . }}
        helm.sh/chart: {{ template "traefik.chart" . }}
        app.kubernetes.io/managed-by: {{ .Release.Service }}
        app.kubernetes.io/instance: {{ .Release.Name }}
      {{- with .Values.deployment.podLabels }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if $custom_extensions.labels -}}
      {{- range $key, $value := .Values.global.custom_extensions.labels }}
        {{ $key }}: {{ $value | quote }}
      {{- end }}
      {{- end }}
      {{- if $pod_metaspec.deployment -}}
      {{- range $key, $value := $pod_metaspec.deployment.pod_metaspec.labels }}
        {{ $key }}: {{ $value | quote }}
      {{- end }}
      {{- end }}
    spec:
      {{- with .Values.deployment.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- if  .Values.podConfig }}
{{ toYaml .Values.podConfig | indent 6 }}
{{- end }}
{{- if .Values.global.mtcil.podConfig }}
{{ toYaml .Values.global.mtcil.podConfig | indent 6 }}
{{- end }}
{{- if  .Values.affinity }}
      affinity:
{{ toYaml .Values.affinity | indent 8 }}
{{- end }}
      serviceAccountName: {{ include "traefik.serviceAccountName" . }}
      terminationGracePeriodSeconds: 60
      hostNetwork: {{ .Values.hostNetwork }}
      {{- with .Values.deployment.dnsPolicy }}
      dnsPolicy: {{ . }}
      {{- end }}
      {{- with .Values.deployment.initContainers }}
      initContainers:
      {{- toYaml . | nindent 6 }}
      {{- end }}
      containers:
      - image: {{ .Values.global.hub }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}
        imagePullPolicy: {{ .Values.global.mtcil.imagePullPolicy }}
{{- if  .Values.containerConfig }}
{{ toYaml .Values.containerConfig | indent 8 }}
{{- else if .Values.global.mtcil.containerConfig }}
{{ toYaml .Values.global.mtcil.containerConfig | indent 8 }}
{{- end }}
        name: {{ template "traefik.fullname" . }}
        resources:
          {{- with .Values.resources }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        readinessProbe:
          httpGet:
            path: /ping
            port: {{ default .Values.ports.traefik.port .Values.ports.traefik.healthchecksPort }}
          failureThreshold: 1
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        livenessProbe:
          httpGet:
            path: /ping
            port: {{ default .Values.ports.traefik.port .Values.ports.traefik.healthchecksPort }}
          failureThreshold: 3
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        ports:
        {{- range $name, $config := .Values.ports }}
        {{- if $config }}
        - name: {{ $name | quote }}
          containerPort: {{ $config.port }}
          {{- if $config.hostPort }}
          hostPort: {{ $config.hostPort }}
          {{- end }}
          {{- if $config.hostIP }}
          hostIP: {{ $config.hostIP }}
          {{- end }}
          protocol: {{ default "TCP" $config.protocol | quote }}
        {{- end }}
        {{- end }}
        {{- range $name, $config := .Values.addOnPorts }}
        {{- if $config }}
        - name: {{ $name | quote }}
          containerPort: {{ $config.port }}
          {{- if $config.hostPort }}
          hostPort: {{ $config.hostPort }}
          {{- end }}
          {{- if $config.hostIP }}
          hostIP: {{ $config.hostIP }}
          {{- end }}
          protocol: {{ default "TCP" $config.protocol | quote }}
        {{- end }}
        {{- end }}
        volumeMounts:
          - name: {{ .Values.persistence.name }}
            mountPath: {{ .Values.persistence.path }}
            {{- if .Values.persistence.subPath }}
            subPath: {{ .Values.persistence.subPath }}
            {{- end }}
          - name: tmp
            mountPath: /tmp
          {{- $root := . }}
          {{- range .Values.volumes }}
          - name: {{ tpl (.name) $root }}
            mountPath: {{ .mountPath }}
            readOnly: true
          {{- end }}
          {{- if .Values.experimental.plugins.enabled }}
          - name: plugins
            mountPath: "/plugins-storage"
          {{- end }}
          {{- if .Values.additionalVolumeMounts }}
            {{- toYaml .Values.additionalVolumeMounts | nindent 10 }}
          {{- end }}
        args:
          {{- with .Values.globalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
          {{- range $name, $config := .Values.ports }}
          {{- if $config }}
          - "--entryPoints.{{$name}}.address=:{{ $config.port }}/{{ default "tcp" $config.protocol | lower }}"
          {{- end }}
          {{- end }}
          {{- range $name, $config := .Values.addOnPorts }}
          {{- if $config }}
          - "--entryPoints.{{$name}}.address=:{{ $config.port }}/{{ default "tcp" $config.protocol | lower }}"
          {{- end }}
          {{- end }}
          - "--api.dashboard=true"
          - "--ping=true"
          {{- if .Values.providers.kubernetesCRD.enabled }}
          - "--providers.kubernetescrd"
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.enabled }}
          - "--providers.kubernetesingress"
          {{- if and .Values.service.enabled .Values.providers.kubernetesIngress.publishedService.enabled }}
          - "--providers.kubernetesingress.ingressendpoint.publishedservice={{ template "providers.kubernetesIngress.publishedServicePath" . }}"
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.labelSelector }}
          - "--providers.kubernetesingress.labelSelector={{ .Values.providers.kubernetesIngress.labelSelector }}"
          {{- end }}
          {{- end }}
          {{- if .Values.experimental.kubernetesGateway.enabled }}
          - "--providers.kubernetesgateway"
          - "--experimental.kubernetesgateway"
          {{- end }}
          {{- if and .Values.rbac.enabled .Values.global.mtcil.scope.namespaced }}
          {{- if .Values.providers.kubernetesCRD.enabled }}
          - "--providers.kubernetescrd.namespaces={{ template "scope.namespaceList" . }}"
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.enabled }}
          - "--providers.kubernetesingress.namespaces={{ template "scope.namespaceList" . }}"
          {{- end }}
          {{- end }}
          {{- range $entrypoint, $config := $.Values.ports }}
          {{- if $config.redirectTo }}
          {{- $toPort := index $.Values.ports $config.redirectTo }}
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.to=:{{ $toPort.exposedPort }}"
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.scheme=https"
          {{- end }}
          {{- if $config.tls }}
          {{- if $config.tls.enabled }}
          - "--entrypoints.{{ $entrypoint }}.http.tls=true"
          {{- if $config.tls.options }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.options={{ $config.tls.options }}"
          {{- end }}
          {{- if $config.tls.certResolver }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.certResolver={{ $config.tls.certResolver }}"
          {{- end }}
          {{- if $config.tls.domains }}
          {{- range $index, $domain := $config.tls.domains }}
          {{- if $domain.main }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].main={{ $domain.main }}"
          {{- end }}
          {{- if $domain.sans }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].sans={{ join "," $domain.sans }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- range $entrypoint, $config := $.Values.addOnPorts }}
          {{- if $config.redirectTo }}
          {{- $toPort := index $.Values.addOnPorts $config.redirectTo }}
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.to=:{{ $toPort.exposedPort }}"
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.scheme=https"
          {{- end }}
          {{- if $config.tls }}
          {{- if $config.tls.enabled }}
          - "--entrypoints.{{ $entrypoint }}.http.tls=true"
          {{- if $config.tls.options }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.options={{ $config.tls.options }}"
          {{- end }}
          {{- if $config.tls.certResolver }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.certResolver={{ $config.tls.certResolver }}"
          {{- end }}
          {{- if $config.tls.domains }}
          {{- range $index, $domain := $config.tls.domains }}
          {{- if $domain.main }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].main={{ $domain.main }}"
          {{- end }}
          {{- if $domain.sans }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].sans={{ join "," $domain.sans }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- with .Values.logs }}
          {{- if .general.format }}
          - "--log.format={{ .general.format }}"
          {{- end }}
          {{- if ne .general.level "ERROR" }}
          - "--log.level={{ .general.level | upper }}"
          {{- end }}
          {{- if .access.enabled }}
          - "--accesslog=true"
          {{- if .access.format }}
          - "--accesslog.format={{ .access.format }}"
          {{- end }}
          {{- if .access.bufferingsize }}
          - "--accesslog.bufferingsize={{ .access.bufferingsize }}"
          {{- end }}
          {{- if .access.filters }}
          {{- if .access.filters.statuscodes }}
          - "--accesslog.filters.statuscodes={{ .access.filters.statuscodes }}"
          {{- end }}
          {{- if .access.filters.retryattempts }}
          - "--accesslog.filters.retryattempts"
          {{- end }}
          {{- if .access.filters.minduration }}
          - "--accesslog.filters.minduration={{ .access.filters.minduration }}"
          {{- end }}
          {{- end }}
          - "--accesslog.fields.defaultmode={{ .access.fields.general.defaultmode }}"
          {{- range $fieldname, $fieldaction := .access.fields.general.names }}
          - "--accesslog.fields.names.{{ $fieldname }}={{ $fieldaction }}"
          {{- end }}
          - "--accesslog.fields.headers.defaultmode={{ .access.fields.headers.defaultmode }}"
          {{- range $fieldname, $fieldaction := .access.fields.headers.names }}
          - "--accesslog.fields.headers.names.{{ $fieldname }}={{ $fieldaction }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- if .Values.pilot.enabled }}
          - "--pilot.token={{ .Values.pilot.token }}"
          {{- end }}
          {{- if hasKey .Values.pilot "dashboard" }}
          - "--pilot.dashboard={{ .Values.pilot.dashboard }}"
          {{- end }}
          {{- with .Values.additionalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
        {{- with .Values.env }}
        env:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.envFrom }}
        envFrom:
          {{- toYaml . | nindent 10 }}
        {{- end }}
      {{- if .Values.deployment.additionalContainers }}
        {{- toYaml .Values.deployment.additionalContainers | nindent 6 }}
      {{- end }}
      volumes:
        - name: {{ .Values.persistence.name }}
          {{- if .Values.persistence.enabled }}
          persistentVolumeClaim:
            claimName: {{ default (include "traefik.fullname" .) .Values.persistence.existingClaim }}
          {{- else }}
          emptyDir: {}
          {{- end }}
        - name: tmp
          emptyDir: {}
        {{- $root := . }}
        {{- range .Values.volumes }}
        - name: {{ tpl (.name) $root }}
          {{- if eq .type "secret" }}
          secret:
            secretName: {{ tpl (.name) $root }}
          {{- else if eq .type "configMap" }}
          configMap:
            name: {{ tpl (.name) $root }}
          {{- end }}
        {{- end }}
        {{- if .Values.deployment.additionalVolumes }}
          {{- toYaml .Values.deployment.additionalVolumes | nindent 8 }}
        {{- end }}
        {{- if .Values.experimental.plugins.enabled }}
        - name: plugins
          emptyDir: {}
        {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if and (.Values.global) (.Values.global.mtcil) (.Values.global.mtcil.infraNodeSelector) (.Values.global.mtcil.infraNodeSelector.enabled) }}
      nodeSelector:
        {{ .Values.global.mtcil.infraNodeSelector.labelKey }}: {{ .Values.global.mtcil.infraNodeSelector.labelValue | quote }}
      {{- end }}
      {{- if .Values.priorityClassName }}
      priorityClassName: {{ .Values.priorityClassName }}
      {{- end }}
{{ end -}}
