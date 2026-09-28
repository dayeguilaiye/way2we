package account

import "testing"

func TestNormalizeEmail(t *testing.T) {
	for _, raw := range []string{"", "a\r\n@example.com", "Display <a@example.com>", "中文@example.com", "a b@example.com", "no-at"} {
		if _, err := NormalizeEmail(raw); err == nil {
			t.Errorf("accepted invalid email")
		}
	}
	got, err := NormalizeEmail(" A.B+tag@EXAMPLE.com ")
	if err != nil || got != "a.b+tag@example.com" {
		t.Fatal("normalization changed mailbox identity")
	}
}
