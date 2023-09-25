#!/bin/bash

# Parameters to be set or modified
declare -A parameters=(
  ["net.ipv4.ip_forward"]=0
  ["net.ipv4.conf.all.send_redirects"]=0
  ["net.ipv4.conf.default.send_redirects"]=0
  ["fs.suid_dumpable"]=0
  ["net.ipv4.conf.default.accept_source_route"]=0
  ["net.ipv4.conf.all.rp_filter"]=1
  ["net.ipv4.conf.default.rp_filter"]=1
  ["net.ipv6.conf.all.accept_ra"]=0
  ["net.ipv6.conf.default.accept_ra"]=0
  ["net.ipv4.conf.all.log_martians"]=1
  ["net.ipv4.conf.default.log_martians"]=1
  ["kernel.sysrq"]=0
  ["kernel.core_uses_pid"]=1
  ["kernel.perf_event_paranoid"]=3
  ["net.ipv4.tcp_syncookies"]=1
  ["net.ipv4.tcp_synack_retries"]=5
  ["kernel.randomize_va_space"]=2
  ["dev.tty.ldisc_autoload"]=0
  ["fs.protected_fifos"]=2
  ["kernel.dmesg_restrict"]=1
  ["kernel.kptr_restrict"]=2
  ["kernel.unprivileged_bpf_disabled"]=1
  ["kernel.yama.ptrace_scope"]=1
  ["net.core.bpf_jit_harden"]=2
  ["net.ipv4.conf.all.accept_redirects"]=0
  ["net.ipv4.conf.default.accept_redirects"]=0
  ["net.ipv6.conf.all.accept_redirects"]=0
  ["net.ipv6.conf.default.accept_redirects"]=0
)

# Backup the existing sysctl.conf file
cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Loop through the parameters and modify or add them
for param in "${!parameters[@]}"; do
  value=${parameters["$param"]}
  if grep -q "^$param\s*=" /etc/sysctl.conf; then
    sed -i "s/^$param\s*=.*/$param = $value/" /etc/sysctl.conf
  else
    echo "$param = $value" >> /etc/sysctl.conf
  fi
done

# Apply the new sysctl settings
if ! sysctl -p; then
  echo "Error applying sysctl settings. Reverting to backup."
  cp /etc/sysctl.conf.backup /etc/sysctl.conf
  sysctl -p
  exit 1
fi

echo "Sysctl configuration successfully updated and applied!"
