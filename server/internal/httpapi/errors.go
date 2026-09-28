package httpapi

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
	"way2we/server/internal/platform/apperror"
)

type ErrorBody struct {
	Code    string           `json:"code"`
	Message string           `json:"message"`
	Fields  []apperror.Field `json:"field_errors"`
}
type ErrorEnvelope struct {
	Error     ErrorBody `json:"error"`
	RequestID string    `json:"request_id"`
}
type publicError struct {
	status  int
	message string
}

var errorCatalog = map[string]publicError{
	"INVALID_REQUEST":         {400, "请求无法提交，请检查后重试。"},
	"UNAUTHENTICATED":         {401, "登录已到期，请重新登录。"},
	"CODE_INVALID_OR_EXPIRED": {401, "验证码无效或已过期，请重新申请。"},
	"FORBIDDEN":               {403, "你暂时无法执行此操作。"},
	"MEMBERSHIP_INACTIVE":     {403, "你已退出这个空间。"},
	"NOT_FOUND":               {404, "内容暂时不可用。"},
	"OPERATION_NOT_FOUND":     {404, "尚未查到操作结果，请继续核对。"},
	"INSUFFICIENT_POINTS":     {409, "积分不足，请调整数量或稍后再试。"},
	"ITEM_CHANGED":            {409, "商品已更新，请查看最新内容。"},
	"ITEM_UNAVAILABLE":        {409, "商品暂时无法购买。"},
	"RESOURCE_STATE_CONFLICT": {409, "状态已变化，请刷新后重试。"},
	"IDEMPOTENCY_KEY_REUSED":  {409, "操作内容已变化，请重新确认。"},
	"OPERATION_IN_PROGRESS":   {409, "操作正在处理中，请稍后核对。"},
	"UPLOAD_NOT_READY":        {409, "图片尚未处理完成，请稍后重试。"},
	"VALIDATION_FAILED":       {422, "请检查填写内容。"},
	"INVALID_MEDIA":           {422, "图片无法使用，请重新选择。"},
	"RATE_LIMITED":            {429, "操作过于频繁，请稍后重试。"},
	"INTERNAL_ERROR":          {500, "暂时无法完成，请稍后重试。"},
	"SERVICE_UNAVAILABLE":     {503, "服务暂时不可用，请稍后重试。"},
}

func mapError(err error, requestID string) (int, ErrorEnvelope) {
	code := "INTERNAL_ERROR"
	fields := []apperror.Field{}
	var business *apperror.Error
	if errors.As(err, &business) {
		if _, ok := errorCatalog[business.Code]; ok {
			code = business.Code
			if business.Fields != nil {
				fields = business.Fields
			}
		}
	}
	p := errorCatalog[code]
	return p.status, ErrorEnvelope{Error: ErrorBody{Code: code, Message: p.message, Fields: fields}, RequestID: requestID}
}

// safeErrorKind deliberately excludes raw errors, which can contain SQL or credentials.
func safeErrorKind(err error) string {
	var business *apperror.Error
	var pgerr *pgconn.PgError
	switch {
	case errors.As(err, &business):
		return "business"
	case errors.Is(err, context.DeadlineExceeded):
		return "deadline"
	case errors.Is(err, context.Canceled):
		return "cancelled"
	case errors.As(err, &pgerr):
		return "database_" + pgerr.Code
	default:
		return "internal"
	}
}
