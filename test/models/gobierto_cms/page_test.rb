# frozen_string_literal: true

require "test_helper"
require "support/concerns/gobierto_attachments/attachable_test"

module GobiertoCms
  class PageTest < ActiveSupport::TestCase
    include GobiertoAttachments::AttachableTest

    def page
      @page ||= gobierto_cms_pages(:consultation_faq)
    end
    alias attachable_with_attachment page
    alias collectionable_object page

    def process
      @process ||= gobierto_participation_processes(:gender_violence_process)
    end

    def site_news
      @site_news ||= gobierto_cms_pages(:site_news_1)
    end

    def site_page
      @site_page ||= gobierto_cms_pages(:consultation_faq)
    end

    def process_news
      @process_news ||= gobierto_cms_pages(:notice_1)
    end

    def module_page
      @module_page ||= gobierto_cms_pages(:how_to_participate)
    end

    def attachable_without_attachment
      @attachable_without_attachment ||= gobierto_cms_pages(:privacy)
    end
    alias process_information_page attachable_without_attachment

    def test_valid
      assert page.valid?
    end

    def test_searchable_body
      assert page.send(:searchable_body).include?("This is the body of the page")
      assert page.send(:searchable_body).include?("Cuerpo página consultas")
    end

    def test_searchable_body_on_empty_page
      new_page = GobiertoCms::Page.new
      assert_equal "", new_page.send(:searchable_body)
      assert_equal "", new_page.send(:searchable_body)
    end

    def test_destroy
      page.destroy

      assert page.slug.include?("archived-")
    end

    def test_destroyable?
      refute process_information_page.destroyable?

      ::GobiertoParticipation::ProcessStagePage.where(
        page_id: process_information_page.id
      ).destroy_all

      assert process_information_page.reload.destroyable?
    end

    def test_public?
      assert [site_news, site_page, process_news, module_page].all?(&:public?)

      process.draft!

      refute process_news.public?

      [site_news, site_page, module_page].map(&:draft!)

      assert [site_news, site_page, process_news, module_page].none?(&:public?)
    end

  end
end
