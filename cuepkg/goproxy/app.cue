package goproxy

import (
	"github.com/innoai-tech/runtime/cuepkg/kube"
)

#GoProxy: kube.#App & {
	app: {
		name:    "goproxy"
		version: _ | *"main"
	}

	services: "\(app.name)": {
		selector: "app": app.name
		ports: containers."goproxy".ports
	}

	containers: "goproxy": {
		image: {
			name: _ | *"ghcr.io/octohelm/goproxy"
			tag:  _ | *"\(app.version)"
		}
		ports: http: 80
		env: {
			"GOPROXY":       _ | *"https://goproxy.cn"
			"GOSUMDB":       _ | *"sum.golang.org"
			"PROXIEDSUMDBS": _ | *"sum.golang.org https://goproxy.cn/sumdb/sum.golang.org"
		}
		readinessProbe: kube.#ProbeHttpGet & {
			httpGet: {path: "/golang.org/x/mod/@v/v0.5.1.mod", port: ports.http}
		}
		livenessProbe: readinessProbe
	}

	volumes: storage: #GoProxyStorage
}

#GoProxyStorage: kube.#Volume & {
	mountPath: "/data"
	source: {
		claimName: "goproxy-storage"
		spec: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: "10Gi"
			storageClassName: "local-path"
		}
	}
}
