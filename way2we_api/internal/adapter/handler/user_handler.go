package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/internal/adapter/storage"
	"github.com/way2we/way2we_api/internal/app/user"
	"github.com/way2we/way2we_api/internal/pkg/validator"
)

type UserHandler struct {
	userService     *user.Service
	storageProvider storage.Provider
}

func NewUserHandler(userService *user.Service, storageProvider storage.Provider) *UserHandler {
	return &UserHandler{
		userService:     userService,
		storageProvider: storageProvider,
	}
}

type UpdateProfileRequest struct {
	Nickname *string `json:"nickname"`
	Avatar   *string `json:"avatar"`
}

func (h *UserHandler) GetProfile(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "Unauthorized",
		})
	}

	u, err := h.userService.GetProfile(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusNotFound, ErrorResponse{
			Code:    "ERR_USER_NOT_FOUND",
			Message: "User not found",
		})
	}

	return c.JSON(http.StatusOK, toUserDTO(u))
}

func (h *UserHandler) UpdateProfile(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "Unauthorized",
		})
	}

	var req UpdateProfileRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "Invalid request format",
		})
	}

	// Validate nickname length before updating
	if req.Nickname != nil && len(*req.Nickname) > 20 {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_NICKNAME_TOO_LONG",
			Message: "Nickname cannot exceed 20 characters",
		})
	}

	updatedUser, err := h.userService.UpdateProfile(c.Request().Context(), userID, req.Nickname, req.Avatar)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_UPDATE_FAILED",
			Message: "Failed to update profile",
		})
	}

	return c.JSON(http.StatusOK, toUserDTO(updatedUser))
}

func (h *UserHandler) UploadAvatar(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "Unauthorized",
		})
	}

	file, err := c.FormFile("avatar")
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_FILE_REQUIRED",
			Message: "File 'avatar' is required",
		})
	}

	if err := validator.ValidateImageFile(file); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_FILE",
			Message: "Invalid file type or size",
		})
	}

	// Get current user to find old avatar for cleanup
	var oldAvatarKey string
	if h.userService != nil {
		currentUser, _ := h.userService.GetProfile(c.Request().Context(), userID)
		if currentUser != nil && currentUser.Avatar != "" && h.storageProvider != nil {
			oldAvatarKey = h.storageProvider.ExtractKeyFromUrl(currentUser.Avatar)
		}
	}

	src, err := file.Open()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_FILE_OPEN",
			Message: "Failed to read file",
		})
	}
	defer src.Close()

	key, err := h.storageProvider.Upload(c.Request().Context(), src, file.Filename)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPLOAD_FAILED",
			Message: "Failed to upload file",
		})
	}

	// Delete old avatar after successful upload (ignore errors)
	if oldAvatarKey != "" && h.storageProvider != nil {
		_ = h.storageProvider.Delete(c.Request().Context(), oldAvatarKey)
	}

	url := h.storageProvider.GetPublicUrl(key)

	return c.JSON(http.StatusOK, map[string]string{
		"url": url,
		"key": key,
	})
}
