class DashboardController < ApplicationController
  def index
    @daily_sales = DailySale.order(sale_date: :desc).limit(30)
    @top_products = TopProduct.order(total_revenue: :desc).limit(10)
    @category_revenues = CategoryRevenue.order(total_revenue: :desc)
    @top_users = UserEngagement.order(lifetime_value: :desc).limit(10)

    @total_revenue = @daily_sales.sum(&:total_revenue)
    @total_orders = @daily_sales.sum(&:total_orders)

    # Performance stats
    @view_count = {
      daily_sales: DailySale.count,
      top_products: TopProduct.count,
      user_engagements: UserEngagement.count,
      category_revenues: CategoryRevenue.count
    }
  end
end
