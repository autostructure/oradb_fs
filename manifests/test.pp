define oradb_fs::test (
)
{
pam { "Set cracklib limits in password-auth":
  ensure    => present,
  type      => 'session',
  control   => 'required',
  module    => 'pam_limits.so',
  target    => '/tmp/su',
}

}
