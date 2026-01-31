package handler

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/app/points"
)

// PointsHandler handles points-related HTTP requests.
type PointsHandler struct {
	pointsService *points.Service
}

const (
	defaultPointsLogLimit = 50
	maxPointsLogLimit     = 200
)

// NewPointsHandler creates a new PointsHandler instance.
func NewPointsHandler(pointsService *points.Service) *PointsHandler {
	return &PointsHandler{
		pointsService: pointsService,
	}
}

// PointsBalanceResponse represents the response for points balance.
type PointsBalanceResponse struct {
	GroupID int `json:"group_id"`
	UserID  int `json:"user_id"`
	Balance int `json:"balance"`
}

// PointLogDTO represents point log info in API responses.
type PointLogDTO struct {
	ID           int    `json:"id"`
	GroupID      int    `json:"group_id"`
	UserID       int    `json:"user_id"`
	Delta        int    `json:"delta"`
	BalanceAfter int    `json:"balance_after"`
	Reason       string `json:"reason,omitempty"`
	SourceType   string `json:"source_type"`
	SourceID     string `json:"source_id"`
	SourceRef    string `json:"source_ref,omitempty"`
	CreatedAt    string `json:"created_at"`
}

// ListPointLogsResponse represents the response for listing point logs.
type ListPointLogsResponse struct {
	Logs []*PointLogDTO `json:"logs"`
}

// toPointLogDTO converts ent.PointLog to PointLogDTO.
func toPointLogDTO(log *ent.PointLog) *PointLogDTO {
	if log == nil {
		return nil
	}

	return &PointLogDTO{
		ID:           log.ID,
		GroupID:      log.GroupID,
		UserID:       log.UserID,
		Delta:        log.Delta,
		BalanceAfter: log.BalanceAfter,
		Reason:       log.Reason,
		SourceType:   log.SourceType,
		SourceID:     log.SourceID,
		SourceRef:    log.SourceRef,
		CreatedAt:    log.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

// GetMyPoints handles GET /v1/groups/:groupId/points/me
func (h *PointsHandler) GetMyPoints(c echo.Context) error {
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

	balance, err := h.pointsService.GetBalance(c.Request().Context(), groupID, userID)
	if err != nil {
		if errors.Is(err, points.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_GET_POINTS_BALANCE_FAILED",
			Message: "获取积分余额失败",
		})
	}

	return c.JSON(http.StatusOK, PointsBalanceResponse{
		GroupID: groupID,
		UserID:  userID,
		Balance: balance,
	})
}

// ListPointLogs handles GET /v1/groups/:groupId/points/logs?member_id=&from=&to=&limit=&offset=
func (h *PointsHandler) ListPointLogs(c echo.Context) error {
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

	targetUserID := userID
	memberIDParam := c.QueryParam("member_id")
	if memberIDParam != "" {
		parsed, err := strconv.Atoi(memberIDParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_MEMBER_ID",
				Message: "无效的成员ID",
			})
		}
		targetUserID = parsed
	}

	limit := defaultPointsLogLimit
	limitParam := c.QueryParam("limit")
	if limitParam != "" {
		parsed, err := strconv.Atoi(limitParam)
		if err != nil || parsed <= 0 {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_LIMIT",
				Message: "无效的分页大小",
			})
		}
		if parsed > maxPointsLogLimit {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_LIMIT_TOO_LARGE",
				Message: "分页大小超过限制",
			})
		}
		limit = parsed
	}

	offset := 0
	offsetParam := c.QueryParam("offset")
	if offsetParam != "" {
		parsed, err := strconv.Atoi(offsetParam)
		if err != nil || parsed < 0 {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_OFFSET",
				Message: "无效的分页偏移量",
			})
		}
		offset = parsed
	}

	var fromTime *time.Time
	fromParam := c.QueryParam("from")
	if fromParam != "" {
		parsed, err := time.Parse(time.RFC3339, fromParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_FROM",
				Message: "无效的起始时间格式",
			})
		}
		fromTime = &parsed
	}

	var toTime *time.Time
	toParam := c.QueryParam("to")
	if toParam != "" {
		parsed, err := time.Parse(time.RFC3339, toParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_TO",
				Message: "无效的结束时间格式",
			})
		}
		toTime = &parsed
	}

	if fromTime != nil && toTime != nil && fromTime.After(*toTime) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_TIME_RANGE",
			Message: "起始时间不能晚于结束时间",
		})
	}

	logs, err := h.pointsService.ListLogs(c.Request().Context(), groupID, userID, targetUserID, limit, offset, fromTime, toTime)
	if err != nil {
		if errors.Is(err, points.ErrNotGroupMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		}
		if errors.Is(err, points.ErrTargetNotMember) {
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_TARGET_NOT_MEMBER",
				Message: "目标用户不是该群组成员",
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			Code:    "ERR_LIST_POINT_LOGS_FAILED",
			Message: "获取积分流水失败",
		})
	}

	resp := ListPointLogsResponse{
		Logs: make([]*PointLogDTO, 0, len(logs)),
	}
	for _, log := range logs {
		resp.Logs = append(resp.Logs, toPointLogDTO(log))
	}

	return c.JSON(http.StatusOK, resp)
}
