# lts

# Namecheap SSH MySQL SELECT to CSV

This repository contains a repeatable process for SSHing into a Namecheap hosting account, running a MySQL/MariaDB `SELECT`, and saving the result as a local CSV file.

## Files

- `export_namecheap_db.sh` — main export script.
- `.env.example` — connection settings template.
- `queries/example_select.sql` — example SELECT statement.
- `exports/` — recommended output folder for CSV files.

## One-time setup

Open Git Bash from this folder:

```bash
cd /c/Users/Sean/lts
chmod +x export_namecheap_db.sh
cp .env.example .env
```

Edit `.env` with your real Namecheap/cPanel and database values:

```bash
nano .env
```

Typical Namecheap shared hosting SSH port is `21098`, but use whatever Namecheap/cPanel shows for your account.

## Verify SSH access

```bash
source .env
ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST"
```

If SSH works, exit the server:

```bash
exit
```

## Create your SELECT statement

Create or edit a `.sql` file under `queries/`. Example:

```sql
SELECT
  id,
  email,
  created_at
FROM your_table_name
WHERE created_at >= '2026-01-01'
ORDER BY created_at DESC;
```

The script intentionally refuses to run SQL that does not begin with `SELECT` or `WITH`, so this process does not accidentally mutate production data.

## Export to CSV

```bash
source .env
./export_namecheap_db.sh queries/example_select.sql exports/example_select.csv
```

If `DB_PASS` is not set in `.env`, the script prompts for the MySQL password securely.

The script does this:

1. Opens SSH to the Namecheap server.
2. Runs the SQL through the remote `mysql` CLI.
3. Captures tab-separated output with headers.
4. Converts it locally to CSV using Python's built-in `csv` module.
5. Writes the final CSV to the path you provide.

## Common Namecheap values

- `SSH_USER`: cPanel username.
- `SSH_HOST`: Namecheap server hostname, SSH hostname, or your domain if DNS points to the hosting account.
- `SSH_PORT`: often `21098` on Namecheap shared hosting.
- `DB_HOST`: usually `localhost`.
- `DB_USER` / `DB_NAME`: often prefixed by cPanel username, e.g. `cpaneluser_appdb`.

## Optional: key-based SSH

If you use an SSH key, add this to `.env`:

```bash
export SSH_KEY='/c/Users/Sean/.ssh/namecheap_ed25519'
```

Then run the same export command.

## Troubleshooting

### `Permission denied` over SSH

Check username, hostname, port, and whether SSH is enabled for the hosting account. Namecheap may require enabling SSH access from cPanel or support.

### `mysql: command not found`

Most cPanel servers have `mysql` available. If yours does not, ask Namecheap support for the MySQL CLI path and update `REMOTE_CMD` in `export_namecheap_db.sh` to use that full path.

### `Access denied for user ...`

Check `DB_USER`, `DB_NAME`, and MySQL password. In cPanel, make sure the database user is assigned to the database with at least `SELECT` permissions.

### CSV contains unexpected columns or too many rows

Edit the SQL in `queries/*.sql`; the CSV output exactly follows the query result set.
