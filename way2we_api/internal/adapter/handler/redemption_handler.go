package handler

import (
	"errors"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/app/redemption"
)

// RedemptionHandler handles redemption order-related HTTP requests.
type RedemptionHandler struct {
	service *redemption.Service
}

const (
	defaultOrderListLimit = 50
	maxOrderListLimit     = 200
)

// NewRedemptionHandler creates a new RedemptionHandler instance.
func NewRedemptionHandler(service *redemption.Service) *RedemptionHandler {
	return &RedemptionHandler{service: service}
}

type CreateRedemptionRequest struct {
	Quantity *int `json:"quantity"`
}

type MarkUnsatisfiedRequest struct {
	Reason string `json:"reason"`
}

type RedemptionOrderDTO struct {
	ID                     int    `json:"id"`
	GroupID                int    `json:"group_id"`
	RewardID               int    `json:"reward_id"`
	RewardName             string `json:"reward_name,omitempty"`
	ConsumerID             int    `json:"consumer_id"`
	ConsumerNickname       string `json:"consumer_nickname,omitempty"`
	ProviderID             int    `json:"provider_id"`
	ProviderNickname       string `json:"provider_nickname,omitempty"`
	Quantity               int    `json:"quantity"`
	UnitCostPoints         int    `json:"unit_cost_points"`
	TotalCostPoints        int    `json:"total_cost_points"`
	Status                 string `json:"status"`
	AutoFulfill            bool   `json:"auto_fulfill"`
	AutoComplete           bool   `json:"auto_complete"`
	ProviderIncentiveRatio int    `json:"provider_incentive_ratio"`
	UnsatisfiedReason      string `json:"unsatisfied_reason,omitempty"`
	CreatedAt              string `json:"created_at"`
	UpdatedAt              string `json:"updated_at"`
	FulfilledAt            string `json:"fulfilled_at,omitempty"`
	ConfirmedAt            string `json:"confirmed_at,omitempty"`
	EndedAt                string `json:"ended_at,omitempty"`
}

type CreateRedemptionResponse struct {
	Order *RedemptionOrderDTO `json:"order"`
}

type GetOrderResponse struct {
	Order *RedemptionOrderDTO `json:"order"`
}

type ListOrdersResponse struct {
	Orders []*RedemptionOrderDTO `json:"orders"`
}

func toRedemptionOrderDTO(order *ent.RedemptionOrder) *RedemptionOrderDTO {
	if order == nil {
		return nil
	}

	dto := &RedemptionOrderDTO{
		ID:                     order.ID,
		GroupID:                order.GroupID,
		RewardID:               order.RewardID,
		ConsumerID:             order.ConsumerID,
		ProviderID:             order.ProviderID,
		Quantity:               order.Quantity,
		UnitCostPoints:         order.UnitCostPoints,
		TotalCostPoints:        order.TotalCostPoints,
		Status:                 string(order.Status),
		AutoFulfill:            order.AutoFulfill,
		AutoComplete:           order.AutoComplete,
		ProviderIncentiveRatio: order.ProviderIncentiveRatio,
		UnsatisfiedReason:      order.UnsatisfiedReason,
		CreatedAt:              order.CreatedAt.Format(time.RFC3339),
		UpdatedAt:              order.UpdatedAt.Format(time.RFC3339),
	}

	if order.FulfilledAt != nil {
		dto.FulfilledAt = order.FulfilledAt.Format(time.RFC3339)
	}
	if order.ConfirmedAt != nil {
		dto.ConfirmedAt = order.ConfirmedAt.Format(time.RFC3339)
	}
	if order.EndedAt != nil {
		dto.EndedAt = order.EndedAt.Format(time.RFC3339)
	}
	if order.Edges.Reward != nil {
		dto.RewardName = order.Edges.Reward.Name
	}
	if order.Edges.Consumer != nil {
		dto.ConsumerNickname = order.Edges.Consumer.Nickname
	}
	if order.Edges.Provider != nil {
		dto.ProviderNickname = order.Edges.Provider.Nickname
	}

	return dto
}

// CreateRedemption handles POST /v1/groups/:groupId/rewards/:rewardId/redemptions
func (h *RedemptionHandler) CreateRedemption(c echo.Context) error {
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

	rewardID, err := strconv.Atoi(c.Param("rewardId"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_REWARD_ID",
			Message: "无效的商品ID",
		})
	}

	quantity := 1
	var req CreateRedemptionRequest
	if err := c.Bind(&req); err != nil && !errors.Is(err, io.EOF) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_BODY",
			Message: "请求体解析失败",
		})
	}
	if req.Quantity != nil {
		quantity = *req.Quantity
	}

	order, err := h.service.CreateOrder(c.Request().Context(), groupID, rewardID, userID, quantity)
	if err != nil {
		switch {
		case errors.Is(err, redemption.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, redemption.ErrRewardNotFound), errors.Is(err, redemption.ErrRewardNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_REWARD_NOT_FOUND",
				Message: "商品不存在",
			})
		case errors.Is(err, redemption.ErrRewardInactive):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_REWARD_INACTIVE",
				Message: "商品已下架",
			})
		case errors.Is(err, redemption.ErrInsufficientPoints):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INSUFFICIENT_POINTS",
				Message: "积分不足",
			})
		case errors.Is(err, redemption.ErrInvalidQuantity):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_QUANTITY",
				Message: "数量无效",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_CREATE_ORDER_FAILED",
				Message: "创建订单失败",
			})
		}
	}

	return c.JSON(http.StatusOK, CreateRedemptionResponse{
		Order: toRedemptionOrderDTO(order),
	})
}

// ListOrders handles GET /v1/groups/:groupId/orders?status=&role=&limit=&offset=
func (h *RedemptionHandler) ListOrders(c echo.Context) error {
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

	statusFilter := c.QueryParam("status")
	roleFilter := c.QueryParam("role")

	limit := defaultOrderListLimit
	if limitParam := c.QueryParam("limit"); limitParam != "" {
		parsed, err := strconv.Atoi(limitParam)
		if err != nil || parsed <= 0 {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_LIMIT",
				Message: "无效的分页大小",
			})
		}
		if parsed > maxOrderListLimit {
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

	orders, err := h.service.ListMyOrders(
		c.Request().Context(),
		groupID,
		userID,
		roleFilter,
		statusFilter,
		limit,
		offset,
	)
	if err != nil {
		switch {
		case errors.Is(err, redemption.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, redemption.ErrInvalidRoleFilter):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_ROLE",
				Message: "无效的角色筛选",
			})
		case errors.Is(err, redemption.ErrInvalidStatusFilter):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_INVALID_STATUS",
				Message: "无效的状态筛选",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_LIST_ORDERS_FAILED",
				Message: "获取订单列表失败",
			})
		}
	}

	resp := ListOrdersResponse{
		Orders: make([]*RedemptionOrderDTO, 0, len(orders)),
	}
	for _, order := range orders {
		resp.Orders = append(resp.Orders, toRedemptionOrderDTO(order))
	}

	return c.JSON(http.StatusOK, resp)
}

// GetOrder handles GET /v1/groups/:groupId/orders/:id
func (h *RedemptionHandler) GetOrder(c echo.Context) error {
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

	orderID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_ORDER_ID",
			Message: "无效的订单ID",
		})
	}

	order, err := h.service.GetOrder(c.Request().Context(), groupID, orderID, userID)
	if err != nil {
		switch {
		case errors.Is(err, redemption.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, redemption.ErrNotOrderParticipant):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_ORDER_PERMISSION_DENIED",
				Message: "无权查看该订单",
			})
		case errors.Is(err, redemption.ErrOrderNotFound), errors.Is(err, redemption.ErrOrderNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_ORDER_NOT_FOUND",
				Message: "订单不存在",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_GET_ORDER_FAILED",
				Message: "获取订单详情失败",
			})
		}
	}

	return c.JSON(http.StatusOK, GetOrderResponse{
		Order: toRedemptionOrderDTO(order),
	})
}

// FulfillOrder handles POST /v1/groups/:groupId/orders/:id/fulfill
func (h *RedemptionHandler) FulfillOrder(c echo.Context) error {
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

	orderID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_ORDER_ID",
			Message: "无效的订单ID",
		})
	}

	if err := h.service.MarkFulfilled(c.Request().Context(), groupID, orderID, userID); err != nil {
		switch {
		case errors.Is(err, redemption.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, redemption.ErrNotOrderProvider):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ORDER_PROVIDER",
				Message: "仅提供方可履约",
			})
		case errors.Is(err, redemption.ErrOrderNotFound), errors.Is(err, redemption.ErrOrderNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_ORDER_NOT_FOUND",
				Message: "订单不存在",
			})
		case errors.Is(err, redemption.ErrOrderNotAwaitingFulfill):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_ORDER_STATUS_INVALID",
				Message: "订单状态不允许履约",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_FULFILL_ORDER_FAILED",
				Message: "履约失败",
			})
		}
	}

	return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}

// ConfirmOrder handles POST /v1/groups/:groupId/orders/:id/confirm
func (h *RedemptionHandler) ConfirmOrder(c echo.Context) error {
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

	orderID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_ORDER_ID",
			Message: "无效的订单ID",
		})
	}

	if err := h.service.ConfirmSatisfied(c.Request().Context(), groupID, orderID, userID); err != nil {
		switch {
		case errors.Is(err, redemption.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, redemption.ErrNotOrderConsumer):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ORDER_CONSUMER",
				Message: "仅消费方可确认",
			})
		case errors.Is(err, redemption.ErrOrderNotFound), errors.Is(err, redemption.ErrOrderNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_ORDER_NOT_FOUND",
				Message: "订单不存在",
			})
		case errors.Is(err, redemption.ErrOrderNotAwaitingConfirm):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_ORDER_STATUS_INVALID",
				Message: "订单状态不允许确认",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_CONFIRM_ORDER_FAILED",
				Message: "确认失败",
			})
		}
	}

	return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}

// MarkUnsatisfied handles POST /v1/groups/:groupId/orders/:id/unsatisfied
func (h *RedemptionHandler) MarkUnsatisfied(c echo.Context) error {
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

	orderID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_ORDER_ID",
			Message: "无效的订单ID",
		})
	}

	var req MarkUnsatisfiedRequest
	if err := c.Bind(&req); err != nil && !errors.Is(err, io.EOF) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			Code:    "ERR_INVALID_BODY",
			Message: "请求体解析失败",
		})
	}

	if err := h.service.MarkUnsatisfied(c.Request().Context(), groupID, orderID, userID, req.Reason); err != nil {
		switch {
		case errors.Is(err, redemption.ErrNotGroupMember):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_MEMBER",
				Message: "您不是该群组的成员",
			})
		case errors.Is(err, redemption.ErrNotOrderConsumer):
			return c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "ERR_NOT_ORDER_CONSUMER",
				Message: "仅消费方可操作",
			})
		case errors.Is(err, redemption.ErrUnsatisfiedReasonTooLong):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_REASON_TOO_LONG",
				Message: "原因长度超出限制",
			})
		case errors.Is(err, redemption.ErrOrderNotFound), errors.Is(err, redemption.ErrOrderNotInGroup):
			return c.JSON(http.StatusNotFound, ErrorResponse{
				Code:    "ERR_ORDER_NOT_FOUND",
				Message: "订单不存在",
			})
		case errors.Is(err, redemption.ErrOrderNotAwaitingConfirm):
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				Code:    "ERR_ORDER_STATUS_INVALID",
				Message: "订单状态不允许操作",
			})
		default:
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				Code:    "ERR_MARK_UNSATISFIED_FAILED",
				Message: "提交不满意失败",
			})
		}
	}

	return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}
