# frozen_string_literal: true

module GobiertoBudgets
  module SearchEngineConfiguration
    class Year

      def self.last(force = false)
        return default if force || current_site.nil?
        cached(:last) { last_year_with_data }
      end

      def self.first
        2010
      end

      def self.all
        cached(:all) { last.downto(first).to_a }
      end

      def self.with_data(params={})
        cached :with_data, params do
          all.select do |year|
            ::GobiertoBudgets::BudgetLine.any_data?(site: current_site, year: year, index: params[:index])
          end
        end
      end

      # private class methods

      def self.last_year_with_data
        current_year.downto(first) do |year|
          next unless GobiertoBudgets::BudgetLine.any_data?(
            site: current_site,
            index: ::GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
            year: year
          )
          if year == current_year && budgets_elaboration_disabled?
            return year
          end
        end
        return default
      end
      private_class_method :last_year_with_data

      def self.budgets_elaboration_disabled?
        current_site.gobierto_budgets_settings && !current_site.gobierto_budgets_settings.settings["budgets_elaboration"]
      end
      private_class_method :budgets_elaboration_disabled?

      def self.default
        2017
      end
      private_class_method :default

      def self.current_year
        Date.today.year
      end
      private_class_method :current_year

      def self.current_site
        GobiertoCore::CurrentScope.current_site
      end
      private_class_method :current_site

      def self.cached(method_name, args={})
        cache_key = "#{name.underscore}/#{method_name}/#{current_site&.id || 'global'}"
        cache_key += args.to_s if args.any?
        Rails.cache.fetch(cache_key) { yield }
      end
      private_class_method :cached

    end
  end
end
