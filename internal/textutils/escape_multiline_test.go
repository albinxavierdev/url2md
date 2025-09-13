package textutils

import (
	"strings"
	"testing"
)

func TestEscapeMultiLine(t *testing.T) {
	var tests = []struct {
		Name     string
		Text     string
		Expected string
	}{
		{
			Name:     "empty",
			Text:     "",
			Expected: "",
		},
		{
			Name:     "not needed",
			Text:     "some longer text that is on one line",
			Expected: "some longer text that is on one line",
		},

		{
			Name:     "one newline",
			Text:     "A\nB",
			Expected: "A  \nB",
		},
		{
			Name:     "two newlines",
			Text:     "A\n\nB",
			Expected: "A  \n\\\nB",
		},
		{

			Name: "many newlines",
			// Will be max two newlines characters
			Text:     "line 1\n\n\n\nline 2",
			Expected: "line 1  \n\\\nline 2",
		},

		{
			Name: "multiple empty lines",
			Text: `line1
line2

line3




line4`,
			Expected: `line1  
line2  
\
line3  
\
line4`,
		},

		{
			Name:     "empty line with a space",
			Text:     "line 1\n  \nline 2",
			Expected: "line 1  \n\\\nline 2",
		},

		{
			Name:     "content has a space",
			Text:     "a\n\n b",
			Expected: "a  \n\\\nb",
		},
		{
			Name:     "content is indented",
			Text:     "line 1\n  line 2\n\tline 3",
			Expected: "line 1  \nline 2  \nline 3",
		},

		// TODO: keep existing "\" characters?
	}

	for _, test := range tests {
		t.Run(test.Name, func(t *testing.T) {
			input := TrimConsecutiveNewlines([]byte(test.Text))
			output := EscapeMultiLine(input)

			if string(output) != test.Expected {
				t.Errorf("expected '%s' but got '%s'", test.Expected, string(output))
			}
		})

	}
}

func BenchmarkEscapeMultiLine(b *testing.B) {
	b.Run("new", func(b *testing.B) {
		input := []byte(strings.Repeat("line 1\n\n  \nline 2", 100))

		for i := 0; i < b.N; i++ {
			_ = EscapeMultiLine(input)
		}
	})
}
