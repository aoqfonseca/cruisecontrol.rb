ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'mocha'
require 'ostruct'
require 'stringio'
require 'xmlsimple'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true

class ActiveSupport::TestCase
  def assert_raise_with_message(types, matcher, message = nil, &block)
    args = [types].flatten + [message]
    exception = assert_raise(*args, &block)
    assert_match matcher, exception.message, message
  end
  
  def assert_false(expression)
    assert_equal false, expression
  end
  
  def in_total_sandbox(&block)
    in_sandbox do |sandbox|
      @dir = File.expand_path(sandbox.root)
      @stdout = "#{@dir}/stdout"
      @stderr = "#{@dir}/stderr"
      @prompt = "#{@dir} #{Platform.user}$"
      yield(sandbox)
    end
  end
  
  def with_sandbox_project(&block)
    in_total_sandbox do |sandbox|
      FileUtils.mkdir_p("#{sandbox.root}/work/.svn")
      
      project = Project.new(:name => 'my_project')
      project.path = sandbox.root
      
      yield(sandbox, project)
    end
  end
  
  def create_project_stub(name, last_complete_build_status = 'failed', last_five_builds = [])
    project = Object.new
    project.stubs(:name).returns(name)
    project.stubs(:last_complete_build_status).returns(last_complete_build_status)
    project.stubs(:last_five_builds).returns(last_five_builds)
    project.stubs(:builder_state_and_activity).returns('building')
    project.stubs(:last_build).returns(last_five_builds.last)
    project.stubs(:builder_error_message).returns('')
    project.stubs(:to_param).returns(name)
    project.stubs(:path).returns('.')
    project.stubs(:builder_down?).returns(false)
    project.stubs(:can_build_now?).returns(true)
    
    project.stubs(:last_complete_build).returns(nil)
    last_five_builds.reverse.each do |build|
      project.stubs(:last_complete_build).returns(build) unless build.incomplete?
    end
    
    project
  end
  
  def create_build_stub(label, status, time = Time.at(0))
    build = Object.new
    build.stubs(:label).returns(label)
    build.stubs(:abbreviated_label).returns(label)
    build.stubs(:status).returns(status)
    build.stubs(:time).returns(time)
    build.stubs(:failed?).returns(status == 'failed')
    build.stubs(:successful?).returns(status == 'success')
    build.stubs(:incomplete?).returns(status == 'incomplete')
    build.stubs(:changeset).returns("bobby checked something in")
    build.stubs(:brief_error).returns(nil)
    build
  end
end

class File
  def inspect
    "File(#{path})"
  end
end
