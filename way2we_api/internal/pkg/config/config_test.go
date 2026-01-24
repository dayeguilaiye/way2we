package config

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLoadConfig_AppPublicURL(t *testing.T) {
	// Setup environment for test if needed, or rely on default config
	// For this test, we assume configs/config.yaml will have the value

	// Temporarily switch to project root to load config
	originalWd, _ := os.Getwd()
	os.Chdir("../../../") // assuming we run from internal/pkg/config
	defer os.Chdir(originalWd)

	cfg, err := LoadConfig()
	assert.NoError(t, err)
	assert.NotNil(t, cfg)

	// This expectation will fail initially because App struct doesn't exist
	// or PublicURL is empty
	assert.Equal(t, "http://localhost:8080", cfg.App.PublicURL)
}
