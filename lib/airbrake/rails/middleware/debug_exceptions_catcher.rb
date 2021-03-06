module Airbrake
  module Rails
    module Middleware
      module DebugExceptionsCatcher
        def self.included(base)
          base.send(:alias_method_chain,:render_exception,:airbrake)
        end

        def define_proxy_method(klass)
          klass.class_eval do
            def call_the_real_method_if_exists
              rescue_action_in_public_without_airbrake(request.env['fake_exception'])
            end
          end
        end

        def skip_user_agent?(env)
          begin
            user_agent = env["HTTP_USER_AGENT"]
            ::Airbrake.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
          rescue
            false
          end
        end

        def render_exception_with_airbrake(env,exception)
          controller = env['action_controller.instance']
          env['airbrake.error_id'] = Airbrake.notify_or_ignore(exception, controller.airbrake_request_data) unless skip_user_agent?(env)
          if defined?(controller.rescue_action_in_public_without_airbrake)
            env['fake_exception'] = exception
            define_proxy_method(controller.class)
            controller.class.action(:call_the_real_method_if_exists).call(env)
          else
            render_exception_without_airbrake(env,exception)
          end
        end
      end
    end
  end
end
