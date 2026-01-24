package validator_test

import (
	"mime/multipart"
	"net/textproto"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/way2we/way2we_api/internal/pkg/validator"
)

func TestValidateImageFile(t *testing.T) {
	// Case 1: Too Large
	header := &multipart.FileHeader{
		Size: 11 * 1024 * 1024, // 11MB
	}
	err := validator.ValidateImageFile(header)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "too large")

	// Case 2: Invalid Content Type
	header = &multipart.FileHeader{
		Size:   1 * 1024 * 1024,
		Header: make(textproto.MIMEHeader),
	}
	header.Header.Set("Content-Type", "text/plain")
	err = validator.ValidateImageFile(header)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid image format")

	// Case 3: Valid JPEG
	header = &multipart.FileHeader{
		Size:   1 * 1024 * 1024,
		Header: make(textproto.MIMEHeader),
	}
	header.Header.Set("Content-Type", "image/jpeg")
	err = validator.ValidateImageFile(header)
	assert.NoError(t, err)

	// Case 4: Valid PNG
	header.Header.Set("Content-Type", "image/png")
	err = validator.ValidateImageFile(header)
	assert.NoError(t, err)

	// Case 5: Valid WebP
	header.Header.Set("Content-Type", "image/webp")
	err = validator.ValidateImageFile(header)
	assert.NoError(t, err)
}
