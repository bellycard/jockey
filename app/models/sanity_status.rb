class SanityStatus
  attr_reader :environments

  def initialize environments=nil
    @environments = environments || Environment.all
    @environments = [@environments].flatten
  end

  def envs
    environments.map {|env| InEnvironment.new(env) }
  end

  def to_json
    output = envs.inject({}) do |out, env|
      out[env.name] = env.to_json
      out
    end

    output[:stuck_builds] = stuck_builds.select(:id).map(&:id)
    output
  end

  def healthy?
    envs.all?(&:healthy?) && stuck_builds.empty?
  end

  def stuck_builds
    @stuck_builds ||= Build.stuck
  end

  class InEnvironment
    attr_reader :environment
    delegate :name, to: :environment

    def initialize environment
      @environment = environment
    end

    def to_json
      {
        reconcile_plan: reconcile_plan,
        stuck_deploys: stuck_deploys.select(&:id).map(&:id),
        stuck_reconciles: stuck_reconciles.select(&:id).map(&:id),
        stack_status: stack_status,
        status: status
      }
    end

    def status
      healthy? ? 'OK' : 'NOT OK'
    end

    def healthy?
      [reconcile_plan, stuck_deploys, stuck_reconciles].all?(&:empty?) &&
        stack_status.values.all? {|stat| stat == true }
    end

    def reconcile_plan
      @reconcile_plan ||= environment.reconciles.new.plan
    end

    def stuck_deploys
      @stuck_deploys ||= environment.deploys.stuck
    end

    def stuck_reconciles
      @stuck_reconciles ||= environment.reconciles.stuck
    end

    def stack_status
      @stack_status ||= Stack.all.inject({}) do |status_out, stack|
        status_out[stack.name] = stack.docker_healthy_in_env?(environment)
        status_out
      end
    end
  end
end
