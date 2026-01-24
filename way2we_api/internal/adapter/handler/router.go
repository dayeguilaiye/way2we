package handler

import (
	"github.com/golang-jwt/jwt/v5"
	echojwt "github.com/labstack/echo-jwt/v4"
	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/internal/pkg/config"
	pkgjwt "github.com/way2we/way2we_api/internal/pkg/jwt"
)

// RegisterRoutes registers all routes for the application.
func RegisterRoutes(e *echo.Echo, cfg *config.Config, authHandler *AuthHandler, userHandler *UserHandler) {
	v1 := e.Group("/v1")

	// Auth Routes (Public)
	authGroup := v1.Group("/auth")
	authGroup.POST("/verification-code", authHandler.SendVerificationCode)
	authGroup.POST("/register", authHandler.Register)
	authGroup.POST("/login", authHandler.Login)

	// Auth Middleware
	jwtMiddleware := echojwt.WithConfig(echojwt.Config{
		SigningKey: []byte(cfg.JWT.Secret),
		NewClaimsFunc: func(c echo.Context) jwt.Claims {
			return new(pkgjwt.Claims)
		},
		SuccessHandler: func(c echo.Context) {
			token := c.Get("user").(*jwt.Token)
			claims := token.Claims.(*pkgjwt.Claims)
			c.Set("user_id", claims.UserID)
		},
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
