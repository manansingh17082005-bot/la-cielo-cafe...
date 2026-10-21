# La Cielo Cafe — Admin Panel Starter

This is a responsive admin-panel starter for the existing La Cielo static website. It includes:
- Supabase Auth admin login with admin allow-list check
- Forgot-password email flow and reset-password page
- Cafe contact/business settings form
- Menu item create/edit/availability controls
- Orders, bookings and reviews table/status management
- Responsive layout for desktop and mobile

## Important status
This is a starter, not a fully tested production deployment. It does not automatically merge itself into the existing `index.html`, and it does not configure your Supabase project for you. Customer-facing order and booking forms must be integrated with the same schema before going live. Orders are deliberately constrained by the SQL policy to `total_paise = 0`; do not remove this guard or accept payments until a trusted server-side function validates menu item IDs, quantities, prices, delivery fees, and totals. Add rate limiting/CAPTCHA and test the database policies before public launch.

## 1. Put files in the GitHub repository root
Copy these files into the root of your existing repository (alongside `index.html`):
- `admin.html`
- `admin-login.html` (replace the old starter version)
- `reset-password.html`
- `admin.css`
- `config.example.js`
- `supabase/schema.sql`

Keep your current `index.html`. Do not overwrite it with the prototype unless you intentionally want that preview.

## 2. Configure Supabase
1. Create/open the cafe project in https://supabase.com/dashboard.
2. In SQL Editor, run `supabase/schema.sql` once on a new/empty project. Review first if the project already has tables or policies.
3. In Authentication → Users, create the admin user with their real email.
4. Copy the user's UUID from the user details.
5. In SQL Editor, run this with the real UUID substituted:

```sql
insert into public.admin_users (user_id)
values ('PASTE-ADMIN-USER-UUID-HERE');
```

6. Copy `config.example.js` to a new file named `config.js`. Put the Supabase Project URL and publishable/anon key in it. Never put a secret/service-role key in browser files.
7. In Supabase Authentication URL Configuration, add your published website URL to Site URL / Redirect URLs, including the reset page URL. Example pattern: `https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/reset-password.html`.
8. Configure Supabase email delivery for reliable password reset emails. Test the reset link from the deployed site.

## 3. GitHub Pages
In repository Settings → Pages, choose Deploy from a branch, branch `main`, folder `/(root)`, then Save. Commit and push files to publish. The admin URL is `/admin-login.html`; do not add a link to it in the customer navigation. Hiding the link is not security—Supabase auth and RLS are the actual protections.

## 4. Commit from Codespaces
Run one command at a time:

```bash
git add admin.html admin-login.html reset-password.html admin.css config.example.js supabase/schema.sql README.md
git commit -m "Add La Cielo admin dashboard and password reset"
git push
```

## 5. Features / notes
- Dashboard uses `cafe_settings` singleton row id `1`; settings changes save to Supabase.
- Menu manager uses `menu_items` table.
- Orders/bookings/reviews pages show records and allow status updates when records exist.
- The public website must be integrated with `cafe_settings`, `menu_items`, `orders`, `bookings`, and `reviews` to reflect these changes and collect records.
- `config.js` is intentionally not included because it contains your project-specific public config. The publishable/anon key is intended for browser use with RLS enabled; secret/service-role keys are not.
- This starter uses the Supabase JS CDN and Google Fonts; these require internet access in the browser.
