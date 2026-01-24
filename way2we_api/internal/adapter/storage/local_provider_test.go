package storage_test

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/way2we/way2we_api/internal/adapter/storage"

	"github.com/stretchr/testify/assert"
)

func TestLocalStorageProvider_Upload(t *testing.T) {
	// Setup temporary upload directory
	tempDir := t.TempDir()
	publicURL := "http://localhost:8080"

	provider := storage.NewLocalStorageProvider(tempDir, publicURL)

	// Test case: Upload file
	filename := "test_avatar.jpg"
	content := "fake image content"
	reader := strings.NewReader(content)

	key, err := provider.Upload(context.Background(), reader, filename)

	assert.NoError(t, err)
	assert.NotEmpty(t, key)
	// Key should contain the filename (or a generated one with extension)
	// The simple implementation follows: uploads/key

	// Verify file exists on disk
	fullPath := filepath.Join(tempDir, key)
	fileContent, err := os.ReadFile(fullPath)
	assert.NoError(t, err)
	assert.Equal(t, content, string(fileContent))

	// Test case: GetPublicUrl
	url := provider.GetPublicUrl(key)

	expectedUrlSuffix := "/uploads/" + key
	assert.True(t, strings.HasSuffix(url, expectedUrlSuffix), "URL %s should end with %s", url, expectedUrlSuffix)
}
