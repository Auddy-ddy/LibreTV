#!/bin/sh
set -e

# Function to hash a string with SHA-256
hash_password() {
  if [ -z "$1" ]; then
    echo ""
  else
    echo -n "$1" | sha256sum | cut -d ' ' -f 1
  fi
}

# Function to escape special characters for sed
escape_for_sed() {
  echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Function to replace environment variables in HTML files
replace_env_vars() {
  # Hash the password if it exists
  local password_hash=""
  if [ -n "$PASSWORD" ]; then
    password_hash=$(hash_password "$PASSWORD")
  fi

  # 获取PASSWORD_URL环境变量
  local password_url="${PASSWORD_URL:-}"
  # 转义password_url中的特殊字符
  local escaped_password_url=$(escape_for_sed "$password_url")
  
  # 打印环境变量值以便调试
  echo "PASSWORD_HASH: ${password_hash}"
  echo "PASSWORD_URL: ${password_url}"
  echo "ESCAPED_PASSWORD_URL: ${escaped_password_url}"

  # Replace the password placeholder in all HTML files with the hashed password
  find /usr/share/nginx/html -type f -name "*.html" -exec sed -i "s/window.__ENV__.PASSWORD = \"{{PASSWORD}}\";/window.__ENV__.PASSWORD = \"${password_hash}\";/g" {} \;
  
  # 替换PASSWORD_URL环境变量 - 使用分隔符|避免URL中的/造成问题
  find /usr/share/nginx/html -type f -name "*.html" -exec sed -i "s|window.__ENV__.PASSWORD_URL = \"{{PASSWORD_URL}}\";|window.__ENV__.PASSWORD_URL = \"${escaped_password_url}\";|g" {} \;
  
  # 替换链接中的{{PASSWORD_URL}}为实际值 - 使用分隔符|避免URL中的/造成问题
  find /usr/share/nginx/html -type f -name "*.html" -exec sed -i "s|href=\"{{PASSWORD_URL}}\"|href=\"${escaped_password_url}\"|g" {} \;
  
  echo "Environment variables have been injected into HTML files."
}

# Replace environment variables in HTML files
replace_env_vars

# Execute the command provided as arguments
exec "$@"