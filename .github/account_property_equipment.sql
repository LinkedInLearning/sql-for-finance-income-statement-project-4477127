create materialized view account_property_equipment as with depreciation_dates as(
  select id,
    calendar_at,
    year as period_year,
    case
      when year = date_part('year', payment_date + interval '10 years')
      and month = date_part('month', payment_date) then 1
      when month = 12 then 1
      else 0
    end as flag_1_year,
    amount / count(*) over(partition by id) as installments
  from calendar
    cross join payments
  where calendar_at >= payment_date
    and calendar_at <= payment_date + interval '10 years'
    and payment_type = 'equipment'
    and id = 66
),
depreciation_sum as(
  select *,
    sum(installments) over(
      partition by id
      order by calendar_at
    ) as depreciation_amount
  from depreciation_dates
),
depreciation as(
  select period_year,
    sum(depreciation_amount) as total_amount
  from depreciation_sum
  group by period_year
),
ple_purchase as(
  select date_part('year', payment_date) as period_year,
    sum(amount) as total_amount
  from payments
  where payment_type in ('equipment')
  group by date_part('year', payment_date)
),
ple_union as(
  select *
  from depreciation
  union all
  select *
  from ple_purchase
),
ple_sum as(
  select period_year,
    sum(total_amount) as total_amount
  from ple_union
  group by period_year
),
property_equipment as(
  select period_year,
    'Property Land & Equipment' as account,
    round(
      sum(total_amount) over(
        order by period_year
      ),
      2
    ) as total_amount
  from ple_sum
)
select *
from property_equipment