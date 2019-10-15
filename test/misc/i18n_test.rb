# frozen_string_literal: true

require "test_helper"
require "i18n/tasks"

module Misc
  class I18nTest < ActiveSupport::TestCase
    def i18n
      @i18n ||= I18n::Tasks::BaseTask.new
    end

    def missing_keys
      @missing_keys ||= i18n.missing_keys
    end

    def unused_keys
      @unused_keys ||= i18n.unused_keys
    end

    def non_normalized_paths
      @non_normalized_paths ||= i18n.non_normalized_paths
    end

    def test_no_missing_keys
      assert_empty missing_keys, "Missing #{missing_keys.leaves.count} i18n keys, run `i18n-tasks missing' to show them"
    end

    def test_no_unused_keys
      assert_empty unused_keys, "#{unused_keys.leaves.count} unused i18n keys, run `i18n-tasks unused' to show them"
    end

    def test_normalized
      assert_empty non_normalized_paths, "The following files need to be normalized:\n" \
        "#{non_normalized_paths.map { |path| "  #{path}" }.join("\n")}\n" \
        "Please run `i18n-tasks normalize` to fix"
    end
  end
end