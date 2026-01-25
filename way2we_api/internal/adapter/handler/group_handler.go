package handler

import (
	"errors"
	"net/http"
	"strconv"

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

// InvitationResponse represents the response for invitation code endpoints.
type InvitationResponse struct {
	GroupID        int    `json:"group_id"`
	InvitationCode string `json:"invitation_code"`
	ShareURL       string `json:"share_url"`
}

// GetInvitation handles GET /v1/groups/:id/invitation
func (h *GroupHandler) GetInvitation(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("id")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	code, err := h.groupService.GetInvitationCode(c.Request().Context(), groupID, userID)
	if err != nil {
		if errors.Is(err, group.ErrNotAdmin) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ADMIN",
				Message: "您不是该群组的管理员",
			})
		}
		if errors.Is(err, group.ErrGroupNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_GROUP_NOT_FOUND",
				Message: "群组不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_INVITATION_FAILED",
			Message: "获取邀请码失败",
		})
	}

	return c.JSON(http.StatusOK, InvitationResponse{
		GroupID:        groupID,
		InvitationCode: code,
		ShareURL:       "https://way2we.app/join/" + code,
	})
}

// RefreshInvitation handles POST /v1/groups/:id/invitation/refresh
func (h *GroupHandler) RefreshInvitation(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("id")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	code, err := h.groupService.RefreshInvitationCode(c.Request().Context(), groupID, userID)
	if err != nil {
		if errors.Is(err, group.ErrNotAdmin) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ADMIN",
				Message: "您不是该群组的管理员",
			})
		}
		if errors.Is(err, group.ErrGroupNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_GROUP_NOT_FOUND",
				Message: "群组不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_REFRESH_INVITATION_FAILED",
			Message: "刷新邀请码失败",
		})
	}

	return c.JSON(http.StatusOK, InvitationResponse{
		GroupID:        groupID,
		InvitationCode: code,
		ShareURL:       "https://way2we.app/join/" + code,
	})
}

// GroupPreviewResponse represents the response for group preview.
type GroupPreviewResponse struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	MemberCount int    `json:"member_count"`
	CreatedAt   string `json:"created_at"`
}

// GetGroupByInvitation handles GET /v1/groups/by-invitation/:code
func (h *GroupHandler) GetGroupByInvitation(c echo.Context) error {
	code := c.Param("code")
	if code == "" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVITATION_CODE_REQUIRED",
			Message: "邀请码不能为空",
		})
	}

	preview, err := h.groupService.GetGroupByInvitation(c.Request().Context(), code)
	if err != nil {
		if errors.Is(err, group.ErrInvitationCodeNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_INVITATION_CODE_INVALID",
				Message: "邀请码无效或已过期",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_GROUP_FAILED",
			Message: "获取群组信息失败",
		})
	}

	return c.JSON(http.StatusOK, GroupPreviewResponse{
		ID:          preview.ID,
		Name:        preview.Name,
		MemberCount: preview.MemberCount,
		CreatedAt:   preview.CreatedAt,
	})
}

// JoinGroupRequest represents the request body for joining a group.
type JoinGroupRequest struct {
	InvitationCode string `json:"invitation_code"`
}

// JoinGroupResponse represents the response for joining a group.
type JoinGroupResponse struct {
	Group struct {
		ID          int    `json:"id"`
		Name        string `json:"name"`
		MemberCount int    `json:"member_count"`
		Role        string `json:"role"`
	} `json:"group"`
}

// JoinGroup handles POST /v1/groups/join
func (h *GroupHandler) JoinGroup(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	var req JoinGroupRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	if req.InvitationCode == "" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVITATION_CODE_REQUIRED",
			Message: "邀请码不能为空",
		})
	}

	result, err := h.groupService.JoinGroup(c.Request().Context(), req.InvitationCode, userID)
	if err != nil {
		if errors.Is(err, group.ErrInvitationCodeNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_INVITATION_CODE_INVALID",
				Message: "邀请码无效或已过期",
			})
		}
		if errors.Is(err, group.ErrAlreadyMember) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_ALREADY_MEMBER",
				Message: "您已经是该群组成员",
			})
		}
		if errors.Is(err, group.ErrUserNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_USER_NOT_FOUND",
				Message: "用户不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_JOIN_GROUP_FAILED",
			Message: "加入群组失败",
		})
	}

	resp := JoinGroupResponse{}
	resp.Group.ID = result.Group.ID
	resp.Group.Name = result.Group.Name
	resp.Group.MemberCount = result.MemberCount
	resp.Group.Role = string(result.Member.Role)

	return c.JSON(http.StatusOK, resp)
}

// UserGroupDTO represents a group with user's membership info.
type UserGroupDTO struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	MemberCount int    `json:"member_count"`
	Role        string `json:"role"`
	JoinedAt    string `json:"joined_at"`
	CreatedAt   string `json:"created_at"`
}

// GetUserGroupsResponse represents the response for getting user's groups.
type GetUserGroupsResponse struct {
	Groups []UserGroupDTO `json:"groups"`
}

// GetUserGroups handles GET /v1/groups
func (h *GroupHandler) GetUserGroups(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groups, err := h.groupService.GetUserGroups(c.Request().Context(), userID)
	if err != nil {
		if errors.Is(err, group.ErrUserNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_USER_NOT_FOUND",
				Message: "用户不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_GROUPS_FAILED",
			Message: "获取群组列表失败",
		})
	}

	resp := GetUserGroupsResponse{
		Groups: make([]UserGroupDTO, 0, len(groups)),
	}
	for _, g := range groups {
		resp.Groups = append(resp.Groups, UserGroupDTO{
			ID:          g.Group.ID,
			Name:        g.Group.Name,
			Description: g.Group.Description,
			MemberCount: g.MemberCount,
			Role:        string(g.Role),
			JoinedAt:    g.JoinedAt,
			CreatedAt:   g.Group.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	return c.JSON(http.StatusOK, resp)
}
