# La Cielo Cafe — production starter

This package is a secure-backend starter, not yet a finished production deployment. No external accounts are connected and no live orders or WhatsApp messages will be sent until you complete the setup and integrate the existing prototype's UI with Supabase.

## Files
- `demo-prototype-not-production.html`: your earlier prototype, retained for design reference only. It uses localStorage and demo password `demo123`; do not deploy it as the production site or collect real customer information with it.
- `config.example.js`: browser-safe Supabase project URL + publishable key template.
- `admin-login.html`: Supabase password login and an `admin_users` authorization check.
- `schema.sql`: database tables and Row Level Security policies for menu, orders, reviews, bookings and photo storage.
- `supabase/functions/notify-whatsapp/index.ts`: WhatsApp Cloud API notification function starter. Requires server-side secrets and a trusted order workflow before use.

## Step 1 — Create Supabase project
1. Sign in to Supabase and create a new project for La Cielo Cafe.
2. Save the database password in a password manager. Do not put it in GitHub.
3. Open Project Settings → API (or API Keys). Copy Project URL and the publishable key.
4. Copy `config.example.js` to `config.js` and fill in those two public values. `config.js` is safe only for the project URL and publishable key; never put a secret/service_role key in it.

## Step 2 — Create database
1. Open SQL Editor in the Supabase dashboard.
2. Review `schema.sql` and run it on the new, empty project.
3. Confirm tables exist: `admin_users`, `menu_items`, `orders`, `reviews`, `bookings`.
4. Confirm RLS is enabled on each table. Test with a non-admin session: it must not be able to select orders/bookings or modify menu items.

## Step 3 — Create the first admin account
1. In Supabase Authentication → Users, add the cafe owner's email as a user (set a strong unique password or send an invite, according to the options shown in your dashboard).
2. Copy the user's UUID.
3. In SQL Editor, run this after replacing the UUID:

```sql
insert into public.admin_users (user_id)
values ('PASTE-AUTH-USER-UUID-HERE');
```

4. Disable public sign-ups in Authentication settings if the project will only have admin users. Use password reset or a secure invitation flow for future admins.
5. `admin-login.html` verifies both successful Supabase authentication and membership in `admin_users`. It is a login starter only; the dashboard operations still need to be connected to the database.

## Step 4 — Test locally
For local testing, serve the folder with a static server rather than opening the HTML with `file://`. For example, if Python is installed, run from this folder:

```bash
python -m http.server 8000
```

Open `http://localhost:8000/admin-login.html`. Do not commit `config.js` if you prefer not to expose project metadata, and do not ever commit server-side secrets. The publishable key is designed for browser use, but its safety depends on correct RLS policies.

## Step 5 — Production website and GitHub Pages
1. Create a private development repository or a public site repository containing only the production frontend and `config.js` with the publishable key.
2. Enable GitHub Pages for the site branch/folder and test the deployed URL.
3. Add the exact deployed domain to Supabase Authentication → URL Configuration / allowed redirect URLs.
4. Before launch, remove the demo `demo123` login and localStorage order flows. Connect the public menu to `menu_items`, the order form to a validated order-creation flow, and the admin UI to authenticated Supabase queries.

## Important implementation tasks before real customers use it
- Order prices must be recalculated on the server/database from current menu prices. Never trust a customer-provided total or item price. The included schema stores a total but does not yet implement a trusted checkout function.
- Add rate limiting / CAPTCHA / abuse prevention for anonymous order and review submissions.
- Add an order-creation Edge Function that validates item IDs, quantities, current prices, availability, delivery details, and computes totals server-side before inserting an order. It should also trigger notifications reliably. Do not use the `notify-whatsapp` function as an unauthenticated public endpoint.
- Restrict CORS and add server-side validation before launch.
- Ensure phone numbers, delivery addresses and order history are visible only to authorized staff. Establish a retention policy for customer data.
- Configure WhatsApp Cloud API credentials and recipient phone number in Supabase Edge Function secrets, then test with a permitted recipient. Meta setup may require a business portfolio, WhatsApp Business Account, and approved sender. Provider fees and messaging rules may apply.
- Confirm the cafe owner has authorized use of their name, logo, photos and menu. Verify every item and price.
- The schema is a starting point; review it and test policies in a staging project before applying to a live project.

## Official references
- Supabase data security: https://supabase.com/docs/guides/database/secure-data
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Auth: https://supabase.com/docs/guides/auth
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- Meta WhatsApp Cloud API: https://developers.facebook.com/docs/whatsapp/cloud-api/overview
