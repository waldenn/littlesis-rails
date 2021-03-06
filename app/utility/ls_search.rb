# frozen_string_literal: true

# Utility functions for searching
# TODO: move and combine functions from SearchController, EntitySearch and
# EntityMatcher into this module
module LsSearch
  # This un-escapes double quotes (")
  # When a user searches for a term on LittleSis, we use ThinkingSphinx's escape
  # helper fucntion running submittig the query to sphinx.
  # However, we want to expose some of the sphinx's extended search functionality,
  # and therefore have to un-escape those query features we allow.
  def self.escape(query)
    ThinkingSphinx::Query
      .escape(query)
      .gsub('\\"', '"')
  end
end
