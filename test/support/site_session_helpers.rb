# frozen_string_literal: true

module SiteSessionHelpers
  def with_current_site(site, opts = {})
    if opts[:include_host]
      with_site_host(site) do
        yield
      end
    else
      stub_current_site(site) { yield }
    end
  end

  def with_each_current_site(*sites)
    sites.each do |site|
      with_current_site(site) do
        yield(site)
      end
    end
  end
end

def stub_current_site(site)
  if GobiertoSiteConstraint.new.public_methods.include?(:__minitest_any_instance_stub__matches?)
    raise(Exception, "GobiertoSiteConstraint.matches? already stubbed. Maybe with_current_site is in use outside this block?")
  end

  GobiertoSiteConstraint.stub_any_instance(:matches?, true) do
    ApplicationController.stub_any_instance(:current_site, site) do
      ApiBaseController.stub_any_instance(:current_site, site) do
        GobiertoAdmin::BaseController.stub_any_instance(:current_site, SiteDecorator.new(site)) do
          ::GobiertoCore::CurrentScope.current_site = site
          yield
          ::GobiertoCore::CurrentScope.current_site = nil
        end
      end
    end
  end
end
