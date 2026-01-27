package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/adapter/storage"
	"github.com/way2we/way2we_api/internal/app/reward"
	"github.com/way2we/way2we_api/internal/pkg/validator"
)

// RewardHandler handles reward-related HTTP requests.
type RewardHandler struct {
	rewardService   *reward.Service
	storageProvider storage.Provider
}

// NewRewardHandler creates a new RewardHandler instance.
func NewRewardHandler(rewardService *reward.Service, storageProvider storage.Provider) *RewardHandler {
	return &RewardHandler{
		rewardService:   rewardService,
		storageProvider: storageProvider,
	}
}

// RewardDTO represents reward info in API responses.
type RewardDTO struct {
	ID               int    `json:"id"`
	Name             string `json:"name"`
	Description      string `json:"description,omitempty"`
	CostPoints       int    `json:"cost_points"`
	CoverImageURL    string `json:"cover_image_url,omitempty"`
	Status           string `json:"status"`
	AutoFulfill      bool   `json:"auto_fulfill"`
	AutoComplete     bool   `json:"auto_complete"`
	GroupID          int    `json:"group_id"`
	ProviderID       int    `json:"provider_id"`
	ProviderNickname string `json:"provider_nickname,omitempty"`
	CreatedAt        string `json:"created_at"`
	UpdatedAt        string `json:"updated_at"`
}

// toRewardDTO converts ent.Reward to RewardDTO.
func toRewardDTO(r *ent.Reward) *RewardDTO {
	if r == nil {
		return nil
	}

	coverImageURL := ""
	if r.CoverImageURL != nil {
		coverImageURL = *r.CoverImageURL
	}

	providerNickname := ""
	if r.Edges.Provider != nil {
		providerNickname = r.Edges.Provider.Nickname
	}

	return &RewardDTO{
		ID:               r.ID,
		Name:             r.Name,
		Description:      r.Description,
		CostPoints:       r.CostPoints,
		CoverImageURL:    coverImageURL,
		Status:           string(r.Status),
		AutoFulfill:      r.AutoFulfill,
		AutoComplete:     r.AutoComplete,
		GroupID:          r.GroupID,
		ProviderID:       r.ProviderID,
		ProviderNickname: providerNickname,
		CreatedAt:        r.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:        r.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

// ListRewardsResponse represents the response for listing rewards.
type ListRewardsResponse struct {
	Rewards []*RewardDTO `json:"rewards"`
}

// ListRewards handles GET /v1/groups/:groupId/rewards
func (h *RewardHandler) ListRewards(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("groupId")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	// Optional status filter
	statusFilter := c.QueryParam("status")

	rewards, err := h.rewardService.ListRewards(c.Request().Context(), groupID, userID, statusFilter)
	if err != nil {
		if errors.Is(err, reward.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, reward.ErrInvalidStatus) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_STATUS",
				Message: "无效的状态筛选值",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_LIST_REWARDS_FAILED",
			Message: "获取商品列表失败",
		})
	}

	resp := ListRewardsResponse{
		Rewards: make([]*RewardDTO, 0, len(rewards)),
	}
	for _, r := range rewards {
		resp.Rewards = append(resp.Rewards, toRewardDTO(r))
	}

	return c.JSON(http.StatusOK, resp)
}

// CreateRewardRequest represents the request body for creating a reward.
type CreateRewardRequest struct {
	Name          string `json:"name"`
	Description   string `json:"description"`
	CostPoints    int    `json:"cost_points"`
	AutoFulfill   *bool  `json:"auto_fulfill"`
	AutoComplete  *bool  `json:"auto_complete"`
	CoverImageURL string `json:"cover_image_url"`
}

// CreateReward handles POST /v1/groups/:groupId/rewards
func (h *RewardHandler) CreateReward(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("groupId")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	var req CreateRewardRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	input := reward.CreateInput{
		Name:          req.Name,
		Description:   req.Description,
		CostPoints:    req.CostPoints,
		AutoFulfill:   req.AutoFulfill,
		AutoComplete:  req.AutoComplete,
		CoverImageURL: req.CoverImageURL,
	}

	r, err := h.rewardService.CreateReward(c.Request().Context(), groupID, userID, input)
	if err != nil {
		if errors.Is(err, reward.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, reward.ErrRewardNameEmpty) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_REQUIRED",
				Message: "商品名称不能为空",
			})
		}
		if errors.Is(err, reward.ErrRewardNameTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_TOO_LONG",
				Message: "商品名称不能超过50个字符",
			})
		}
		if errors.Is(err, reward.ErrDescriptionTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_DESCRIPTION_TOO_LONG",
				Message: "描述不能超过200个字符",
			})
		}
		if errors.Is(err, reward.ErrInvalidCostPoints) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_COST_POINTS",
				Message: "积分必须在1到99999之间",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_CREATE_REWARD_FAILED",
			Message: "创建商品失败",
		})
	}

	return c.JSON(http.StatusOK, toRewardDTO(r))
}

// GetReward handles GET /v1/groups/:groupId/rewards/:id
func (h *RewardHandler) GetReward(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("groupId")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	rewardIDStr := c.Param("id")
	rewardID, err := strconv.Atoi(rewardIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REWARD_ID",
			Message: "无效的商品ID",
		})
	}

	r, err := h.rewardService.GetReward(c.Request().Context(), groupID, rewardID, userID)
	if err != nil {
		if errors.Is(err, reward.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, reward.ErrRewardNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_FOUND",
				Message: "商品不存在",
			})
		}
		if errors.Is(err, reward.ErrRewardNotInGroup) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_IN_GROUP",
				Message: "商品不属于该群组",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_REWARD_FAILED",
			Message: "获取商品失败",
		})
	}

	return c.JSON(http.StatusOK, toRewardDTO(r))
}

// UpdateRewardRequest represents the request body for updating a reward.
type UpdateRewardRequest struct {
	Name          *string `json:"name"`
	Description   *string `json:"description"`
	CostPoints    *int    `json:"cost_points"`
	AutoFulfill   *bool   `json:"auto_fulfill"`
	AutoComplete  *bool   `json:"auto_complete"`
	CoverImageURL *string `json:"cover_image_url"`
}

// UpdateReward handles PUT /v1/groups/:groupId/rewards/:id
func (h *RewardHandler) UpdateReward(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("groupId")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	rewardIDStr := c.Param("id")
	rewardID, err := strconv.Atoi(rewardIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REWARD_ID",
			Message: "无效的商品ID",
		})
	}

	var req UpdateRewardRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	input := reward.UpdateInput{
		Name:          req.Name,
		Description:   req.Description,
		CostPoints:    req.CostPoints,
		AutoFulfill:   req.AutoFulfill,
		AutoComplete:  req.AutoComplete,
		CoverImageURL: req.CoverImageURL,
	}

	r, err := h.rewardService.UpdateReward(c.Request().Context(), groupID, rewardID, userID, input)
	if err != nil {
		if errors.Is(err, reward.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, reward.ErrPermissionDenied) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_PERMISSION_DENIED",
				Message: "您没有权限编辑商品",
			})
		}
		if errors.Is(err, reward.ErrRewardNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_FOUND",
				Message: "商品不存在",
			})
		}
		if errors.Is(err, reward.ErrRewardNotInGroup) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_IN_GROUP",
				Message: "商品不属于该群组",
			})
		}
		if errors.Is(err, reward.ErrRewardNameEmpty) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_REQUIRED",
				Message: "商品名称不能为空",
			})
		}
		if errors.Is(err, reward.ErrRewardNameTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_TOO_LONG",
				Message: "商品名称不能超过50个字符",
			})
		}
		if errors.Is(err, reward.ErrDescriptionTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_DESCRIPTION_TOO_LONG",
				Message: "描述不能超过200个字符",
			})
		}
		if errors.Is(err, reward.ErrInvalidCostPoints) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_COST_POINTS",
				Message: "积分必须在1到99999之间",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_REWARD_FAILED",
			Message: "更新商品失败",
		})
	}

	return c.JSON(http.StatusOK, toRewardDTO(r))
}

// UpdateRewardStatusRequest represents the request body for updating reward status.
type UpdateRewardStatusRequest struct {
	Status string `json:"status"`
}

// UpdateRewardStatus handles PUT /v1/groups/:groupId/rewards/:id/status
func (h *RewardHandler) UpdateRewardStatus(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupIDStr := c.Param("groupId")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	rewardIDStr := c.Param("id")
	rewardID, err := strconv.Atoi(rewardIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REWARD_ID",
			Message: "无效的商品ID",
		})
	}

	var req UpdateRewardStatusRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	r, err := h.rewardService.UpdateRewardStatus(c.Request().Context(), groupID, rewardID, userID, req.Status)
	if err != nil {
		if errors.Is(err, reward.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, reward.ErrPermissionDenied) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_PERMISSION_DENIED",
				Message: "您没有权限更新商品状态",
			})
		}
		if errors.Is(err, reward.ErrRewardNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_FOUND",
				Message: "商品不存在",
			})
		}
		if errors.Is(err, reward.ErrRewardNotInGroup) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_IN_GROUP",
				Message: "商品不属于该群组",
			})
		}
		if errors.Is(err, reward.ErrInvalidStatus) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_STATUS",
				Message: "无效的状态值",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_REWARD_STATUS_FAILED",
			Message: "更新商品状态失败",
		})
	}

	return c.JSON(http.StatusOK, toRewardDTO(r))
}

// UploadRewardCover handles POST /v1/uploads/reward-cover
func (h *RewardHandler) UploadRewardCover(c echo.Context) error {
	_, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "Unauthorized",
		})
	}

	file, err := c.FormFile("cover")
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_FILE_REQUIRED",
			Message: "File 'cover' is required",
		})
	}

	if err := validator.ValidateImageFile(file); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_FILE",
			Message: "Invalid file type or size",
		})
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

	url := h.storageProvider.GetPublicUrl(key)

	return c.JSON(http.StatusOK, map[string]string{
		"url": url,
		"key": key,
	})
}
