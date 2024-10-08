package module

import (
	"github.com/cottand/selfhosted/dev-go/lib/bedrock"
	"github.com/cottand/selfhosted/dev-go/lib/mono"
	s_rpc_nomad_api "github.com/cottand/selfhosted/dev-go/lib/proto/s-rpc-nomad-api"
	nomad "github.com/hashicorp/nomad/api"
	"google.golang.org/grpc"
	"os"
)

var Name, slog, tracer = bedrock.Service("s-rpc-nomad-api")

func InitService() {
	token, ok := os.LookupEnv("NOMAD_TOKEN")
	if !ok {
		slog.Error("failed to get NOMAD_TOKEN, aborting init")
		return
	}
	nomadClient, err := nomad.NewClient(&nomad.Config{
		Address:  "unix:///secrets/api.sock",
		SecretID: token,
	})
	if err != nil {
		slog.Error("failed to create Nomad client, aborting init", "err", err.Error())
		return
	}
	protoHandler := &ProtoHandler{
		nomadClient: nomadClient,
	}
	this := mono.Service{
		Name: Name,
		RegisterGrpc: func(srv *grpc.Server) {
			s_rpc_nomad_api.RegisterNomadApiServer(srv, protoHandler)
		},
	}

	notify := mono.Register(this)

	go func() {
		_, _ = <-notify
		nomadClient.Close()
	}()
}
