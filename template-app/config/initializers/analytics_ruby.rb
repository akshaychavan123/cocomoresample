Analytics =
  if ENV['RUBY_ANALYTICS_TOKEN'].present?
    Segment::Analytics.new({
                             write_key: ENV['RUBY_ANALYTICS_TOKEN'],
                             on_error: Proc.new { |status, msg| print msg }
                           })
  else
    class FakeSegment
      def track(**args)
        Rails.logger.error "RUBY_ANALYTICS_TOKEN environment variable missing. Could not send data to Segment:"
        Rails.logger.error args.inspect
      end
    end

    FakeSegment.new
  end
