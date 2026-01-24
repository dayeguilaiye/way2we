package handler

import (
	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/internal/app/auth"
	"github.com/way2we/way2we_api/internal/pkg/config"
	"github.com/way2we/way2we_api/internal/pkg/middleware"
)

// RegisterRoutes registers all routes for the application.
func RegisterRoutes(e *echo.Echo, cfg *config.Config, authService *auth.Service, authHandler *AuthHandler, userHandler *UserHandler) {
	v1 := e.Group("/v1")

	// Auth Routes (Public)
	authGroup := v1.Group("/auth")
	authGroup.POST("/verification-code", authHandler.SendVerificationCode)
	authGroup.POST("/register", authHandler.Register)
	authGroup.POST("/login", authHandler.Login)
	authGroup.POST("/logout", authHandler.Logout)

	// Auth Middleware with blacklist support
	jwtMiddleware := middleware.JWT(middleware.JWTConfig{
		AuthService: authService,
	})

	// User Routes (Protected)
	userGroup := v1.Group("/users")
	userGroup.Use(jwtMiddleware)
	userGroup.GET("/me", userHandler.GetProfile)
	userGroup.PUT("/me", userHandler.UpdateProfile)

	// Upload Routes (Protected)
	uploadGroup := v1.Group("/uploads")
	uploadGroup.Use(jwtMiddleware)
	uploadGroup.POST("/avatar", userHandler.UploadAvatar)

	// Static Files
	// Serve uploads directory under /uploads path
	e.Static("/uploads", "uploads")
}
