module: "github.com/octohelm/goproxy"

require: {
	"dagger.io":                      "v0.3.0"
	"github.com/innoai-tech/runtime": "v0.0.0-20220610020543-4da0f32c31bb"
	"universe.dagger.io":             "v0.3.0"
}

require: {
	"k8s.io/api":          "v0.24.1" @indirect()
	"k8s.io/apimachinery": "v0.24.1" @indirect()
}

replace: {
	"k8s.io/api":          "" @import("go")
	"k8s.io/apimachinery": "" @import("go")
}
