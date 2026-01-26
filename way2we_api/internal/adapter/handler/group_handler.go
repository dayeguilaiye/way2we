package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/groupmember"
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
	ID          int      `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	MemberCount int      `json:"member_count"`
	Role        string   `json:"role"`
	JoinedAt    string   `json:"joined_at"`
	CreatedAt   string   `json:"created_at"`
	Permissions []string `json:"permissions"`
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
		permissions := g.Permissions
		if permissions == nil {
			permissions = []string{}
		}
		resp.Groups = append(resp.Groups, UserGroupDTO{
			ID:          g.Group.ID,
			Name:        g.Group.Name,
			Description: g.Group.Description,
			MemberCount: g.MemberCount,
			Role:        string(g.Role),
			JoinedAt:    g.JoinedAt,
			CreatedAt:   g.Group.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			Permissions: permissions,
		})
	}

	return c.JSON(http.StatusOK, resp)
}

// MemberDTO represents member info in API response.
type MemberDTO struct {
	ID          int      `json:"id"`
	UserID      int      `json:"user_id"`
	Nickname    string   `json:"nickname"`
	AvatarURL   string   `json:"avatar_url"`
	Role        string   `json:"role"`
	Permissions []string `json:"permissions"`
	JoinedAt    string   `json:"joined_at"`
}

// ListMembersResponse represents the response for listing members.
type ListMembersResponse struct {
	Members []MemberDTO `json:"members"`
}

// ListMembers handles GET /v1/groups/:id/members
func (h *GroupHandler) ListMembers(c echo.Context) error {
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

	members, err := h.groupService.ListMembers(c.Request().Context(), groupID, userID)
	if err != nil {
		if errors.Is(err, group.ErrNotAdmin) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_FORBIDDEN",
				Message: "您无权查看该群组的成员列表",
			})
		}
		if errors.Is(err, group.ErrGroupNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_GROUP_NOT_FOUND",
				Message: "群组不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_LIST_MEMBERS_FAILED",
			Message: "获取成员列表失败",
		})
	}

	resp := ListMembersResponse{
		Members: make([]MemberDTO, 0, len(members)),
	}
	for _, m := range members {
		resp.Members = append(resp.Members, MemberDTO{
			ID:          m.ID,
			UserID:      m.UserID,
			Nickname:    m.Nickname,
			AvatarURL:   m.AvatarURL,
			Role:        string(m.Role),
			Permissions: m.Permissions,
			JoinedAt:    m.JoinedAt,
		})
	}

	return c.JSON(http.StatusOK, resp)
}

// UpdateMemberRoleRequest represents request to update member role.
type UpdateMemberRoleRequest struct {
	Role string `json:"role"`
}

// UpdateMemberRole handles PUT /v1/groups/:id/members/:userId/role
func (h *GroupHandler) UpdateMemberRole(c echo.Context) error {
	actorID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, _ := strconv.Atoi(c.Param("id"))
	targetUserID, _ := strconv.Atoi(c.Param("userId"))

	var req UpdateMemberRoleRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	err := h.groupService.UpdateMemberRole(c.Request().Context(), groupID, targetUserID, groupmember.Role(req.Role), actorID)
	if err != nil {
		if errors.Is(err, group.ErrNotAdmin) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ADMIN",
				Message: "仅管理员可修改成员角色",
			})
		}
		if errors.Is(err, group.ErrLastAdminCannotDemote) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_LAST_ADMIN",
				Message: "群组必须至少保留一名管理员",
			})
		}
		if errors.Is(err, group.ErrMemberNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_MEMBER_NOT_FOUND",
				Message: "成员不在群组中",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_ROLE_FAILED",
			Message: "更新角色失败",
		})
	}

	return c.NoContent(http.StatusOK)
}

// UpdateMemberPermissionsRequest represents request to update member permissions.
type UpdateMemberPermissionsRequest struct {
	Permissions []string `json:"permissions"`
}

// UpdateMemberPermissions handles PUT /v1/groups/:id/members/:userId/permissions
func (h *GroupHandler) UpdateMemberPermissions(c echo.Context) error {
	actorID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, _ := strconv.Atoi(c.Param("id"))
	targetUserID, _ := strconv.Atoi(c.Param("userId"))

	var req UpdateMemberPermissionsRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	err := h.groupService.UpdateMemberPermissions(c.Request().Context(), groupID, targetUserID, req.Permissions, actorID)
	if err != nil {
		if errors.Is(err, group.ErrNotAdmin) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ADMIN",
				Message: "仅管理员可分配权限",
			})
		}
		if errors.Is(err, group.ErrPermissionInvalid) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_PERMISSION",
				Message: "包含无效的权限项",
			})
		}
		if errors.Is(err, group.ErrMemberNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_MEMBER_NOT_FOUND",
				Message: "成员不在群组中",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_PERMISSIONS_FAILED",
			Message: "更新权限失败",
		})
	}

	return c.NoContent(http.StatusOK)
}

// GroupSettingsResponse represents the response for group settings.
type GroupSettingsResponse struct {
	RequireConfirmationDefault    bool `json:"require_confirmation_default"`
	AutoCompleteRedemptionDefault bool `json:"auto_complete_redemption_default"`
	AutoFulfillRedemptionDefault  bool `json:"auto_fulfill_redemption_default"`
	ProviderIncentiveRatio        int  `json:"provider_incentive_ratio"`
}

// GetGroupSettings handles GET /v1/groups/:id/settings
func (h *GroupHandler) GetGroupSettings(c echo.Context) error {
	_, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	g, err := h.groupService.GetGroup(c.Request().Context(), groupID)
	if err != nil {
		if errors.Is(err, group.ErrGroupNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_GROUP_NOT_FOUND",
				Message: "群组不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_SETTINGS_FAILED",
			Message: "获取配置失败",
		})
	}

	return c.JSON(http.StatusOK, GroupSettingsResponse{
		RequireConfirmationDefault:    g.RequireConfirmationDefault,
		AutoCompleteRedemptionDefault: g.AutoCompleteRedemptionDefault,
		AutoFulfillRedemptionDefault:  g.AutoFulfillRedemptionDefault,
		ProviderIncentiveRatio:        g.ProviderIncentiveRatio,
	})
}

// UpdateGroupSettingsRequest represents request to update group settings.
type UpdateGroupSettingsRequest struct {
	RequireConfirmationDefault    bool `json:"require_confirmation_default"`
	AutoCompleteRedemptionDefault bool `json:"auto_complete_redemption_default"`
	AutoFulfillRedemptionDefault  bool `json:"auto_fulfill_redemption_default"`
	ProviderIncentiveRatio        int  `json:"provider_incentive_ratio"`
}

// UpdateGroupSettings handles PUT /v1/groups/:id/settings
func (h *GroupHandler) UpdateGroupSettings(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	var req UpdateGroupSettingsRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	updates := group.SettingsUpdate{
		RequireConfirmationDefault:    req.RequireConfirmationDefault,
		AutoCompleteRedemptionDefault: req.AutoCompleteRedemptionDefault,
		AutoFulfillRedemptionDefault:  req.AutoFulfillRedemptionDefault,
		ProviderIncentiveRatio:        req.ProviderIncentiveRatio,
	}

	updated, err := h.groupService.UpdateGroupSettings(c.Request().Context(), userID, groupID, updates)
	if err != nil {
		if errors.Is(err, group.ErrNotAdmin) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_FORBIDDEN",
				Message: "您无权修改群组配置",
			})
		}
		if errors.Is(err, group.ErrInvalidIncentiveRatio) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_INCENTIVE_RATIO",
				Message: "提供者激励比例必须在 0-100 之间",
			})
		}
		if errors.Is(err, group.ErrGroupNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_GROUP_NOT_FOUND",
				Message: "群组不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_SETTINGS_FAILED",
			Message: "更新配置失败",
		})
	}

	return c.JSON(http.StatusOK, GroupSettingsResponse{
		RequireConfirmationDefault:    updated.RequireConfirmationDefault,
		AutoCompleteRedemptionDefault: updated.AutoCompleteRedemptionDefault,
		AutoFulfillRedemptionDefault:  updated.AutoFulfillRedemptionDefault,
		ProviderIncentiveRatio:        updated.ProviderIncentiveRatio,
	})
}
