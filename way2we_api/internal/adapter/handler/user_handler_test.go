package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/user"

	_ "github.com/mattn/go-sqlite3"
)

// MockStorageProvider
type MockStorageProvider struct {
	UploadFunc            func(ctx context.Context, file io.Reader, filename string) (string, error)
	DeleteFunc            func(ctx context.Context, key string) error
	GetPublicUrlFunc      func(key string) string
	ExtractKeyFromUrlFunc func(url string) string
}

func (m *MockStorageProvider) Upload(ctx context.Context, file io.Reader, filename string) (string, error) {
	if m.UploadFunc != nil {
		return m.UploadFunc(ctx, file, filename)
	}
	return "mock_key.jpg", nil
}

func (m *MockStorageProvider) Delete(ctx context.Context, key string) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(ctx, key)
	}
	return nil
}

func (m *MockStorageProvider) GetPublicUrl(key string) string {
	if m.GetPublicUrlFunc != nil {
		return m.GetPublicUrlFunc(key)
	}
	return "http://localhost/uploads/" + key
}

func (m *MockStorageProvider) ExtractKeyFromUrl(url string) string {
	if m.ExtractKeyFromUrlFunc != nil {
		return m.ExtractKeyFromUrlFunc(url)
	}
	return ""
}

func TestUserHandler_UpdateProfile(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	// Create user
	ctx := context.Background()
	u, err := client.User.Create().SetNickname("Old").SetPasswordHash("hash").Save(ctx)
	require.NoError(t, err)

	userService := user.NewService(client)
	h := handler.NewUserHandler(userService, nil)

	e := echo.New()
	reqBody := map[string]string{"nickname": "NewName"}
	body, _ := json.Marshal(reqBody)
	req := httptest.NewRequest(http.MethodPut, "/v1/users/me", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Inject user ID into context (simulating JWT middleware)
	c.Set("user_id", u.ID)

	// Execute
	err = h.UpdateProfile(c)

	// Assert
	if assert.NoError(t, err) {
		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Contains(t, rec.Body.String(), "NewName")
	}
}

func TestUserHandler_UploadAvatar(t *testing.T) {
	// Setup Mock Storage
	mockStorage := &MockStorageProvider{
		UploadFunc: func(ctx context.Context, file io.Reader, filename string) (string, error) {
			return "avatar123.jpg", nil
		},
		GetPublicUrlFunc: func(key string) string {
			return "http://localhost/uploads/" + key
		},
	}

	h := handler.NewUserHandler(nil, mockStorage)
	e := echo.New()

	// Create Multipart Form
	body := new(bytes.Buffer)
	writer := multipart.NewWriter(body)

	// Use CreatePart to set Content-Type explicitly
	hPart := make(textproto.MIMEHeader)
	hPart.Set("Content-Disposition", `form-data; name="avatar"; filename="test.jpg"`)
	hPart.Set("Content-Type", "image/jpeg")
	part, _ := writer.CreatePart(hPart)
	part.Write([]byte("fake image content"))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/v1/uploads/avatar", body)
	req.Header.Set(echo.HeaderContentType, writer.FormDataContentType())
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Inject user ID into context (simulating JWT middleware)
	c.Set("user_id", 1)

	// Execute
	err := h.UploadAvatar(c)

	// Assert
	if assert.NoError(t, err) {
		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Contains(t, rec.Body.String(), "http://localhost/uploads/avatar123.jpg")
	}
}
