def fake_node
  Consul::Node.new(
    'node.example.com',
    '192.0.2.103'
  )
end

def fake_service
  Consul::Service.new('foo-web')
end

def fake_instance
  Consul::Instance.new('abcdef', fake_node, fake_service)
end