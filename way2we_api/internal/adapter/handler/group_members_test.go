package handler_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/group"

	_ "github.com/mattn/go-sqlite3"
)

func TestGroupHandler_MemberManagement(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	h := handler.NewGroupHandler(service)

	ctx := context.Background()
	// Setup: Admin creates group
	admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("x").Save(ctx)
	assert.NoError(t, err)

	gRes, err := service.CreateGroup(ctx, admin.ID, "TestGroup")
	assert.NoError(t, err)
	groupID := gRes.Group.ID

	// Setup: Member joins group
	member, err := client.User.Create().SetNickname("Member").SetPasswordHash("x").Save(ctx)
	assert.NoError(t, err)
	_, err = client.GroupMember.Create().
		SetUserID(member.ID).
		SetGroupID(groupID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	assert.NoError(t, err)

	t.Run("ListMembers", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/members")
		c.SetParamNames("id")
		c.SetParamValues(strconv.Itoa(groupID))
		c.Set("user_id", admin.ID)

		err := h.ListMembers(c)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Contains(t, rec.Body.String(), "Admin")
		assert.Contains(t, rec.Body.String(), "Member")
	})

	t.Run("UpdateMemberRole", func(t *testing.T) {
		e := echo.New()
		body := `{"role":"admin"}`
		req := httptest.NewRequest(http.MethodPut, "/", strings.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/members/:userId/role")
		c.SetParamNames("id", "userId")
		c.SetParamValues(strconv.Itoa(groupID), strconv.Itoa(member.ID))
		c.Set("user_id", admin.ID)

		err := h.UpdateMemberRole(c)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, rec.Code)

		// Verify promotion
		m, _ := client.GroupMember.Query().Where(groupmember.UserID(member.ID)).Only(ctx)
		assert.Equal(t, groupmember.RoleAdmin, m.Role)
	})

	t.Run("UpdateMemberPermissions", func(t *testing.T) {
		e := echo.New()
		body := `{"permissions":["create_agreement"]}`
		req := httptest.NewRequest(http.MethodPut, "/", strings.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/members/:userId/permissions")
		c.SetParamNames("id", "userId")
		c.SetParamValues(strconv.Itoa(groupID), strconv.Itoa(member.ID))
		c.Set("user_id", admin.ID)

		err := h.UpdateMemberPermissions(c)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, rec.Code)

		// Verify permissions
		m, _ := client.GroupMember.Query().Where(groupmember.UserID(member.ID)).Only(ctx)
		assert.Equal(t, []string{"create_agreement"}, m.Permissions)
	})
}
