package bedrock

import (
	"github.com/monzo/terrors"
	"os"
	"path"
)

var nixAssetsDir = ""

// NixAssetsDir returns the assets folder added by Nix at runtime.
//
// When running outside of Nix, this simply returns the dir the binary
// is in.
func NixAssetsDir() (string, error) {
	//goland:noinspection GoBoolExpressions
	if nixAssetsDir != "" {
		return nixAssetsDir, nil
	}

	e, err := os.Executable()
	if err != nil {
		return "", terrors.Propagate(err)
	}
	return path.Dir(e), nil
}
