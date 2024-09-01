package module

import (
	"context"
	"embed"
	"github.com/cottand/selfhosted/services/lib/bedrock"
	"github.com/cottand/selfhosted/services/lib/mono"
	s_rpc_portfolio_stats "github.com/cottand/selfhosted/services/lib/proto/s-rpc-portfolio-stats"
	"github.com/monzo/terrors"
	"google.golang.org/grpc"
	"log"
	"log/slog"
)

//go:embed migrations
var dbMigrations embed.FS

var Name = "s-rpc-portfolio-stats"

var logger = slog.With("service_module", Name)

func InitService() {
	db, err := bedrock.GetMigratedDB(Name, dbMigrations)
	if err != nil {
		log.Fatal(err.Error())
	}
	this := mono.Service{
		Name: Name,
		RegisterGrpc: func(srv *grpc.Server) {
			s_rpc_portfolio_stats.RegisterPortfolioStatsServer(srv, &ProtoHandler{db: db})
		},
	}

	notify := mono.Register(this)

	refreshCtx, refreshCancel := context.WithCancel(context.Background())

	go RefreshPromStats(refreshCtx, db)

	go func() {
		_, _ = <-notify
		refreshCancel()
		if db.Close() != nil {
			logger.Error(terrors.Propagate(err).Error(), "Failed to close DB", "service", Name)
		}
	}()
}
