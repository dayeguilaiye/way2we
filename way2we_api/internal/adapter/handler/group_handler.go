package handler

import (
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/app/group"
)

// GroupHandler handles group-related HTTP requests.
type GroupHandler struct {
	groupService *group.Service
}

// NewGroupHandler creates a new GroupHandler instance.
func NewGroupHandler(groupService *group.Service) *GroupHandler {
	return &GroupHandler{
		groupService: groupService,
	}
}

// CreateGroupRequest represents the request body for creating a group.
type CreateGroupRequest struct {
	Name string `json:"name"`
}

// GroupDTO represents group info returned in API responses.
type GroupDTO struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

// CreateGroupResponse represents the response for creating a group.
type CreateGroupResponse struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
	Role string `json:"role"`
}

// CreateGroup handles POST /v1/groups
func (h *GroupHandler) CreateGroup(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	var req CreateGroupRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	// Validate name length
	if req.Name == "" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_NAME_REQUIRED",
			Message: "群组名称不能为空",
		})
	}
	if len(req.Name) > 30 {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_NAME_TOO_LONG",
			Message: "群组名称不能超过30个字符",
		})
	}

	result, err := h.groupService.CreateGroup(c.Request().Context(), userID, req.Name)
	if err != nil {
		if errors.Is(err, group.ErrGroupNameEmpty) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_REQUIRED",
				Message: "群组名称不能为空",
			})
		}
		if errors.Is(err, group.ErrGroupNameTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_TOO_LONG",
				Message: "群组名称不能超过30个字符",
			})
		}
		if errors.Is(err, group.ErrUserNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_USER_NOT_FOUND",
				Message: "用户不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_CREATE_GROUP_FAILED",
			Message: "创建群组失败",
		})
	}

	return c.JSON(http.StatusOK, CreateGroupResponse{
		ID:   result.Group.ID,
		Name: result.Group.Name,
		Role: string(result.Member.Role),
	})
}

// toGroupDTO converts ent.Group to GroupDTO for API responses.
func toGroupDTO(g *ent.Group) *GroupDTO {
	if g == nil {
		return nil
	}
	return &GroupDTO{
		ID:          g.ID,
		Name:        g.Name,
		Description: g.Description,
		CreatedAt:   g.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:   g.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}
