package middleware

import (
	"context"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
)

// PermissionChecker defines the interface for checking permissions
type PermissionChecker interface {
	IsGroupAdmin(ctx context.Context, groupID int, userID int) (bool, error)
	HasPermission(ctx context.Context, groupID int, userID int, permission string) (bool, error)
}

// RequireGroupAdmin enforces that the user is an admin of the group specified in path param :id
func RequireGroupAdmin(checker PermissionChecker) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			userID, ok := c.Get("user_id").(int)
			if !ok {
				// Should be caught by JWT middleware, but double check
				return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
			}

			groupIDStr := c.Param("id")
			groupID, err := strconv.Atoi(groupIDStr)
			if err != nil {
				return echo.NewHTTPError(http.StatusBadRequest, "Invalid group ID")
			}

			isAdmin, err := checker.IsGroupAdmin(c.Request().Context(), groupID, userID)
			if err != nil {
				// Don't leak internal errors, but log them? For now just 500
				return echo.NewHTTPError(http.StatusInternalServerError, "Permission check failed")
			}

			if !isAdmin {
				return echo.NewHTTPError(http.StatusForbidden, "Requires group admin privileges")
			}

			return next(c)
		}
	}
}

// RequireGroupPermission enforces that the user has a specific permission in the group
func RequireGroupPermission(checker PermissionChecker, permission string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			userID, ok := c.Get("user_id").(int)
			if !ok {
				return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
			}

			groupIDStr := c.Param("id")
			groupID, err := strconv.Atoi(groupIDStr)
			if err != nil {
				return echo.NewHTTPError(http.StatusBadRequest, "Invalid group ID")
			}

			hasPerm, err := checker.HasPermission(c.Request().Context(), groupID, userID, permission)
			if err != nil {
				return echo.NewHTTPError(http.StatusInternalServerError, "Permission check failed")
			}

			if !hasPerm {
				return echo.NewHTTPError(http.StatusForbidden, "Missing required permission: "+permission)
			}

			return next(c)
		}
	}
}
