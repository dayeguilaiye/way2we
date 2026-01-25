package handler

import (
	"errors"
	"log/slog"
	"net/http"
	"regexp"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/app/auth"
)

// AuthHandler handles authentication-related HTTP requests.
type AuthHandler struct {
	authService *auth.Service
}

// NewAuthHandler creates a new AuthHandler instance.
func NewAuthHandler(authService *auth.Service) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// SendVerificationCodeRequest represents the request body for sending verification code.
type SendVerificationCodeRequest struct {
	Type   string `json:"type"`   // "phone" or "email"
	Target string `json:"target"` // phone number or email address
}

type SendVerificationCodeResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// RegisterRequest represents the request body for registration.
type RegisterRequest struct {
	Type     string `json:"type"`     // "phone" or "email"
	Target   string `json:"target"`   // phone number or email address
	Code     string `json:"code"`     // verification code
	Password string `json:"password"` // password
}

// UserDTO represents user info returned in auth responses.
// Note: password_hash is never exposed in API responses.
type UserDTO struct {
	ID        int    `json:"id"`
	Nickname  string `json:"nickname,omitempty"`
	Avatar    string `json:"avatar,omitempty"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type RegisterResponse struct {
	Success bool     `json:"success"`
	Message string   `json:"message"`
	Token   string   `json:"token,omitempty"`
	User    *UserDTO `json:"user,omitempty"`
}

// LoginRequest represents the request body for login.
type LoginRequest struct {
	Type       string `json:"type"`       // "phone" or "email"
	Target     string `json:"target"`     // phone number or email address
	Mode       string `json:"mode"`       // "password" or "code"
	Credential string `json:"credential"` // password or verification code content
}

type LoginResponse struct {
	Success bool     `json:"success"`
	Message string   `json:"message"`
	Token   string   `json:"token,omitempty"`
	User    *UserDTO `json:"user,omitempty"`
}

// ErrorResponse represents an error response.
type ErrorResponse struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// LogoutResponse represents the response for logout.
type LogoutResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// Regular expressions for validation
var (
	phoneRegex = regexp.MustCompile(`^1[3-9]\d{9}$`)              // Chinese phone format
	emailRegex = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]+$`) // Simple email format
)

// RegisterRoutes registers auth-related routes to the Echo instance.
func (h *AuthHandler) RegisterRoutes(e *echo.Echo) {
	v1 := e.Group("/v1")
	v1Auth := v1.Group("/auth")

	v1Auth.POST("/verification-code", h.SendVerificationCode)
	v1Auth.POST("/register", h.Register)
	v1Auth.POST("/login", h.Login)
	v1Auth.POST("/logout", h.Logout)
}

// SendVerificationCode handles POST /v1/auth/verification-code
func (h *AuthHandler) SendVerificationCode(c echo.Context) error {
	var req SendVerificationCodeRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	verifyType, err := h.validateType(req.Type)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TYPE",
			Message: "验证类型无效，请使用 'phone' 或 'email'",
		})
	}

	if err := h.validateTarget(verifyType, req.Target); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TARGET",
			Message: err.Error(),
		})
	}

	if err := h.authService.SendVerificationCode(c.Request().Context(), verifyType, req.Target); err != nil {
		slog.Error("failed to send verification code", "error", err)
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_SEND_FAILED",
			Message: "验证码发送失败，请稍后重试",
		})
	}

	return c.JSON(http.StatusOK, SendVerificationCodeResponse{
		Success: true,
		Message: "验证码已发送",
	})
}

// Register handles POST /v1/auth/register
func (h *AuthHandler) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	verifyType, err := h.validateType(req.Type)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TYPE",
			Message: "验证类型无效",
		})
	}

	if err := h.validateTarget(verifyType, req.Target); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TARGET",
			Message: err.Error(),
		})
	}

	if req.Code == "" || req.Password == "" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_MISSING_FIELD",
			Message: "验证码和密码不能为空",
		})
	}

	authResult, err := h.authService.Register(c.Request().Context(), verifyType, req.Target, req.Code, req.Password)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_REGISTER_FAILED",
			Message: err.Error(),
		})
	}

	return c.JSON(http.StatusOK, RegisterResponse{
		Success: true,
		Message: "注册成功",
		Token:   authResult.Token,
		User:    toUserDTO(authResult.User),
	})
}

// Login handles POST /v1/auth/login
func (h *AuthHandler) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	verifyType, err := h.validateType(req.Type)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TYPE",
			Message: "验证类型无效",
		})
	}

	if err := h.validateTarget(verifyType, req.Target); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TARGET",
			Message: err.Error(),
		})
	}

	var authResult *auth.AuthResult
	// var loginErr error

	if req.Mode == "password" {
		authResult, err = h.authService.LoginByPassword(c.Request().Context(), verifyType, req.Target, req.Credential)
	} else if req.Mode == "code" {
		authResult, err = h.authService.LoginByCode(c.Request().Context(), verifyType, req.Target, req.Credential)
	} else {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_MODE",
			Message: "登录模式无效",
		})
	}

	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_LOGIN_FAILED",
			Message: err.Error(),
		})
	}

	return c.JSON(http.StatusOK, LoginResponse{
		Success: true,
		Message: "登录成功",
		Token:   authResult.Token,
		User:    toUserDTO(authResult.User),
	})
}

// validateType validates and converts the type string to VerificationType.
func (h *AuthHandler) validateType(t string) (auth.VerificationType, error) {
	switch t {
	case "phone":
		return auth.VerificationTypePhone, nil
	case "email":
		return auth.VerificationTypeEmail, nil
	default:
		return "", echo.NewHTTPError(http.StatusBadRequest, "invalid verification type")
	}
}

// toUserDTO converts ent.User to UserDTO for API responses.
func toUserDTO(u *ent.User) *UserDTO {
	if u == nil {
		return nil
	}
	return &UserDTO{
		ID:        u.ID,
		Nickname:  u.Nickname,
		Avatar:    u.Avatar,
		CreatedAt: u.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt: u.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

// validateTarget validates the target based on the verification type.
func (h *AuthHandler) validateTarget(verifyType auth.VerificationType, target string) error {
	if target == "" {
		return errors.New("target is required")
	}

	switch verifyType {
	case auth.VerificationTypePhone:
		if !phoneRegex.MatchString(target) {
			return errors.New("手机号码格式无效")
		}
	case auth.VerificationTypeEmail:
		if !emailRegex.MatchString(target) {
			return errors.New("邮箱格式无效")
		}
	}

	return nil
}

// Logout handles POST /v1/auth/logout
func (h *AuthHandler) Logout(c echo.Context) error {
	// Extract token from Authorization header
	authHeader := c.Request().Header.Get("Authorization")
	if authHeader == "" {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_NO_TOKEN",
			Message: "未提供认证令牌",
		})
	}

	// Parse "Bearer <token>" format
	const prefix = "Bearer "
	if len(authHeader) < len(prefix) || authHeader[:len(prefix)] != prefix {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_INVALID_TOKEN_FORMAT",
			Message: "令牌格式无效",
		})
	}

	token := authHeader[len(prefix):]

	// Call service to blacklist token
	if err := h.authService.Logout(c.Request().Context(), token); err != nil {
		slog.Error("failed to logout", "error", err)
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_LOGOUT_FAILED",
			Message: "登出失败，请稍后重试",
		})
	}

	return c.JSON(http.StatusOK, LogoutResponse{
		Success: true,
		Message: "登出成功",
	})
}
