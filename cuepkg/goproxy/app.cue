package goproxy

import (
	kubepkg "github.com/octohelm/kubepkg/cuepkg/kubepkg"
)

#GoProxy: kubepkg.#KubePkg & {
	metadata: {
		name: _ | *"goproxy"
	}

	spec: {
		version: _ | *"test"

		deploy: {
			kind: "Deployment"
			spec: {
				replicas: _ | *1
			}
		}

		config: {
			GOPRIVATE:     _ | *"git.innoai.tech"
			GOPROXY:       _ | *"https://goproxy.cn"
			PROXIEDSUMDBS: _ | *"sum.golang.org \(GOPROXY)/sumdb/sum.golang.org"
		}

		services: "#": {
			ports: containers."goproxy".ports
			paths: http: "/"
			expose: _ | *{
				type:    "Ingress"
				gateway: _ | *["goproxy.x.io"]
			}
		}

		containers: "goproxy": {
			image: {
				name: _ | *"ghcr.io/octohelm/goproxy"
				tag:  _ | *"\(spec.version)"
			}
			ports: http: 80
			env: PORT:   "80"
			readinessProbe: kubepkg.#Probe & {
				httpGet: {path: "/golang.org/x/mod/@v/v0.7.0.mod", port: ports.http}
			}
			livenessProbe: readinessProbe
		}

		volumes: storage: {
			type:      "PersistentVolumeClaim"
			mountPath: "/go/pkg/mod"
			opt: {
				claimName: "goproxy-storage"
			}
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "10Gi"
				storageClassName: "local-path"
			}
		}
	}
}
