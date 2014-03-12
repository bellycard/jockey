class GithubWebhooksController < ApiController
  include GithubSignature

  def current_user
    nil
  end

  def webhook
    app = App.find(params[:id])
    event = env['HTTP_X_GITHUB_EVENT']

    # Return 401 if not authorized
    unless GithubSignature.verify(app.id, request.body.read, env['HTTP_X_HUB_SIGNATURE'])
      Honeybadger.notify('Github Webhook failed to match signature',
                         context: { app_id: app.id,
                                    settings_page: "https://www.github.com/#{app.repo}/settings/hooks"
                                  }
                        )
      error!(present_error(:unauthorized, 'Missing X-Hub-Signature header'), 401)
    end

    # Return 422 if event header is missing
    error!(present_error(:missing_header, 'Missing X-Hub-Event'), 422) unless event

    case event
    when 'ping'
      render json: {}
    when 'push'
      logger.info("Push for #{app.name}: ref=#{params['ref']} after=#{params['after']}")

      # skip this if it is already built successfully
      if Build.where(state: 'completed',
                     rref: params[:after],
                     app_id: app.id).count > 0
        logger.warn('Build already successfully completed. Skipping build')
        render json: {}
        return
      end

      # Trigger new build
      build = Build.create!(app: app, ref: params[:after])
      build.run_in_container!

      # Return
      render json: { build_id: build.id }
    else
      render(json: { error: { code: :not_yet_implemented, message: "Event #{event} not yet implemented" } },
             status: 422)
    end
  end
end
