class CrimsonCleanup
  class << self
    RETRY_CONDITIONS = [
      Proc.new { |job| job['exception'] == 'Net::HTTPBadResponse' },
      Proc.new { |job| job['exception'] == 'Resque::DirtyExit' },
      Proc.new { |job| job['exception'] == 'NoMemoryError' },
      Proc.new { |job| job['exception'] == 'EOFError' },
      Proc.new { |job| job['exception'] == 'Errno::ECONNRESET' },
      Proc.new { |job| job['exception'] == 'Errno::EPIPE' },
      Proc.new { |job| job['exception'] == 'ActiveRecord::DeadlockVictim' },
      Proc.new { |job| job['error'].include?('timed out') },
      Proc.new { |job| job['error'].include?('Cannot allocate memory') },
      Proc.new { |job| job['error'].include?('Adaptive Server is unavailable') },
    ]

    def clean!
      requeued = 0
      RETRY_CONDITIONS.each do |condition|
        requeued += cleaner.requeue(true) { |job| condition.call(job) }
      end
      requeued
    end

    private

    def cleaner
      @cleaner ||= Resque::Plugins::ResqueCleaner.new
    end
  end
end
