# loads config variables for connecting to the hub via the API
hub_api_file = Rails.root.join('config', 'hub_api.yml')
config = YAML::load(ERB.new(hub_api_file.read).result)[Rails.env]
config =  HashWithIndifferentAccess.new(config)

unless ENV['HUB_API_BASE'] = config[:api_base]
  raise "missing 'api_base', see config/hub_api.yml"
end

ENV['HUB_SYNC_AUDIT_LOG'] = config[:sync_audit_log]
ENV['HUB_PUSH_AUDIT_LOG'] = config[:push_audit_log]
ENV['HUB_PULL_AUDIT_LOG'] = config[:pull_audit_log]
