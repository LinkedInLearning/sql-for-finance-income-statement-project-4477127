create materialized view account_cash as WITH purchase_dates as(
  select case
      when payment_method = 'cash' then payment_at
      else payment_at + interval '1 month'
    end as actual_payment_at,
    - sum(quantity * amount) as total_amount
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
revenue_dates as(
  select case
      when payment_method = 'cash' then payment_at
      else payment_at + interval '1 month'
    end as actual_payment_at,
    sum(quantity * price) as total_amount
  from sales
  group by case
      when payment_method = 'cash' then payment_at
      else payment_at + interval '1 month'
    end
),
revenue as(
  select date_part('year', actual_payment_at) as period_year,
    sum(total_amount) as total_amount
  from revenue_dates
  group by date_part('year', actual_payment_at)
),
loan_in as(
  select date_part('year', loan_at) as period_year,
    sum(value) as total_amount
  from loans
  group by date_part('year', loan_at)
),
expenses as(
  select date_part('year', payment_date) as period_year,
    - sum(amount) as total_amount
  from payments
  where payment_type in (
      'equipment',
      'wage',
      'rent',
      'utility',
      'tax',
      'loan',
      'interest'
    )
  group by date_part('year', payment_date)
),
cash_union as(
  select *
  from loan_in
  union all
  select *
  from expenses
  union all
  select *
  from purchase
  union all
  select *
  from revenue
),
cash_amount as(
  select period_year,
    sum(total_amount) as total_amount
  from cash_union
  group by period_year
)
select period_year,
  'Cash' as account,
  sum(total_amount) over(
    order by period_year
  ) as total_amount
from cash_amount