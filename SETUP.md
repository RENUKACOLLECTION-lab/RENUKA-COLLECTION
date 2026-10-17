# Renuka Collection — shared product catalogue setup

This package updates the store so products and product images added from Admin are stored in Supabase, not just in the current browser. The public site can remain hosted on GitHub Pages for free.

## Files
- `index.html` — updated storefront and admin UI
- `supabase-config.js` — public project URL and anon/publishable key placeholders
- `supabase-schema.sql` — database table, access policies, image bucket, and starter products

## Setup (do these steps before publishing)
1. Create a project at https://supabase.com/ and open its dashboard.
2. Open **SQL Editor**, create a query, paste all of `supabase-schema.sql`, and run it.
3. In Supabase **Project Settings → API** (or **Connect**), copy the Project URL and the public anon/publishable key. Do not copy a `service_role` or secret key.
4. Edit `supabase-config.js`: replace `https://YOUR_PROJECT_ID.supabase.co` and `YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY` with your actual values. These two public values are intended for browser use; RLS policies are what protect data.
5. In Supabase **Authentication → Users**, create the administrator account with an email and a strong password. Turn off public sign-ups if the dashboard offers that setting and you do not want visitors creating accounts.
6. Copy the administrator user's UUID from the Users page. In SQL Editor, run this, replacing the UUID with the actual user ID:

   `insert into public.admin_users (user_id) values ('PASTE-ADMIN-USER-UUID-HERE');`

7. Test locally or in a staging copy. Open the Admin button and sign in using that Supabase email/password. Add a test product and image. Open the site in a private/incognito window or another device and confirm the product appears there. Test edit/delete too.
8. Upload/commit `index.html`, `supabase-config.js`, and `supabase-schema.sql` to the same GitHub Pages folder that currently contains your `index.html`. Keep the image and config file names exactly as shown. Wait for GitHub Pages to deploy, then hard-refresh the live site.

## Important limitations in this starter
- Product details and product images are shared through Supabase. Product images are public to view; only admins can upload them.
- Store settings (including UPI ID) and order history/search are still stored locally in this browser in this starter. WhatsApp messages sent by customers are not automatically saved as central database orders. A follow-up database migration is needed to make settings and orders shared too.
- Old products that exist only in the old browser's `localStorage` are not automatically uploaded. Export them from the old site's Admin panel first, then add/import them to Supabase. This SQL inserts the eight sample products if they do not already exist.
- GitHub Pages itself cannot write to your repository files from a browser. Supabase is the shared online source of truth for products.
- Never place a Supabase service-role/secret key in `supabase-config.js` or any frontend file.
- Keep a backup before replacing the live `index.html`.

## If something fails
- If the storefront shows the setup-required banner, check `supabase-config.js` and ensure it is in the same published directory as `index.html`.
- If products load but admin changes fail, verify the signed-in user UUID exists in `admin_users` and that you ran the complete SQL script.
- If image upload fails, check that the `product-images` bucket and its storage policies exist and the file is JPG/PNG/WebP under 8 MB.
- Open browser DevTools → Console for detailed errors. Never share passwords or secret keys in screenshots.
