 create table if not exists public.location_points (
  id bigserial primary key,
  ts timestamptz not null,
  lat double precision not null,
  lng double precision not null,
  accuracy double precision,
  source text,
  meta jsonb default '{}'::jsonb
);

create index if not exists location_points_ts_idx on public.location_points (ts);

comment on table public.location_points is '轨迹定位点明细';
comment on column public.location_points.id is '主键';
comment on column public.location_points.ts is '定位时间';
comment on column public.location_points.lat is '纬度';
comment on column public.location_points.lng is '经度';
comment on column public.location_points.accuracy is '精度';
comment on column public.location_points.source is '数据来源';
comment on column public.location_points.meta is '扩展字段';
