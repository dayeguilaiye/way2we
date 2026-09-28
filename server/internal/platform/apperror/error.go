// Package apperror defines safe business error values without HTTP semantics.
package apperror

type Field struct {
	Field string `json:"field"`
	Code  string `json:"code"`
}

type Error struct {
	Code   string
	Fields []Field
}

func (e *Error) Error() string { return e.Code }
func New(code string) *Error   { return &Error{Code: code} }
