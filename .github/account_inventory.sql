create materialized view account_inventory as with purchase_dates as(
  select case
      when payment_method = 'cash' then payment_at
      else payment_at + interval '1 month'
    end as actual_payment_at,
    sum(quantity * amount) as total_amount
  from purchases
  group by case
      when payment_method = 'cash' then payment_at
      else payment_at + interval '1 month'
    end
),
purchase as(
  select date_part('year', actual_payment_at) as period_year,
    sum(total_amount) as total_amount
  from purchase_dates
  group by date_part('year', actual_payment_at)
),
product_price as(
  select distinct product_name,
    amount
  from purchases
),
sale as(
  select date_part('year', payment_at) as period_year,
    - sum(s.quantity * p.amount) as total_amount
  from sales s
    left join product_price p on s.product_name = p.product_name
  group by date_part('year', payment_at)
),
inventory_union as(
  select *
  from purchase
  union all
  select *
  from sale
),
inventory_sum aS(
  select period_year,
    sum(total_amount) as total_amount
  from inventory_union
  group by period_year
),
inventory as(
  select period_year,
    sum(total_amount) over(
      order by period_year
    ) as total_amount
  from inventory_sum
)
select *
from inventory