class Stack < ActiveRecord::Base
  has_many :apps
  validates_uniqueness_of :name

  def nodes_in_env env
    Consul::Service.find(['jockey', name, env.name].join('-')).nodes
  rescue Consul::RecordNotFound
    []
  end

  def docker_pings_in_env env
    nodes_in_env(env).map do |node|
      begin
        conn = NodeSelection.docker_connection_for_node(node)
        conn.get('/_ping')
      rescue
        'NOT OK'
      end
    end
  end

  def docker_healthy_in_env? env
    docker_pings_in_env(env).all? {|stat| stat == 'OK' }
  end
end
