package handler

import (
	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/internal/app/auth"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/pkg/config"
	"github.com/way2we/way2we_api/internal/pkg/middleware"
)

// RegisterRoutes registers all routes for the application.
func RegisterRoutes(e *echo.Echo, cfg *config.Config, authService *auth.Service, authHandler *AuthHandler, userHandler *UserHandler, groupHandler *GroupHandler, groupService *group.Service, agreementHandler *AgreementHandler, agreementCompletionHandler *AgreementCompletionHandler, rewardHandler *RewardHandler, redemptionHandler *RedemptionHandler, pointsHandler *PointsHandler) {
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
	uploadGroup.POST("/reward-cover", rewardHandler.UploadRewardCover)

	// Group Routes (Protected)
	groupRoutes := v1.Group("/groups")
	groupRoutes.Use(jwtMiddleware)
	groupRoutes.GET("", groupHandler.GetUserGroups)
	groupRoutes.POST("", groupHandler.CreateGroup)
	groupRoutes.GET("/:id/invitation", groupHandler.GetInvitation)
	groupRoutes.POST("/:id/invitation/refresh", groupHandler.RefreshInvitation)
	groupRoutes.POST("/join", groupHandler.JoinGroup)

	// Member Management Routes
	// Apply permission checks via middleware where appropriate for better architectural enforcement
	groupRoutes.GET("/:id/members", groupHandler.ListMembers) // Handler handles membership check
	groupRoutes.PUT("/:id/members/:userId/role", groupHandler.UpdateMemberRole, middleware.RequireGroupAdmin(groupService))
	groupRoutes.PUT("/:id/members/:userId/permissions", groupHandler.UpdateMemberPermissions, middleware.RequireGroupAdmin(groupService))

	// Group Settings Routes
	groupRoutes.GET("/:id/settings", groupHandler.GetGroupSettings, middleware.RequireGroupPermission(groupService, group.PermissionModifyDefaults))
	groupRoutes.PUT("/:id/settings", groupHandler.UpdateGroupSettings, middleware.RequireGroupPermission(groupService, group.PermissionModifyDefaults))

	// Agreement Routes (Protected - nested under groups)
	// Permission checks handled in service layer
	groupRoutes.GET("/:groupId/agreements", agreementHandler.ListAgreements)
	groupRoutes.POST("/:groupId/agreements", agreementHandler.CreateAgreement)
	groupRoutes.GET("/:groupId/agreements/:id", agreementHandler.GetAgreement)
	groupRoutes.PUT("/:groupId/agreements/:id", agreementHandler.UpdateAgreement)
	groupRoutes.PUT("/:groupId/agreements/:id/status", agreementHandler.UpdateAgreementStatus)
	groupRoutes.POST("/:groupId/agreements/:agreementId/pin", agreementHandler.PinAgreement)
	groupRoutes.DELETE("/:groupId/agreements/:agreementId/pin", agreementHandler.UnpinAgreement)
	groupRoutes.POST("/:groupId/agreements/:agreementId/completions", agreementCompletionHandler.CreateCompletion)
	groupRoutes.GET("/:groupId/agreement-completions", agreementCompletionHandler.ListCompletions)
	groupRoutes.POST("/:groupId/agreement-completions/:id/confirm", agreementCompletionHandler.ConfirmCompletion)
	groupRoutes.POST("/:groupId/agreement-completions/:id/reject", agreementCompletionHandler.RejectCompletion)

	// Reward Routes (Protected - nested under groups)
	// Permission checks handled in service layer
	groupRoutes.GET("/:groupId/rewards", rewardHandler.ListRewards)
	groupRoutes.POST("/:groupId/rewards", rewardHandler.CreateReward)
	groupRoutes.GET("/:groupId/rewards/:id", rewardHandler.GetReward)
	groupRoutes.PUT("/:groupId/rewards/:id", rewardHandler.UpdateReward)
	groupRoutes.PUT("/:groupId/rewards/:id/status", rewardHandler.UpdateRewardStatus)
	groupRoutes.POST("/:groupId/rewards/:id/pin", rewardHandler.PinReward)
	groupRoutes.DELETE("/:groupId/rewards/:id/pin", rewardHandler.UnpinReward)

	// Redemption Order Routes (Protected - nested under groups)
	groupRoutes.POST("/:groupId/rewards/:rewardId/redemptions", redemptionHandler.CreateRedemption)
	groupRoutes.GET("/:groupId/orders", redemptionHandler.ListOrders)
	groupRoutes.GET("/:groupId/orders/:id", redemptionHandler.GetOrder)
	groupRoutes.POST("/:groupId/orders/:id/fulfill", redemptionHandler.FulfillOrder)
	groupRoutes.POST("/:groupId/orders/:id/confirm", redemptionHandler.ConfirmOrder)
	groupRoutes.POST("/:groupId/orders/:id/unsatisfied", redemptionHandler.MarkUnsatisfied)

	// Points Routes (Protected - nested under groups)
	groupRoutes.GET("/:groupId/points/me", pointsHandler.GetMyPoints)
	groupRoutes.GET("/:groupId/points/logs", pointsHandler.ListPointLogs)

	// Group Routes (Public - for invitation preview)
	v1.GET("/groups/by-invitation/:code", groupHandler.GetGroupByInvitation)

	// Static Files
	// Serve uploads directory under /uploads path
	e.Static("/uploads", "uploads")
}
