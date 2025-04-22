
# 🔐 AWS Session Helper via 1Password

This Bash script retrieves temporary AWS credentials using 1Password (`op`) and caches them locally. It's useful for AWS CLI access when you store your long-term AWS credentials and MFA settings in 1Password.

## 🚀 Features

- Retrieves AWS credentials from 1Password
- Supports MFA token generation via `op`
- Supports optional role assumption
- Caches temporary credentials to reduce repeated MFA prompts
- Designed for `credential_process` integration with the AWS CLI

---

## 🧰 Prerequisites

- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- `jq` for JSON parsing
- Logged in to `op` via `op signin`

---

## 📜 Script Usage

```bash
./op-cred-helper-session.sh <vault> <secret_id> <region> [role_field_name]
```

### Arguments

| Argument            | Required | Description                                                                 |
|---------------------|----------|-----------------------------------------------------------------------------|
| `vault`             | ✅       | The name of your 1Password vault (can sometimes be optional if defaulted) |
| `secret_id`         | ✅       | The item ID or name in 1Password containing AWS credentials                |
| `region`            | ✅       | AWS region used to generate the session                                    |
| `role_field_name`   | ❌       | Field name in 1Password item with the Role ARN to assume (optional)        |

---

## 🛠 AWS CLI Integration

You can use the script in your AWS profile with `credential_process`:

### Example AWS CLI config

In `~/.aws/config`:

```ini
[profile my-profile]
region = eu-central-1
credential_process = /path/to/op-cred-helper-session.sh myvault he7tgj4e63x6feufgmxvoe2ms4 eu-central-1 admin-role
```

### Breakdown:

| Config Key         | Description                                                |
|--------------------|------------------------------------------------------------|
| `region`           | The AWS region to use                                      |
| `credential_process` | Path to the script with required arguments               |
| `myvault`          | Your 1Password vault name                                  |
| `he7tgj4e63x6feufgmxvoe2ms4` | 1Password item with keys and MFA info         |
| `admin-role`       | (Optional) Field name with the role ARN to assume          |

---

## 💾 Caching Behavior

To avoid repeated MFA prompts, the script stores temporary credentials in:

```bash
/tmp/aws_session_<secret_id>_<role>.json
```

Before fetching new credentials, it checks if the cached ones are still valid based on the expiration timestamp.

---

## 📋 Expected 1Password Fields

The 1Password item should include:

- **access key id**
- **secret access key**
- **mfa serial**
- *(optional)* a field with your **role ARN** (e.g. `admin-role`)

---

## 🧪 Testing

Test the output manually:

```bash
./op-cred-helper-session.sh myvault myitem eu-central-1
```

You should see a JSON object with `AccessKeyId`, `SecretAccessKey`, `SessionToken`, and `Expiration`.

---

## 🧼 Cleanup (Optional)

To clear the cache manually:

```bash
rm /tmp/aws_session_<secret_id>_*.json
```

---

## 📄 License

MIT – free to use, modify, and improve 😄
```


