class NyDownstreamManager
  def initialize
    
  end
  
  def create_connection
    #CLŠJŽn
    t_cl = Thread.new do
      logger.info "Connecting to #{@node.host}:#{@node.port}..."
      @sock = nil
      timeout(5) do
        @sock = @node.connect
        logger.debug " -> OK."
      end
      proc = NyCmdProcessor.new(@sock)
      proc.send_auth
      proc.recv_auth
      t1 = Thread.new{ proc.start_cmdloop_thread }
      t2 = Thread.new{ proc.start_send_thread }
      t1.join
      t2.join
    end
  end
end
