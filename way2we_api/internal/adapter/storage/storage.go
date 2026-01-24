package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

// Provider defines the interface for file storage operations.
type Provider interface {
	Upload(ctx context.Context, file io.Reader, filename string) (string, error)
	Delete(ctx context.Context, key string) error
	GetPublicUrl(key string) string
	ExtractKeyFromUrl(url string) string
}

type LocalStorageProvider struct {
	uploadDir string
	publicURL string
}

func NewLocalStorageProvider(uploadDir string, publicURL string) *LocalStorageProvider {
	return &LocalStorageProvider{
		uploadDir: uploadDir,
		publicURL: publicURL,
	}
}

func (p *LocalStorageProvider) Upload(ctx context.Context, file io.Reader, filename string) (string, error) {
	// Create directory if not exists
	if err := os.MkdirAll(p.uploadDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create upload directory: %w", err)
	}

	// Generate unique key
	ext := filepath.Ext(filename)
	key := uuid.New().String() + ext

	// Save file
	dstPath := filepath.Join(p.uploadDir, key)
	dst, err := os.Create(dstPath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		return "", fmt.Errorf("failed to copy file content: %w", err)
	}

	return key, nil
}

// Delete removes a file by its key.
// If the file doesn't exist, it returns nil (idempotent).
func (p *LocalStorageProvider) Delete(ctx context.Context, key string) error {
	if key == "" {
		return nil
	}

	filePath := filepath.Join(p.uploadDir, key)

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		// File doesn't exist, nothing to delete
		return nil
	}

	if err := os.Remove(filePath); err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

func (p *LocalStorageProvider) GetPublicUrl(key string) string {
	baseUrl := strings.TrimRight(p.publicURL, "/")
	return fmt.Sprintf("%s/uploads/%s", baseUrl, key)
}

// ExtractKeyFromUrl extracts the storage key from a public URL.
// Returns empty string if the URL doesn't match the expected format.
func (p *LocalStorageProvider) ExtractKeyFromUrl(url string) string {
	if url == "" {
		return ""
	}

	// Expected format: {baseUrl}/uploads/{key}
	prefix := strings.TrimRight(p.publicURL, "/") + "/uploads/"
	if strings.HasPrefix(url, prefix) {
		return strings.TrimPrefix(url, prefix)
	}

	return ""
}
