package middleware

import (
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/internal/app/auth"
	pkgjwt "github.com/way2we/way2we_api/internal/pkg/jwt"
)

// ContextKeyUserID is the key for user ID in context.
const ContextKeyUserID = "user_id"

// JWTConfig holds configuration for JWT middleware.
type JWTConfig struct {
	AuthService *auth.Service
	Skipper     func(echo.Context) bool
}

// JWT returns a JWT authentication middleware.
func JWT(config JWTConfig) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Check if route should be skipped
			if config.Skipper != nil && config.Skipper(c) {
				return next(c)
			}

			// Extract token from Authorization header
			authHeader := c.Request().Header.Get("Authorization")
			if authHeader == "" {
				return echo.NewHTTPError(http.StatusUnauthorized, map[string]interface{}{
					"code":    "ERR_NO_TOKEN",
					"message": "未提供认证令牌",
				})
			}

			// Parse "Bearer <token>" format
			const prefix = "Bearer "
			if !strings.HasPrefix(authHeader, prefix) {
				return echo.NewHTTPError(http.StatusUnauthorized, map[string]interface{}{
					"code":    "ERR_INVALID_TOKEN_FORMAT",
					"message": "令牌格式无效",
				})
			}

			token := strings.TrimPrefix(authHeader, prefix)

			// Parse and validate token
			claims, err := pkgjwt.ParseToken(token, config.AuthService.GetJWTSecret())
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, map[string]interface{}{
					"code":    "ERR_INVALID_TOKEN",
					"message": "令牌无效或已过期",
				})
			}

			// Check if token is blacklisted
			blacklisted, err := config.AuthService.IsTokenBlacklisted(c.Request().Context(), token)
			if err != nil {
				return echo.NewHTTPError(http.StatusInternalServerError, map[string]interface{}{
					"code":    "ERR_INTERNAL",
					"message": "服务器内部错误",
				})
			}
			if blacklisted {
				return echo.NewHTTPError(http.StatusUnauthorized, map[string]interface{}{
					"code":    "ERR_TOKEN_REVOKED",
					"message": "令牌已失效，请重新登录",
				})
			}

			// Set user ID in context
			c.Set(ContextKeyUserID, claims.UserID)

			return next(c)
		}
	}
}

// AuthSkipper returns a skipper function that skips auth routes.
func AuthSkipper(c echo.Context) bool {
	path := c.Path()
	// Skip auth routes (login, register, verification code, logout)
	authPaths := []string{
		"/v1/auth/login",
		"/v1/auth/register",
		"/v1/auth/verification-code",
		"/v1/auth/logout",
	}
	for _, p := range authPaths {
		if path == p {
			return true
		}
	}
	return false
}
