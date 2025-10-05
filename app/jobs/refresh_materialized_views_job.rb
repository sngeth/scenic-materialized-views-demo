class RefreshMaterializedViewsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting materialized views refresh..."

    start_time = Time.now

    DailySale.refresh
    Rails.logger.info "  ✓ DailySale refreshed"

    TopProduct.refresh
    Rails.logger.info "  ✓ TopProduct refreshed"

    UserEngagement.refresh
    Rails.logger.info "  ✓ UserEngagement refreshed"

    CategoryRevenue.refresh
    Rails.logger.info "  ✓ CategoryRevenue refreshed"

    elapsed_time = Time.now - start_time
    Rails.logger.info "Materialized views refresh completed in #{elapsed_time.round(2)}s"
  end
end
