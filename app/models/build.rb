class Build < ActiveRecord::Base
  include DockerLoggable
  include RailsAdminGenericRender
  BASE_DOCKERFILE = <<-EODOCKERFILE
FROM belly/buildstep
ADD . /app
RUN /build/builder
CMD /start web'
EODOCKERFILE

  rails_admin do
    configure :render_actions do
      visible false # so it's not on new/edit
    end

    show do
      include_all_fields
      field :render_actions do
        label 'Actions'
      end
    end
  end

  scope :incomplete, -> { where(completed_at: nil) }
  scope :stuck, -> { incomplete.where("created_at <= ?", 1.hour.ago) }

  belongs_to :app
  has_many :deploys
  validates_presence_of :ref
  before_validation :set_initial_state, on: :create

  valid_states = %w(completed failed in_progress)
  validates_inclusion_of :state, in: valid_states
  valid_states.each do |s|
    define_method "#{s}?" do
      state == s
    end
  end

  def self.latest_for_rref(rref)
    where(rref: rref).order(created_at: :desc).first
  end

  def run!
    create_tmpdir
    clone_repo
    mod_git_time

    update(rref: repo.object(ref).sha)
    update(state: 'in_progress')

    repo.checkout(rref)
    create_dockerfile unless File.exist?(dockerfile_path)

    build_docker_image
    tag_docker_image
    push_docker_image

    update(state: 'completed', completed_at: Time.now)

    msg = "Build #{id} for #{app.name}:#{rref.first(10)} #{state.upcase}"
    Napa::Logger.logger.info(msg)
    Webhook.post_for_app(app, message: msg, color: '#00ff00', from_name: 'jockey build')
  rescue => e
    reason = "#{e.message}\nStacktrace:\n#{e.backtrace.join("\n\t")}"
    update(state: 'failed', failure_reason: reason, completed_at: Time.now)

    msg = "Build #{id} for #{app.name}:#{rref.first(10)} #{state.upcase}"
    Napa::Logger.logger.error("#{msg}:\n#{reason}")
    Webhook.post_for_app(app, message: "#{msg}: #{e.message.first(255)}", color: '#ff0000', from_name: 'jockey build')
  ensure
    post_to_callback
  end

  def run_in_container!
    container = Container.background("rake build:run[#{id}]")
    update!(container_host: container['host'], container_id: container['id'])
  rescue => e
    msg = "Failed to start build container: #{e.message}\n\nStacktrace:\n#{e.backtrace.join("\n\t")}"
    Napa::Logger.logger.error(msg)
  end

  def dir
    @dir ||= Dir.mktmpdir
    Napa::Logger.logger.info("Created temporary directory #{@dir}") unless defined? @dir
    @dir
  end
  alias_method :create_tmpdir, :dir

  def repo
    @repo ||= Git.clone("https://#{ENV['GITHUB_OAUTH_TOKEN']}@github.com/#{app.repo}.git", app.name, path: @dir)
  end
  alias_method :clone_repo, :repo

  def create_dockerfile
    Napa::Logger.logger.info("Creating Dockerfile using buildstep / heroku buildpacks for #{app.name}")
    File.open(dockerfile_path, 'w') do |file|
      file << BASE_DOCKERFILE
    end
  end

  def mod_git_time
    FileUtils.cp(
      File.join(Rails.root, 'scripts', 'git_mod_time.sh'),
      File.join(dir, app.name, 'git_mod_time.sh')
    )
    Dir.chdir File.join(dir, app.name) do
      `bash git_mod_time.sh`
    end
    # TODO: remove git_mod_time.sh?
  end

  def dockerfile_path
    File.join(app_path, 'Dockerfile')
  end

  def app_path
    File.join(dir, app.name)
  end

  def docker_connection
    return @docker_connection if defined? @docker_connection

    node_selection = NodeSelection.new(
      worker: Worker.new(
        app: App.new(stack: Stack.find_by_name('build')),
        environment: Environment.find_by_name(Rails.env)
      )
    )

    node = node_selection.next_available_nodes.first
    NodeSelection.docker_connection_for_node(node)
  end

  def docker_image
    return @docker_image if defined? @docker_image

    Napa::Logger.logger.info("Building Docker image #{app.name}:#{rref}")
    @docker_image = Docker::Image.build_from_dir(app_path, {}, docker_connection) do |output|
      Napa::Logger.logger.info(output)
    end
  end
  alias_method :build_docker_image, :docker_image

  def tag_docker_image
    Napa::Logger.logger.info("Tagging Docker image #{app.name}:#{rref}")
    docker_image.tag(repo: "#{ ENV['DOCKER_REGISTRY_URL'] }/#{ app.name }", tag: rref, force: true)
    docker_image.tag(repo: "#{ ENV['DOCKER_REGISTRY_URL'] }/#{ app.name }", tag: 'latest', force: true)
  end

  def push_docker_image
    Napa::Logger.logger.info("Pushing docker image #{app.name}:#{rref} to #{ ENV['DOCKER_REGISTRY_URL'] }")
    docker_image.push(nil, tag: rref)
    docker_image.push(nil, tag: 'latest')
  end

  def post_to_callback
    return if callback_url.blank?

    Napa::Logger.logger.info("Posting build data to callback for build #{id}")
    conn = Faraday.new(url: callback_url) do |faraday|
      faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP
    end
    conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = BuildRepresenter.new(self).to_json
      req.options.timeout = 30           # open/read timeout in seconds
      req.options.open_timeout = 30      # connection open timeout in seconds
    end
  end

  def set_initial_state
    self.state ||= 'in_progress'
  end
end
