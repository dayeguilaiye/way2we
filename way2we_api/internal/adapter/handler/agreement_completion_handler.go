package handler

import (
	"errors"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/app/agreementcompletion"
)

// AgreementCompletionHandler handles agreement completion-related HTTP requests.
type AgreementCompletionHandler struct {
	service *agreementcompletion.Service
}

const (
	defaultCompletionListLimit = 50
	maxCompletionListLimit     = 200
)

// NewAgreementCompletionHandler creates a new AgreementCompletionHandler instance.
func NewAgreementCompletionHandler(service *agreementcompletion.Service) *AgreementCompletionHandler {
	return &AgreementCompletionHandler{service: service}
}

type CreateCompletionRequest struct {
	CompleterID *int `json:"completer_id"`
}

type RejectCompletionRequest struct {
	Reason string `json:"reason"`
}

type AgreementCompletionDTO struct {
	ID                  int    `json:"id"`
	GroupID             int    `json:"group_id"`
	AgreementID         int    `json:"agreement_id"`
	AgreementName       string `json:"agreement_name,omitempty"`
	CompleterID         int    `json:"completer_id"`
	CompleterNickname   string `json:"completer_nickname,omitempty"`
	RecorderID          int    `json:"recorder_id"`
	RecorderNickname    string `json:"recorder_nickname,omitempty"`
	Points              int    `json:"points"`
	RequireConfirmation bool   `json:"require_confirmation"`
	Status              string `json:"status"`
	RejectedReason      string `json:"rejected_reason,omitempty"`
	ConfirmedBy         *int   `json:"confirmed_by,omitempty"`
	ConfirmedAt         string `json:"confirmed_at,omitempty"`
	RejectedAt          string `json:"rejected_at,omitempty"`
	CreatedAt           string `json:"created_at"`
}

type ListCompletionsResponse struct {
	Completions []*AgreementCompletionDTO `json:"completions"`
}

type CreateCompletionResponse struct {
	Completion *AgreementCompletionDTO `json:"completion"`
	Message    string                  `json:"message"`
}

func toAgreementCompletionDTO(completion *ent.AgreementCompletion) *AgreementCompletionDTO {
	if completion == nil {
		return nil
	}

	dto := &AgreementCompletionDTO{
		ID:                  completion.ID,
		GroupID:             completion.GroupID,
		AgreementID:         completion.AgreementID,
		CompleterID:         completion.CompleterID,
		RecorderID:          completion.RecorderID,
		Points:              completion.Points,
		RequireConfirmation: completion.RequireConfirmation,
		Status:              string(completion.Status),
		RejectedReason:      completion.RejectedReason,
		ConfirmedBy:         completion.ConfirmedBy,
		CreatedAt:           completion.CreatedAt.Format(time.RFC3339),
	}

	if completion.ConfirmedAt != nil {
		dto.ConfirmedAt = completion.ConfirmedAt.Format(time.RFC3339)
	}
	if completion.RejectedAt != nil {
		dto.RejectedAt = completion.RejectedAt.Format(time.RFC3339)
	}
	if completion.Edges.Agreement != nil {
		dto.AgreementName = completion.Edges.Agreement.Name
	}
	if completion.Edges.Completer != nil {
		dto.CompleterNickname = completion.Edges.Completer.Nickname
	}
	if completion.Edges.Recorder != nil {
		dto.RecorderNickname = completion.Edges.Recorder.Nickname
	}

	return dto
}

// CreateCompletion handles POST /v1/groups/:groupId/agreements/:agreementId/completions
func (h *AgreementCompletionHandler) CreateCompletion(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, err := strconv.Atoi(c.Param("groupId"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	agreementID, err := strconv.Atoi(c.Param("agreementId"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_AGREEMENT_ID",
			Message: "无效的约定ID",
		})
	}

	var req CreateCompletionRequest
	if err := c.Bind(&req); err != nil && !errors.Is(err, io.EOF) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_BODY",
			Message: "请求体解析失败",
		})
	}

	completerID := 0
	if req.CompleterID != nil {
		completerID = *req.CompleterID
	}

	completion, err := h.service.CreateCompletion(c.Request().Context(), groupID, agreementID, userID, completerID)
	if err != nil {
		switch {
		case errors.Is(err, agreementcompletion.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, agreementcompletion.ErrPermissionDenied):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_COMPLETION_PERMISSION_DENIED",
				Message: "没有权限代他人记录",
			})
		case errors.Is(err, agreementcompletion.ErrAgreementNotFound), errors.Is(err, agreementcompletion.ErrAgreementNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_COMPLETION_AGREEMENT_NOT_FOUND",
				Message: "约定不存在",
			})
		case errors.Is(err, agreementcompletion.ErrAgreementInactive):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_COMPLETION_AGREEMENT_INACTIVE",
				Message: "约定未启用",
			})
		case errors.Is(err, agreementcompletion.ErrCompleterNotMember):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_COMPLETION_COMPLETER_NOT_MEMBER",
				Message: "完成者不是该群组成员",
			})
		case errors.Is(err, agreementcompletion.ErrCompleterNotApplicable):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_APPLICABLE",
				Message: "完成者不在约定适用范围内",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_CREATE_COMPLETION_FAILED",
				Message: "记录约定完成失败",
			})
		}
	}

	message := "已提交，等待确认"
	if string(completion.Status) == "confirmed" {
		message = "记录完成，积分已入账"
	}

	return c.JSON(http.StatusOK, CreateCompletionResponse{
		Completion: toAgreementCompletionDTO(completion),
		Message:    message,
	})
}

// ListCompletions handles GET /v1/groups/:groupId/agreement-completions?status=pending&limit=&offset=
func (h *AgreementCompletionHandler) ListCompletions(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, err := strconv.Atoi(c.Param("groupId"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	status := c.QueryParam("status")
	if status != "" && status != "pending" {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_STATUS",
			Message: "无效的状态值，必须是 pending",
		})
	}

	limit := defaultCompletionListLimit
	if limitParam := c.QueryParam("limit"); limitParam != "" {
		parsed, err := strconv.Atoi(limitParam)
		if err != nil || parsed <= 0 {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_LIMIT",
				Message: "无效的分页大小",
			})
		}
		if parsed > maxCompletionListLimit {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_LIMIT_TOO_LARGE",
				Message: "分页大小超过限制",
			})
		}
		limit = parsed
	}

	offset := 0
	if offsetParam := c.QueryParam("offset"); offsetParam != "" {
		parsed, err := strconv.Atoi(offsetParam)
		if err != nil || parsed < 0 {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_OFFSET",
				Message: "无效的分页偏移量",
			})
		}
		offset = parsed
	}

	completions, err := h.service.ListPending(c.Request().Context(), groupID, userID, limit, offset)
	if err != nil {
		if errors.Is(err, agreementcompletion.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_LIST_COMPLETIONS_FAILED",
			Message: "获取待确认列表失败",
		})
	}

	resp := ListCompletionsResponse{
		Completions: make([]*AgreementCompletionDTO, 0, len(completions)),
	}
	for _, completion := range completions {
		resp.Completions = append(resp.Completions, toAgreementCompletionDTO(completion))
	}

	return c.JSON(http.StatusOK, resp)
}

// ConfirmCompletion handles POST /v1/groups/:groupId/agreement-completions/:id/confirm
func (h *AgreementCompletionHandler) ConfirmCompletion(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, err := strconv.Atoi(c.Param("groupId"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	completionID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_COMPLETION_ID",
			Message: "无效的记录ID",
		})
	}

	if err := h.service.Confirm(c.Request().Context(), groupID, completionID, userID); err != nil {
		switch {
		case errors.Is(err, agreementcompletion.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, agreementcompletion.ErrCannotSelfConfirm):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_COMPLETION_SELF_CONFIRM",
				Message: "不能确认自己完成的记录",
			})
		case errors.Is(err, agreementcompletion.ErrCompletionNotFound), errors.Is(err, agreementcompletion.ErrCompletionNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_FOUND",
				Message: "记录不存在",
			})
		case errors.Is(err, agreementcompletion.ErrCompletionNotPending):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_PENDING",
				Message: "记录已处理",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_CONFIRM_COMPLETION_FAILED",
				Message: "确认失败",
			})
		}
	}

	return c.NoContent(http.StatusOK)
}

// RejectCompletion handles POST /v1/groups/:groupId/agreement-completions/:id/reject
func (h *AgreementCompletionHandler) RejectCompletion(c echo.Context) error {
	userID, ok := c.Get("user_id").(int)
	if !ok {
		return c.JSON(http.StatusUnauthorized, ErrorResponse{
			Code:    "ERR_UNAUTHORIZED",
			Message: "未授权",
		})
	}

	groupID, err := strconv.Atoi(c.Param("groupId"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_GROUP_ID",
			Message: "无效的群组ID",
		})
	}

	completionID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_COMPLETION_ID",
			Message: "无效的记录ID",
		})
	}

	var req RejectCompletionRequest
	if err := c.Bind(&req); err != nil && !errors.Is(err, io.EOF) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_BODY",
			Message: "请求体解析失败",
		})
	}

	if err := h.service.Reject(c.Request().Context(), groupID, completionID, userID, req.Reason); err != nil {
		switch {
		case errors.Is(err, agreementcompletion.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, agreementcompletion.ErrCompletionNotFound), errors.Is(err, agreementcompletion.ErrCompletionNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_FOUND",
				Message: "记录不存在",
			})
		case errors.Is(err, agreementcompletion.ErrCompletionNotPending):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_COMPLETION_NOT_PENDING",
				Message: "记录已处理",
			})
		case errors.Is(err, agreementcompletion.ErrRejectReasonTooLong):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_COMPLETION_REASON_TOO_LONG",
				Message: "驳回原因过长",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_REJECT_COMPLETION_FAILED",
				Message: "驳回失败",
			})
		}
	}

	return c.NoContent(http.StatusOK)
}
