package tree_sitter_time_track_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_time_track "github.com/tristanbarrow/time_track/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_time_track.Language())
	if language == nil {
		t.Errorf("Error loading TimeTrack grammar")
	}
}
