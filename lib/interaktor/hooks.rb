# Internal: Methods relating to supporting hooks around Interaktor invocation.
module Interaktor::Hooks
  # Internal: Install Interaktor's behavior in the given class.
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  # Internal: Interaktor::Hooks class methods.
  module ClassMethods
    # Public: Declare hooks to run around Interaktor invocation. The around
    # method may be called multiple times; subsequent calls append declared
    # hooks to existing around hooks.
    #
    # hooks - Zero or more Symbol method names representing instance methods
    #         to be called around interaktor invocation. Each instance method
    #         invocation receives an argument representing the next link in
    #         the around hook chain.
    # block - An optional block to be executed as a hook. If given, the block
    #         is executed after methods corresponding to any given Symbols.
    #
    # Examples
    #
    #   class MyInteraktor
    #     include Interaktor
    #
    #     around :time_execution
    #
    #     around do |interaktor|
    #       puts "started"
    #       interaktor.call
    #       puts "finished"
    #     end
    #
    #     def call
    #       puts "called"
    #     end
    #
    #     private
    #
    #     def time_execution(interaktor)
    #       context.start_time = Time.now
    #       interaktor.call
    #       context.finish_time = Time.now
    #     end
    #   end
    #
    # Returns nothing.
    def around(*hooks, &block)
      hooks << block if block
      hooks.each { |hook| around_hooks.push(hook) }
    end

    # Public: Declare hooks to run before Interaktor invocation. The before
    # method may be called multiple times; subsequent calls append declared
    # hooks to existing before hooks.
    #
    # hooks - Zero or more Symbol method names representing instance methods
    #         to be called before interaktor invocation.
    # block - An optional block to be executed as a hook. If given, the block
    #         is executed after methods corresponding to any given Symbols.
    #
    # Examples
    #
    #   class MyInteraktor
    #     include Interaktor
    #
    #     before :set_start_time
    #
    #     before do
    #       puts "started"
    #     end
    #
    #     def call
    #       puts "called"
    #     end
    #
    #     private
    #
    #     def set_start_time
    #       context.start_time = Time.now
    #     end
    #   end
    #
    # Returns nothing.
    def before(*hooks, &block)
      hooks << block if block
      hooks.each { |hook| before_hooks.push(hook) }
    end

    # Public: Declare hooks to run after Interaktor invocation. The after
    # method may be called multiple times; subsequent calls prepend declared
    # hooks to existing after hooks.
    #
    # hooks - Zero or more Symbol method names representing instance methods
    #         to be called after interaktor invocation.
    # block - An optional block to be executed as a hook. If given, the block
    #         is executed before methods corresponding to any given Symbols.
    #
    # Examples
    #
    #   class MyInteraktor
    #     include Interaktor
    #
    #     after :set_finish_time
    #
    #     after do
    #       puts "finished"
    #     end
    #
    #     def call
    #       puts "called"
    #     end
    #
    #     private
    #
    #     def set_finish_time
    #       context.finish_time = Time.now
    #     end
    #   end
    #
    # Returns nothing.
    def after(*hooks, &block)
      hooks << block if block
      hooks.each { |hook| after_hooks.unshift(hook) }
    end

    def ensure_hook(*hooks, &block)
      hooks << block if block
      hooks.each { |hook| ensure_hooks.push(hook) }
    end

    # Internal: An Array of declared hooks to run around Interaktor
    # invocation. The hooks appear in the order in which they will be run.
    #
    # Examples
    #
    #   class MyInteraktor
    #     include Interaktor
    #
    #     around :time_execution, :use_transaction
    #   end
    #
    #   MyInteraktor.around_hooks
    #   # => [:time_execution, :use_transaction]
    #
    # Returns an Array of Symbols and Procs.
    def around_hooks
      @around_hooks ||= []
    end

    # Internal: An Array of declared hooks to run before Interaktor
    # invocation. The hooks appear in the order in which they will be run.
    #
    # Examples
    #
    #   class MyInteraktor
    #     include Interaktor
    #
    #     before :set_start_time, :say_hello
    #   end
    #
    #   MyInteraktor.before_hooks
    #   # => [:set_start_time, :say_hello]
    #
    # Returns an Array of Symbols and Procs.
    def before_hooks
      @before_hooks ||= []
    end

    # Internal: An Array of declared hooks to run before Interaktor
    # invocation. The hooks appear in the order in which they will be run.
    #
    # Examples
    #
    #   class MyInteraktor
    #     include Interaktor
    #
    #     after :set_finish_time, :say_goodbye
    #   end
    #
    #   MyInteraktor.after_hooks
    #   # => [:say_goodbye, :set_finish_time]
    #
    # Returns an Array of Symbols and Procs.
    def after_hooks
      @after_hooks ||= []
    end

    def ensure_hooks
      @ensure_hooks ||= []
    end
  end

  private

  # Internal: Run around, before and after hooks around yielded execution. The
  # required block is surrounded with hooks and executed.
  #
  # Examples
  #
  #   class MyProcessor
  #     include Interaktor::Hooks
  #
  #     def process_with_hooks
  #       with_hooks do
  #         process
  #       end
  #     end
  #
  #     def process
  #       puts "processed!"
  #     end
  #   end
  #
  # Returns nothing.
  def with_hooks
    run_around_hooks do
      run_before_hooks
      yield
      run_after_hooks
    end
  ensure
    run_ensure_hooks
  end

  # Internal: Run around hooks.
  #
  # Returns nothing.
  def run_around_hooks(&block)
    self.class.around_hooks.reverse.inject(block) { |chain, hook|
      proc { run_hook(hook, chain) }
    }.call
  end

  # Internal: Run before hooks.
  #
  # Returns nothing.
  def run_before_hooks
    run_hooks(self.class.before_hooks)
  end

  # Internal: Run after hooks.
  #
  # Returns nothing.
  def run_after_hooks
    run_hooks(self.class.after_hooks)
  end


  def run_ensure_hooks
    run_hooks(self.class.ensure_hooks)
  end

  # Internal: Run a colection of hooks. The "run_hooks" method is the common
  # interface by which collections of either before or after hooks are run.
  #
  # hooks - An Array of Symbol and Proc hooks.
  #
  # Returns nothing.
  def run_hooks(hooks)
    hooks.each { |hook| run_hook(hook) }
  end

  # Internal: Run an individual hook. The "run_hook" method is the common
  # interface by which an individual hook is run. If the given hook is a
  # symbol, the method is invoked whether public or private. If the hook is a
  # proc, the proc is evaluated in the context of the current instance.
  #
  # hook - A Symbol or Proc hook.
  # args - Zero or more arguments to be passed as block arguments into the
  #        given block or as arguments into the method described by the given
  #        Symbol method name.
  #
  # Returns nothing.
  def run_hook(hook, *args)
    hook.is_a?(Symbol) ? send(hook, *args) : instance_exec(*args, &hook)
  end
end
