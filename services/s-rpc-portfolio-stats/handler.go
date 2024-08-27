package main

import (
	"context"
	"crypto"
	"database/sql"
	"encoding/hex"
	s_portfolio_stats "github.com/cottand/selfhosted/services/lib/proto/s-portfolio-stats"
	"github.com/monzo/terrors"
	"google.golang.org/protobuf/types/known/emptypb"
	"log/slog"
	"strings"
	"time"
)

type ProtoHandler struct {
	s_portfolio_stats.UnimplementedPortfolioStatsServer

	db   *sql.DB
	hash *crypto.Hash
}

var _ s_portfolio_stats.PortfolioStatsServer = &ProtoHandler{}

var excludeUrls = []string{
	"/static",
	"/assets",
}

var salt = []byte{4, 49, 127, 104, 174, 252, 225, 13}

func (p *ProtoHandler) Report(ctx context.Context, visit *s_portfolio_stats.Visit) (*emptypb.Empty, error) {
	slog.Info("Received visit! ", "ip", visit.Ip)

	for _, urlSub := range excludeUrls {
		if strings.Contains(visit.Url, urlSub) {
			return &emptypb.Empty{}, nil
		}
	}
	var sha256 = crypto.SHA256.New()
	sha256.Write(salt)
	sha256.Write([]byte(visit.Ip))
	sha256.Write([]byte(visit.UserAgent))
	hashAsString := hex.EncodeToString(sha256.Sum(nil))

	_, err := p.db.ExecContext(ctx, "INSERT INTO  \"s-rpc-portfolio-stats\".visit (url, inserted_at, fingerprint_v1) VALUES ($1, $2, $3)", visit.Url, time.Now(), hashAsString)

	if err != nil {
		return nil, terrors.Augment(err, "failed to insert visit into db", nil)
	}

	return &emptypb.Empty{}, nil
}
