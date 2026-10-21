-- La Cielo Cafe production starter schema
-- Run in Supabase Dashboard > SQL Editor only after reviewing the project.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_cafe_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_cafe_admin() from public;
grant execute on function public.is_cafe_admin() to anon, authenticated;

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  description text not null default '' check (char_length(description) <= 1000),
  category text not null default 'Cafe',
  price_paise integer not null check (price_paise >= 0),
  image_path text,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (char_length(customer_name) between 1 and 120),
  phone text not null check (char_length(phone) between 7 and 20),
  fulfilment text not null check (fulfilment in ('pickup','delivery')),
  delivery_address text,
  customer_note text not null default '' check (char_length(customer_note) <= 1000),
  items jsonb not null check (jsonb_typeof(items) = 'array' and jsonb_array_length(items) between 1 and 50),
  total_paise integer not null check (total_paise >= 0),
  status text not null default 'new' check (status in ('new','accepted','preparing','ready','out_for_delivery','completed','cancelled')),
  notification_status text not null default 'pending' check (notification_status in ('pending','sent','failed','not_configured')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint delivery_requires_address check (fulfilment <> 'delivery' or coalesce(length(trim(delivery_address)),0) >= 8)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (char_length(customer_name) between 1 and 100),
  stars smallint not null check (stars between 1 and 5),
  review_text text not null check (char_length(review_text) between 8 and 1500),
  approved boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null check (char_length(customer_name) between 1 and 120),
  phone text not null check (char_length(phone) between 7 and 20),
  booking_date date not null,
  booking_time text not null,
  party_size smallint not null check (party_size between 1 and 30),
  notes text not null default '' check (char_length(notes) <= 1000),
  status text not null default 'pending' check (status in ('pending','confirmed','declined','completed')),
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.reviews enable row level security;
alter table public.bookings enable row level security;

-- Admin identity table is not directly readable/writable from clients.
revoke all on public.admin_users from anon, authenticated;

-- Anyone can read currently available menu items; only approved reviews are public.
grant select on public.menu_items to anon, authenticated;
grant select, insert, update, delete on public.menu_items to authenticated;
create policy "public reads available menu" on public.menu_items for select to anon, authenticated using (is_available = true or (select public.is_cafe_admin()));
create policy "admins insert menu" on public.menu_items for insert to authenticated with check ((select public.is_cafe_admin()));
create policy "admins update menu" on public.menu_items for update to authenticated using ((select public.is_cafe_admin())) with check ((select public.is_cafe_admin()));
create policy "admins delete menu" on public.menu_items for delete to authenticated using ((select public.is_cafe_admin()));

-- Public customers can submit orders but cannot read, edit, or delete orders.
grant insert on public.orders to anon, authenticated;
grant select, update on public.orders to authenticated;
create policy "customers submit orders" on public.orders for insert to anon, authenticated with check (status = 'new' and notification_status = 'pending');
create policy "admins read orders" on public.orders for select to authenticated using ((select public.is_cafe_admin()));
create policy "admins update orders" on public.orders for update to authenticated using ((select public.is_cafe_admin())) with check ((select public.is_cafe_admin()));

-- Public review submissions are unapproved until an admin moderates them.
grant select, insert, update, delete on public.reviews to anon, authenticated;
create policy "public reads approved reviews" on public.reviews for select to anon, authenticated using (approved = true or (select public.is_cafe_admin()));
create policy "public submits unapproved review" on public.reviews for insert to anon, authenticated with check (approved = false);
create policy "admins moderate reviews" on public.reviews for update to authenticated using ((select public.is_cafe_admin())) with check ((select public.is_cafe_admin()));
create policy "admins delete reviews" on public.reviews for delete to authenticated using ((select public.is_cafe_admin()));

-- Public booking requests; only admins can read/update bookings.
grant insert on public.bookings to anon, authenticated;
grant select, update on public.bookings to authenticated;
create policy "customers request bookings" on public.bookings for insert to anon, authenticated with check (status = 'pending');
create policy "admins read bookings" on public.bookings for select to authenticated using ((select public.is_cafe_admin()));
create policy "admins update bookings" on public.bookings for update to authenticated using ((select public.is_cafe_admin())) with check ((select public.is_cafe_admin()));

-- Storage bucket for cafe images. Create bucket manually as public named 'cafe-photos'
-- (public reads are okay for public website photos; uploads/updates/deletes are admin-only).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cafe-photos', 'cafe-photos', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
create policy "public can view cafe photos" on storage.objects for select to anon, authenticated using (bucket_id = 'cafe-photos');
create policy "admins upload cafe photos" on storage.objects for insert to authenticated with check (bucket_id = 'cafe-photos' and (select public.is_cafe_admin()));
create policy "admins update cafe photos" on storage.objects for update to authenticated using (bucket_id = 'cafe-photos' and (select public.is_cafe_admin())) with check (bucket_id = 'cafe-photos' and (select public.is_cafe_admin()));
create policy "admins delete cafe photos" on storage.objects for delete to authenticated using (bucket_id = 'cafe-photos' and (select public.is_cafe_admin()));
