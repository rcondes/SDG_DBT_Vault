-- Validamos que el teléfono solo contenga caracteres permitidos
-- Caracteres permitidos en regex: 0-9 (números), \- (guiones), \s (espacios), \+ (signo más), \(\) (paréntesis)

select 
    customer_id, 
    phone
from {{ ref('stg_customer') }}
where phone is not null 
  and phone != ''  
  and regexp_like(phone, '[^0-9\+\(\)\s\\-]')