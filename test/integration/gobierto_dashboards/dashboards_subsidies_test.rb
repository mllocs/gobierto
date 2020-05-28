# frozen_string_literal: true

require "test_helper"

class GobiertoDashboards::DashboardsSubsidiesTest < ActionDispatch::IntegrationTest
  def setup
    super
    @summary_path = gobierto_dashboards_subsidies_summary_path(locale: 'es')
    @subsidies_path = gobierto_dashboards_subsidies_path

    ::GobiertoModuleSettings.create!({
      site_id: site.id,
      module_name: "GobiertoDashboards",
      settings: settings
    })

    copy_mock_csv_files
  end

  def teardown
    remove_mock_csv_files
  end

  def copy_mock_csv_files
    FileUtils.cp File.join(Rails.root, 'test', 'fixtures', 'files', 'gobierto_dashboards', 'subsidies.csv'),
      File.join(Rails.root, 'public', 'subsidies.csv')
  end

  def remove_mock_csv_files
    FileUtils.rm File.join(Rails.root, 'public', 'subsidies.csv')
  end

  def site
    @site ||= sites(:madrid)
  end

  def settings
    {
      "dashboards_config" => {
        "dashboards" => {
          "subsidies" => {
            "enabled" => true,
            "data_urls" => {
              "subsidies" => "/subsidies.csv",
            }
          }
        }
      }
    }
  end

  def test_summary
    with(site: site, js: true) do
      visit @summary_path

      ## Active tab is Summary
      assert find(".dashboards-home-nav--tab.is-active").text, 'RESUMEN'

      # Box
      metrics_box = find(".metric_box", match: :first)

      assert metrics_box.has_content?("552\nsubvenciones por importe de\n2.462.031,49 €")
      assert metrics_box.has_content?("99,64 %\na colectivos por importe de\n2.461.652,49 €")
      assert metrics_box.has_content?("0,36 %\na particulares por importe de\n379,00 €")

      assert metrics_box.has_content?("Importe medio\n4460,20 €")
      assert metrics_box.has_content?("Importe mediano\n2074,36 €")

      ## Headlines
      assert page.has_content?("El 30 % de las subvenciones son menores de 1.000 €")
      assert page.has_content?("La mayor subvención supone un 6 % de todo el gasto en subvenciones")
      assert page.has_content?("El 13 % de subvenciones concentran el 50% de todo el gasto")

      ## Charts
      # Category
      category_container = find("#category-bars", match: :first)

      assert category_container.has_content?("URBANISMO")
      assert category_container.has_content?("74,3 %")

      # Beneficiaries table
      first_beneficiary = find(".dashboards-home-main--tr", match: :first)

      assert first_beneficiary.has_content?('ALIANZA CRISTIANA DE JOVENES DE LA Y.M.C.A.')
      assert first_beneficiary.has_content?('22.500,31 €')
    end
  end

  def test_subsidies
    with(site: site, js: true) do
      # Subsidies Index
      #################
      visit @subsidies_path

      assert page.has_content?('BENEFICIARY')
      assert page.has_content?('AMOUNT')
      assert page.has_content?('DATE')

      # Active tab is Subsidies
      assert find(".dashboards-home-nav--tab.is-active").text, 'SUBSIDIES'

      first_subsidy = find(".dashboards-home-main--tr", match: :first)

      # Beneficiary
      assert first_subsidy.has_content?('SUSANA HERRANZ')

      # Amount
      assert first_subsidy.has_content?('€133.00')

      # Date
      assert first_subsidy.has_content?('2019-02-26')


      # Subsidies Show
      ################
      first_subsidy.click

      # Active tab is still Subsidies
      assert find(".dashboards-home-nav--tab.is-active").text, 'SUBSIDIES'

      # Url is updated
      assert_equal current_path, "/dashboards/subvenciones/subvenciones/201902261222133"

      # Title
      assert page.has_content?('CONVOCATORIA INSTRUMENTAL AYUDAS COMEDOR ESCOLAR')

      # Beneficiary
      assert page.has_content?('SUSANA HERRANZ')
    end
  end

end