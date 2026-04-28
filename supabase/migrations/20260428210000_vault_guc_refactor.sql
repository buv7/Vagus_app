-- VAULT GUC refactor: switch vault_encrypt_text / vault_decrypt_text
-- from current_setting('app.vault_data_key') to vault.decrypted_secrets lookup.
--
-- Why: Supabase blocks ALTER DATABASE for non-superusers (42501 permission denied),
-- so the GUC was never set. Helpers deployed via PR #6 throw on every call:
-- "vault_encrypt_text: app.vault_data_key is not set".
--
-- The 256-bit hex key was provisioned via vault.create_secret on staging
-- (secret name 'app_vault_data_key', secret ID 670d52fa-0023-4236-96bd-da9b55c64da5,
-- decisions.md 21:55 UTC). Prod requires the same secret to be created before
-- this refactor unblocks anything there — see ROLLOUT block at bottom.
--
-- Blast radius: 0 callers today (medical-data domain agents are still in PR
-- review or BLOCKED). Refactor is preemptive infra fix.

create or replace function public.vault_encrypt_text(plaintext text)
returns bytea
language plpgsql
security definer
set search_path = public, vault
as $$
declare
  v_key text;
begin
  if plaintext is null then
    return null;
  end if;

  select decrypted_secret
    into v_key
    from vault.decrypted_secrets
   where name = 'app_vault_data_key'
   limit 1;

  if v_key is null then
    raise exception 'vault_encrypt_text: app_vault_data_key secret not found in vault.decrypted_secrets';
  end if;

  return pgp_sym_encrypt(plaintext, v_key);
end;
$$;

create or replace function public.vault_decrypt_text(ciphertext bytea)
returns text
language plpgsql
security definer
set search_path = public, vault
as $$
declare
  v_key text;
begin
  if ciphertext is null then
    return null;
  end if;

  select decrypted_secret
    into v_key
    from vault.decrypted_secrets
   where name = 'app_vault_data_key'
   limit 1;

  if v_key is null then
    raise exception 'vault_decrypt_text: app_vault_data_key secret not found in vault.decrypted_secrets';
  end if;

  return pgp_sym_decrypt(ciphertext, v_key);
end;
$$;

-- Lock down direct execution to authenticated roles only.
revoke execute on function public.vault_encrypt_text(text) from public;
revoke execute on function public.vault_decrypt_text(bytea) from public;
grant execute on function public.vault_encrypt_text(text) to authenticated, service_role;
grant execute on function public.vault_decrypt_text(bytea) to authenticated, service_role;

-- ROLLOUT NOTE:
-- Before this migration runs on prod, an operator must create the secret:
--   select vault.create_secret(
--     '<256-bit hex key>',
--     'app_vault_data_key',
--     'AES-256 key for column-level encryption of medical/PII data'
--   );
-- The same secret name MUST exist on every environment (staging confirmed
-- 2026-04-28; prod pending).
--
-- ROLLBACK: drop function public.vault_encrypt_text(text);
--           drop function public.vault_decrypt_text(bytea);
--           then re-apply 20260427211500_vault_audit_table.sql definitions
--           (GUC version) — but that path is broken on Supabase, so rollback
--           only makes sense if the prod secret can't be provisioned at all.
