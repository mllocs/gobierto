# frozen_string_literal: true

require_dependency "gobierto_people"

module GobiertoPeople
  class Department < ApplicationRecord

    include GobiertoCommon::Metadatable
    include GobiertoCommon::UrlBuildable
    include GobiertoCommon::Sluggable

    belongs_to :site
    has_many :events, class_name: "GobiertoCalendars::Event"
    has_many :gifts
    has_many :invitations
    has_many :trips

    scope :sorted, -> { order(name: :asc) }

    validates :name, presence: true
    validates :slug, uniqueness: { scope: :site_id }

    SHORT_NAME_TRUNCATE_REGEX = Regexp.new([
      "Departamento de ",
      "Departamento ",
      "Department of ",
      "Departament de la ",
      "Departament de ",
      "Departament d'"
    ].join("|")).freeze

    def to_param
      slug
    end

    def parameterize
      { id: slug }
    end

    def attributes_for_slug
      [name]
    end

    def people(params = {})
      GobiertoPeople::QueryWithEvents.filter_department_people(
        params.slice(:from_date, :to_date)
              .merge(people_relation: site.people, department_id: id)
      ).distinct
    end

    def short_name
      result = name.gsub(SHORT_NAME_TRUNCATE_REGEX, "")
      I18n.locale == :ca ? result.gsub("i d'", "i ") : result
    end



  end
end
