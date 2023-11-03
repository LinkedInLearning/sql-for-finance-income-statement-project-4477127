create table calendar as

select date::date as calendar_at
       , extract('year' from date) as year
          , extract('month' from date) as month
from generate_series(date '2021-01-01',
                       date '2050-12-31',
                       interval '1 month')
as t(date);

