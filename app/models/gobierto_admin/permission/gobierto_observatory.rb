# frozen_string_literal: true

module GobiertoAdmin
  class Permission::GobiertoObservatory < GroupPermission
    default_scope -> { where(namespace: "site_module", resource_type: "gobierto_observatory") }
  end
end
