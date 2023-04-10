package main

import (
	"fmt"
	"os"
	"runtime"

	"github.com/botheaj/service4/foundation/logger"
	"go.uber.org/zap"
)

func main() {
	log, err := logger.New("SALES-API")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer log.Sync()

	if err := run(log); err != nil {
		log.Errorw("startup", "ERROR", err)
		log.Sync()
		os.Exit(1)
	}
}

func run(log *zap.SugaredLogger) error {
	log.Infow("startup", "GOMAXPROCS", runtime.GOMAXPROCS(0))
	return nil
}
