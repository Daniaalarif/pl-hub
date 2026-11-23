-- PL Hub database setup
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Safe to run more than once.

-- ---------- Tables ----------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  asin text not null default '',
  url text not null default '',
  category_id uuid references public.categories(id) on delete set null,
  status text not null default 'Idea',
  price numeric,
  cost numeric,
  fees numeric,
  sales numeric,
  image_path text,
  standout text not null default '',
  weaknesses text not null default '',
  title text not null default '',
  bullet1 text not null default '',
  bullet2 text not null default '',
  bullet3 text not null default '',
  bullet4 text not null default '',
  bullet5 text not null default '',
  description text not null default '',
  keywords text not null default '',
  notes text not null default '',
  competitors jsonb not null default '[]'::jsonb,
  mockups jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  source text not null default 'Alibaba',
  wechat text not null default '',
  alibaba text not null default '',
  contact text not null default '',
  phone text not null default '',
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.samples (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  status text not null default 'On the way',
  sample_cost text not null default '',
  unit_price text not null default '',
  moq text not null default '',
  quality integer,
  tracking text not null default '',
  eta date,
  arrived_on date,
  decided_on date,
  notes text not null default '',
  photos jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.thoughts (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  category_id uuid references public.categories(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------- Security: only signed-in team members can read or write ----------
do $$
declare t text;
begin
  foreach t in array array['categories','products','suppliers','samples','thoughts'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "team full access" on public.%I', t);
    execute format('create policy "team full access" on public.%I for all to authenticated using (true) with check (true)', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;

-- ---------- Photo storage ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('pl-images', 'pl-images', true, 15728640, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do nothing;

drop policy if exists "pl-images team upload" on storage.objects;
drop policy if exists "pl-images team update" on storage.objects;
drop policy if exists "pl-images team delete" on storage.objects;
drop policy if exists "pl-images team read" on storage.objects;
create policy "pl-images team upload" on storage.objects for insert to authenticated with check (bucket_id = 'pl-images');
create policy "pl-images team update" on storage.objects for update to authenticated using (bucket_id = 'pl-images');
create policy "pl-images team delete" on storage.objects for delete to authenticated using (bucket_id = 'pl-images');
create policy "pl-images team read" on storage.objects for select to authenticated using (bucket_id = 'pl-images');

-- ---------- Starting data (only added if empty) ----------
insert into public.categories (name, sort)
select v.name, v.sort from (values
  ('Home & Kitchen', 1), ('Home & Garden', 2), ('Lighting', 3), ('Fashion accessories', 4),
  ('Pet Supplies', 5), ('Health & Personal Care', 6), ('DIY & Tools', 7), ('Sports & Outdoors', 8),
  ('Grocery', 9), ('Toys & Games', 10), ('Automotive', 11)
) as v(name, sort)
where not exists (select 1 from public.categories);

insert into public.products (name, category_id, status, notes)
select 'TCG card holders (semi-rigid, rigid & soft sleeves)', c.id, 'Researching', 'For grading submissions and storage.'
from public.categories c
where c.name = 'Toys & Games'
  and not exists (select 1 from public.products);
