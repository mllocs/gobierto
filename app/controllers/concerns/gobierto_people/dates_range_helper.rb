# frozen_string_literal: true

module GobiertoPeople
  module DatesRangeHelper
    extend ActiveSupport::Concern

    included do
      helper_method :dates_range?, :filter_start_date, :filter_end_date
    end

    def filter_start_date
      date_from_param_or_session(:start_date) if site_configuration_dates_range?
    end

    def filter_end_date
      date_from_param_or_session(:end_date) if site_configuration_dates_range?
    end

    def site_configuration_dates_range?
      site_configuration_date_range.values.compact.present?
    end

    def empty_date_range_param?
      (params.keys & %w(start_date end_date)).empty?
    end

    private

    def site_configuration_date_range
      @site_configuration_date_range ||= { start_date: parse_date(current_site.configuration.configuration_variables["gobierto_people_default_filter_start_date"]),
                                           end_date: parse_date(current_site.configuration.configuration_variables["gobierto_people_default_filter_end_date"]) }
    end

    def parse_date(date)
      return unless date
      Time.zone.parse(date)
    rescue ArgumentError
      nil
    end

    def date_from_param_or_session(param)
      if params[param].present?
        session[param] = Time.zone.parse(params[param])
      else
        session[param] ||= site_configuration_date_range[param]
      end
    rescue ArgumentError
      default_value
    end
  end
end
