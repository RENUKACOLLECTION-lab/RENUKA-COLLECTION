-- Renuka Collection cloud product catalogue (run in Supabase SQL Editor).
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_store_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid()); $$;
revoke all on function public.is_store_admin() from public;
grant execute on function public.is_store_admin() to authenticated;

create table if not exists public.products (
  id text primary key,
  name text not null check (char_length(name) between 1 and 80),
  price numeric(10,2) not null check (price >= 0),
  weight_grams integer not null default 1 check (weight_grams between 1 and 35000),
  category text not null check (char_length(category) between 1 and 40),
  emoji text not null default '🛍️',
  image_url text,
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.products enable row level security;
drop policy if exists "Admins can read admin list" on public.admin_users;
create policy "Admins can read admin list" on public.admin_users for select to authenticated using (user_id = auth.uid());
drop policy if exists "Anyone can read active products" on public.products;
create policy "Anyone can read active products" on public.products for select to anon, authenticated using (is_active = true or public.is_store_admin());
drop policy if exists "Admins can insert products" on public.products;
create policy "Admins can insert products" on public.products for insert to authenticated with check (public.is_store_admin());
drop policy if exists "Admins can update products" on public.products;
create policy "Admins can update products" on public.products for update to authenticated using (public.is_store_admin()) with check (public.is_store_admin());
drop policy if exists "Admins can delete products" on public.products;
create policy "Admins can delete products" on public.products for delete to authenticated using (public.is_store_admin());
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant select on public.admin_users to authenticated;

-- Public product images; only an authorized store admin may upload, update, or delete.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 8388608, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 8388608, allowed_mime_types = array['image/jpeg','image/png','image/webp'];
drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images" on storage.objects for select to anon, authenticated using (bucket_id = 'product-images');
drop policy if exists "Admins can upload product images" on storage.objects;
create policy "Admins can upload product images" on storage.objects for insert to authenticated with check (bucket_id = 'product-images' and public.is_store_admin());
drop policy if exists "Admins can update product images" on storage.objects;
create policy "Admins can update product images" on storage.objects for update to authenticated using (bucket_id = 'product-images' and public.is_store_admin()) with check (bucket_id = 'product-images' and public.is_store_admin());
drop policy if exists "Admins can delete product images" on storage.objects;
create policy "Admins can delete product images" on storage.objects for delete to authenticated using (bucket_id = 'product-images' and public.is_store_admin());

-- Optional initial products. Existing rows are not overwritten.
insert into public.products (id,name,price,weight_grams,category,emoji,description) values
('b7000-25','B-7000 Glue 25 ml',50,35,'Craft Supplies','🧴','Precision craft adhesive for DIY and repair projects.'),
('b7000-110','B-7000 Glue 110 ml',100,110,'Craft Supplies','🧴','Larger bottle for bigger crafting projects.'),
('glue-gun','Glue Gun',325,250,'Craft Supplies','🛠️','A handy tool for craft and decoration work.'),
('shills-wipes','Shills Wipes',99,100,'Essentials','🧻','Convenient wipes for everyday use.'),
('craft-thread','Craft Thread',20,20,'Sewing','🧵','Useful thread for stitching and creative projects.'),
('needles','Needles',10,10,'Sewing','🪡','Needles for sewing and handcrafts.'),
('fabric-glue','Fabric Glue',40,40,'Craft Supplies','🧴','For fabric crafts and small DIY projects.'),
('canvas','Craft Canvas',30,100,'Art Supplies','🎨','A surface for painting and creative work.')
on conflict (id) do nothing;
