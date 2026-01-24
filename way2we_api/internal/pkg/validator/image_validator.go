package validator

import (
	"fmt"
	"mime/multipart"
)

const MaxImageSize = 10 * 1024 * 1024 // 10MB

var AllowedImageTypes = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/webp": true,
}

func ValidateImageFile(file *multipart.FileHeader) error {
	if file.Size > MaxImageSize {
		return fmt.Errorf("image too large (Max 10MB)")
	}

	contentType := file.Header.Get("Content-Type")
	if !AllowedImageTypes[contentType] {
		return fmt.Errorf("invalid image format: %s", contentType)
	}

	return nil
}
