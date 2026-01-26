package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/app/agreement"
)

// AgreementHandler handles agreement-related HTTP requests.
type AgreementHandler struct {
	agreementService *agreement.Service
}

// NewAgreementHandler creates a new AgreementHandler instance.
func NewAgreementHandler(agreementService *agreement.Service) *AgreementHandler {
	return &AgreementHandler{
		agreementService: agreementService,
	}
}

// AgreementDTO represents agreement info in API responses.
type AgreementDTO struct {
	ID                  int    `json:"id"`
	Name                string `json:"name"`
	Description         string `json:"description,omitempty"`
	Points              int    `json:"points"`
	RequireConfirmation bool   `json:"require_confirmation"`
	CoverImageURL       string `json:"cover_image_url,omitempty"`
	Status              string `json:"status"`
	GroupID             int    `json:"group_id"`
	CreatorID           int    `json:"creator_id"`
	ApplicableMemberIDs []int  `json:"applicable_member_ids"`
	CreatedAt           string `json:"created_at"`
	UpdatedAt           string `json:"updated_at"`
}

// toAgreementDTO converts ent.Agreement to AgreementDTO.
func toAgreementDTO(a *ent.Agreement) *AgreementDTO {
	if a == nil {
		return nil
	}

	coverImageURL := ""
	if a.CoverImageURL != nil {
		coverImageURL = *a.CoverImageURL
	}

	applicableMemberIDs := a.ApplicableMemberIds
	if applicableMemberIDs == nil {
		applicableMemberIDs = []int{}
	}

	return &AgreementDTO{
		ID:                  a.ID,
		Name:                a.Name,
		Description:         a.Description,
		Points:              a.Points,
		RequireConfirmation: a.RequireConfirmation,
		CoverImageURL:       coverImageURL,
		Status:              string(a.Status),
		GroupID:             a.GroupID,
		CreatorID:           a.CreatorID,
		ApplicableMemberIDs: applicableMemberIDs,
		CreatedAt:           a.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:           a.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

// ListAgreementsResponse represents the response for listing agreements.
type ListAgreementsResponse struct {
	Agreements []*AgreementDTO `json:"agreements"`
}

// ListAgreements handles GET /v1/groups/:groupId/agreements
func (h *AgreementHandler) ListAgreements(c echo.Context) error {
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

	agreements, err := h.agreementService.ListAgreements(c.Request().Context(), groupID, userID, statusFilter)
	if err != nil {
		if errors.Is(err, agreement.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, agreement.ErrInvalidStatus) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_STATUS",
				Message: "无效的状态筛选值",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_LIST_AGREEMENTS_FAILED",
			Message: "获取约定列表失败",
		})
	}

	resp := ListAgreementsResponse{
		Agreements: make([]*AgreementDTO, 0, len(agreements)),
	}
	for _, a := range agreements {
		resp.Agreements = append(resp.Agreements, toAgreementDTO(a))
	}

	return c.JSON(http.StatusOK, resp)
}

// CreateAgreementRequest represents the request body for creating an agreement.
type CreateAgreementRequest struct {
	Name                string `json:"name"`
	Description         string `json:"description"`
	Points              int    `json:"points"`
	RequireConfirmation *bool  `json:"require_confirmation"`
	CoverImageURL       string `json:"cover_image_url"`
	ApplicableMemberIDs []int  `json:"applicable_member_ids"`
}

// CreateAgreement handles POST /v1/groups/:groupId/agreements
func (h *AgreementHandler) CreateAgreement(c echo.Context) error {
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

	var req CreateAgreementRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	input := agreement.CreateInput{
		Name:                req.Name,
		Description:         req.Description,
		Points:              req.Points,
		RequireConfirmation: req.RequireConfirmation,
		CoverImageURL:       req.CoverImageURL,
		ApplicableMemberIDs: req.ApplicableMemberIDs,
	}

	agr, err := h.agreementService.CreateAgreement(c.Request().Context(), groupID, userID, input)
	if err != nil {
		if errors.Is(err, agreement.ErrPermissionDenied) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_PERMISSION_DENIED",
				Message: "您没有权限创建约定",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNameEmpty) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_REQUIRED",
				Message: "约定名称不能为空",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNameTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_TOO_LONG",
				Message: "约定名称不能超过50个字符",
			})
		}
		if errors.Is(err, agreement.ErrDescriptionTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_DESCRIPTION_TOO_LONG",
				Message: "描述不能超过200个字符",
			})
		}
		if errors.Is(err, agreement.ErrInvalidPoints) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_POINTS",
				Message: "积分必须在1到99999之间",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_CREATE_AGREEMENT_FAILED",
			Message: "创建约定失败",
		})
	}

	return c.JSON(http.StatusOK, toAgreementDTO(agr))
}

// GetAgreement handles GET /v1/groups/:groupId/agreements/:id
func (h *AgreementHandler) GetAgreement(c echo.Context) error {
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

	agreementIDStr := c.Param("id")
	agreementID, err := strconv.Atoi(agreementIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_AGREEMENT_ID",
			Message: "无效的约定ID",
		})
	}

	agr, err := h.agreementService.GetAgreement(c.Request().Context(), groupID, agreementID, userID)
	if err != nil {
		if errors.Is(err, agreement.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNotInGroup) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_AGREEMENT_FAILED",
			Message: "获取约定详情失败",
		})
	}

	return c.JSON(http.StatusOK, toAgreementDTO(agr))
}

// UpdateAgreementRequest represents the request body for updating an agreement.
type UpdateAgreementRequest struct {
	Name                *string `json:"name"`
	Description         *string `json:"description"`
	Points              *int    `json:"points"`
	RequireConfirmation *bool   `json:"require_confirmation"`
	CoverImageURL       *string `json:"cover_image_url"`
	ApplicableMemberIDs *[]int  `json:"applicable_member_ids"`
}

// UpdateAgreement handles PUT /v1/groups/:groupId/agreements/:id
func (h *AgreementHandler) UpdateAgreement(c echo.Context) error {
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

	agreementIDStr := c.Param("id")
	agreementID, err := strconv.Atoi(agreementIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_AGREEMENT_ID",
			Message: "无效的约定ID",
		})
	}

	var req UpdateAgreementRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	input := agreement.UpdateInput{
		Name:                req.Name,
		Description:         req.Description,
		Points:              req.Points,
		RequireConfirmation: req.RequireConfirmation,
		CoverImageURL:       req.CoverImageURL,
		ApplicableMemberIDs: req.ApplicableMemberIDs,
	}

	agr, err := h.agreementService.UpdateAgreement(c.Request().Context(), groupID, agreementID, userID, input)
	if err != nil {
		if errors.Is(err, agreement.ErrPermissionDenied) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_PERMISSION_DENIED",
				Message: "您没有权限编辑约定",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNotInGroup) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNameEmpty) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_REQUIRED",
				Message: "约定名称不能为空",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNameTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_NAME_TOO_LONG",
				Message: "约定名称不能超过50个字符",
			})
		}
		if errors.Is(err, agreement.ErrDescriptionTooLong) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_DESCRIPTION_TOO_LONG",
				Message: "描述不能超过200个字符",
			})
		}
		if errors.Is(err, agreement.ErrInvalidPoints) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_POINTS",
				Message: "积分必须在1到99999之间",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_AGREEMENT_FAILED",
			Message: "更新约定失败",
		})
	}

	return c.JSON(http.StatusOK, toAgreementDTO(agr))
}

// UpdateAgreementStatusRequest represents the request body for updating agreement status.
type UpdateAgreementStatusRequest struct {
	Status string `json:"status"`
}

// UpdateAgreementStatus handles PUT /v1/groups/:groupId/agreements/:id/status
func (h *AgreementHandler) UpdateAgreementStatus(c echo.Context) error {
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

	agreementIDStr := c.Param("id")
	agreementID, err := strconv.Atoi(agreementIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_AGREEMENT_ID",
			Message: "无效的约定ID",
		})
	}

	var req UpdateAgreementStatusRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REQUEST",
			Message: "请求格式无效",
		})
	}

	agr, err := h.agreementService.UpdateAgreementStatus(c.Request().Context(), groupID, agreementID, userID, req.Status)
	if err != nil {
		if errors.Is(err, agreement.ErrPermissionDenied) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_PERMISSION_DENIED",
				Message: "您没有权限修改约定状态",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNotFound) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		}
		if errors.Is(err, agreement.ErrAgreementNotInGroup) {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		}
		if errors.Is(err, agreement.ErrInvalidStatus) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_STATUS",
				Message: "无效的状态值，必须是 active 或 inactive",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_UPDATE_STATUS_FAILED",
			Message: "更新约定状态失败",
		})
	}

	return c.JSON(http.StatusOK, toAgreementDTO(agr))
}
