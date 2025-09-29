--Revenue
select t.event_date ,
            product_name,
            sum(revenue) as TR
from mobile_game.transactions t 
group by 1,2



--Last Click Атрибуция
--Находим первую игровую сессию для пользователя
WITH first_start AS (
    SELECT 
        user_id,
        MIN(s.session_start_time) AS first_start
              FROM 
        mobile_game.sessions s
    GROUP BY 
        user_id
),
last_click AS (
    SELECT 
        ut.user_id,
        ut.touch_date,
        ut.channel
    FROM 
        mobile_game.users_touches ut
    JOIN
    GROUP BY 
        ut.user_id, ut.channel
)

SELECT 
    us.user_id,
    us.first_start,
    uc.last_click,
    uc.channel
FROM 
    user_sessions us
JOIN 
    user_clicks uc ON us.user_id = uc.user_id
WHERE 
    uc.last_click <= us.first_start;

	

		


--DAU
with first_start as (
    select 
        user_id,
        min(s.session_start_time) as first_start
    from 
        mobile_game.sessions s
    group by
        user_id
),
last_click as (
    -- находим последний клик для первой сессии
    select 
        t.user_id, 
        t.channel
    from (
        select 
            ut.user_id, 
            ut.channel, 
            ut.touch_date,
            row_number() over (partition by ut.user_id order by ut.touch_date desc) as rn
        from 
            mobile_game.users_touches ut
        join 
            first_start fs on ut.user_id = fs.user_id
        where 
            ut.touch_date <= fs.first_start
    ) t
    where 
        t.rn = 1) -- только последний клик      
select 
	s.session_start_time::date as event_date,
	count (distinct s.user_id) as users, 
	lc.channel
from mobile_game.sessions s 
join last_click lc on s.user_id = lc.user_id
group by s.session_start_time::date, lc.channel

--Channel Revenue
with first_start as (
    select 
        user_id,
        min(s.session_start_time) as first_start
    from 
        mobile_game.sessions s
    group by
        user_id
),
last_click as (
    -- находим последний клик для первой сессии
    select 
        t.user_id, 
        t.channel
    from (
        select 
            ut.user_id, 
            ut.channel, 
            ut.touch_date,
            row_number() over (partition by ut.user_id order by ut.touch_date desc) as rn
        from 
            mobile_game.users_touches ut
        join 
            first_start fs on ut.user_id = fs.user_id
        where 
            ut.touch_date <= fs.first_start
    ) t
    where 
        t.rn = 1) -- только последний клик   
select tr.event_date ,
            lc.channel,
            sum(revenue) as TR
from mobile_game.transactions tr 
join last_click lc on tr.user_id = lc.user_id
group by 1,2

--Retention
with first_start as (
    select 
        user_id,
        min(s.session_start_time) as first_start
    from 
        mobile_game.sessions s
    group by
        user_id
),
last_click as (
    -- находим последний клик для первой сессии
    select 
        t.user_id, 
        t.channel
    from (
        select 
            ut.user_id, 
            ut.channel, 
            ut.touch_date,
            row_number() over (partition by ut.user_id order by ut.touch_date desc) as rn
        from 
            mobile_game.users_touches ut
        join 
            first_start fs on ut.user_id = fs.user_id
        where 
            ut.touch_date <= fs.first_start
    ) t
    where 
        t.rn = 1
)
select
    (s.session_start_time::date - ui.user_start_date) as active_day,
    lc.channel,
    count(*) as retention_count
from 
    mobile_game.sessions s 
join 
    mobile_game.user_info ui on s.user_id = ui.user_id
join 
    last_click lc on s.user_id = lc.user_id  
where
    s.session_start_time::date >= ui.user_start_date
group by 
    active_day, lc.channel; 

--Daily Conversion 
with first_start as (
    select 
        user_id,
        min(s.session_start_time) as first_start
    from 
        mobile_game.sessions s
    group by
        user_id
),
last_click as (
    -- находим последний клик для первой сессии
    select 
        t.user_id, 
        t.channel
    from (
        select 
            ut.user_id, 
            ut.channel, 
            ut.touch_date,
            row_number() over (partition by ut.user_id order by ut.touch_date desc) as rn
        from 
            mobile_game.users_touches ut
        join 
            first_start fs on ut.user_id = fs.user_id
        where 
            ut.touch_date <= fs.first_start
    ) t
    where 
        t.rn = 1
)
select
	tr.event_date, 
	lc.channel,
	sum(tr.revenue) / count(distinct(tr.user_id)) as daily_conversion
from mobile_game.transactions tr
join last_click lc on tr.user_id = lc.user_id
join mobile_game.sessions s on tr.user_id = s.user_id
where  s.session_start_time::date = tr.event_date
group by 1,2

--ARPPU 
with first_start as (
    select 
        user_id,
        min(s.session_start_time) as first_start
    from 
        mobile_game.sessions s
    group by
        user_id
),
last_click as (
    -- находим последний клик для первой сессии
    select 
        t.user_id, 
        t.channel
    from (
        select 
            ut.user_id, 
            ut.channel, 
            ut.touch_date,
            row_number() over (partition by ut.user_id order by ut.touch_date desc) as rn
        from 
            mobile_game.users_touches ut
        join 
            first_start fs on ut.user_id = fs.user_id
        where 
            ut.touch_date <= fs.first_start
    ) t
    where 
        t.rn = 1
)
select
	tr.event_date, 
	lc.channel,
	sum(tr.revenue) / count(distinct(tr.user_id)) as arppu
from mobile_game.transactions tr
join last_click lc on tr.user_id = lc.user_id
where tr.revenue > 0
group by 1,2

--quantity of sales
--Рассчитаем, чтобы понять, как влияют предложения типа sale на наши продажи
select 	t.event_date, 
		t.product_name,
		sum(t. quantity) 
from mobile_game.transactions t
group by 1,2

--average cost of sale type
select 	t.product_name,
		sum(t.revenue) / sum(t. quantity) as avg_cost
from mobile_game.transactions t
group by 1

--total ammount of revenue from 2023-03-10 to 2023-10-23
select 
		t.product_name,
		sum(t.revenue) as total_sale
from mobile_game.transactions t
where t.event_date between '2023-03-10' and '2023-10-23' 
group by 1

--need in sales 
with first_start as (
    select 
        user_id,
        min(s.session_start_time) as first_start
    from 
        mobile_game.sessions s
    group by
        user_id
),
last_click as (
    -- находим последний клик для первой сессии
    select 
        t.user_id, 
        t.channel
    from (
        select 
            ut.user_id, 
            ut.channel, 
            ut.touch_date,
            row_number() over (partition by ut.user_id order by ut.touch_date desc) as rn
        from 
            mobile_game.users_touches ut
        join 
            first_start fs on ut.user_id = fs.user_id
        where 
            ut.touch_date <= fs.first_start
    ) t
    where 
        t.rn = 1
)
select 	lc.channel,
		t.product_name,
		sum(t.quantity) / count (distinct lc.user_id) as avg_buy_quantity
from mobile_game.transactions t 
join last_click lc on t.user_id = lc.user_id
group by 2,1


