require 'spec_helper'
require 'securerandom'

describe Container do
  context 'when starting containers' do
    let(:app) { FactoryGirl.create(:app) }
    let(:command) { '/bin/true' }
    let(:container) { double(Docker::Container, :start => true, :json => {}, :id => container_id) }
    let(:container_id) { SecureRandom.hex(12) }
    let(:environment) { FactoryGirl.create(:environment) }
    let(:instance) { double(Consul::Instance) }
    let(:node) { Consul::Node.new('local-node', '127.0.0.1', 'datacenter') }
    let(:rref) { '123456' }
    let(:worker) { FactoryGirl.create(:worker, app: app, command: command, environment: environment) }

    before do
      allow(Docker::Container).to receive(:create).and_return(container)
      allow(Docker::Image).to receive(:create).and_return(true)
      allow_any_instance_of(Consul::Instance).to receive(:register!)
    end

    it 'pulls the image when necessary' do
      expect(Docker::Image).to receive(:create).
                                with(
                                  hash_including(
                                    'fromImage' => "localhost:4244/#{app.name}:#{rref}"
                                  ),
                                  nil,
                                  kind_of(Docker::Connection),
                                ).and_return(true)
      Container.start(node, app, environment, command, worker.name, rref)
    end

    it 'logs an error without raising an exception if image cannot be pulled' do
      allow(Docker::Image).to receive(:create).and_raise(ArgumentError)

      expect { Container.start(node, app, environment, command, worker.name, rref) }.to_not raise_error
    end

    it 'can start a new container' do
      image_name = "localhost:4244/#{app.name}:#{rref}"

      expect(Docker::Container).to receive(:create).with(
                                     hash_including(
                                       'name' => kind_of(String),
                                       'Cmd' => kind_of(Array),
                                       'Image' => image_name,
                                       'Env' => kind_of(Array),
                                       'ExposedPorts' => hash_including('8888/tcp' => {})
                                     ),
                                     kind_of(Docker::Connection)
                                   ).and_return(
                                     double(Docker::Container, :start => true, :json => {}, :id => container_id)
                                   )
      Container.start(node, app, environment, command, worker.name, rref)
    end

    it 'can start a worker-specific container' do
      expect(Container).to receive(:start).with(node, app, environment, command, worker.name, rref, Hash)
      Container.start_worker(node, worker, rref)
    end

    it 'configures environment based on config set' do
      FactoryGirl.create(:config_set, app: app, environment: environment,
                         config: { 'RAILS_ENV' => 'TEST', 'ENVVAR' => 1, 'ENVVAR2' => 2.0 })

      expect(Docker::Container).to receive(:create).with(
                                     hash_including(
                                       'Env' => array_including(
                                         "RAILS_ENV=TEST",
                                         "ENVVAR=1",
                                         "ENVVAR2=2.0"
                                       )
                                     ),
                                     kind_of(Docker::Connection)
                                   ).and_return(container)
      Container.start(node, app, environment, command, worker.name, rref)
    end

    it 'registers a Consul service with check and tags' do
      allow(Docker::Container).to receive(:create).and_return(
                                     double(
                                       Docker::Container,
                                       :start => true,
                                       :json => {
                                         'Config' => {
                                           'Cmd' => command,
                                           'Image' => "#{app.repo}:#{rref}"
                                         },
                                         'NetworkSettings' => {
                                           'Ports' => [{"PrivatePort" => 2222, "HostPort" => 3333, "Type" => "tcp"}]
                                         }
                                       },
                                       :id => container_id
                                     )
                                   )

      expect(instance).to receive(:register!)
      expect(Consul::Instance).to receive(:new).with(
                                    container_id,
                                    node,
                                    kind_of(Consul::Service),
                                    # TODO
                                    nil, #kind_of(Numeric),
                                    array_including(
                                      "tag:#{rref}",
                                      "rref:#{rref}",
                                      # TODO
                                      # "repo:#{app.repo}",
                                      "command:#{command}"
                                    ),
                                    kind_of(Consul::Check::Ttl)
                                  ).and_return(instance)
      Container.start(node, app, environment, command, worker.name, rref)
    end

    it 'posts to webhooks' do
      worker = FactoryGirl.create(:worker, app: app, command: command, environment: environment)
      allow_any_instance_of(Consul::Instance).to receive(:register!)
      allow(Docker::Image).to receive(:create)
      allow(Docker::Container).to receive(:create).and_return(container)

      expect(Webhook).to receive(:post_for_app).with(
                           app,
                           hash_including(
                             message: kind_of(String),
                             color: /#[0-9a-f]{6}/,
                             from_name: kind_of(String)
                           )
                         )
      Container.start(node, app, environment, command, worker.name, rref)
    end
  end

  context 'when stopping containers' do
    let(:container) { double(Docker::Container) }
    let(:container_id) { SecureRandom.hex(12) }
    let(:instance) { double(Consul::Instance) }
    let(:node) { Consul::Node.new('local-node', '127.0.0.1', 'datacenter') }

    it 'can stop an existing container' do
      allow(Consul::Instance).to receive(:find).with(container_id, node).and_return(double(Consul::Instance, :deregister! => true))
      allow(Docker::Container).to receive(:get).and_return(container)

      expect(container).to receive(:stop)
      Container.stop(node, container_id)
    end

    it 'deregisters the Consul service' do
      allow(Docker::Container).to receive(:get).and_return(double(Docker::Container, :stop => true))
      allow(Consul::Instance).to receive(:find).with(container_id, node).and_return(instance)

      expect(instance).to receive(:deregister!)
      Container.stop(node, container_id)
    end
  end

  context 'when restarting containers' do
    let(:container) { double(Docker::Container) }
    let(:container_id) { SecureRandom.hex(12) }
    let(:instance) { double(Consul::Instance) }
    let(:node) { Consul::Node.new('local-node', '127.0.0.1', 'datacenter') }

    it 'can restart an existing container' do
      allow(Docker::Container).to receive(:get).and_return(container)

      expect(container).to receive(:restart)
      Container.restart(node, container_id)
    end
  end
end
