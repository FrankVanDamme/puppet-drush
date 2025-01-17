# == Define Resource Type: drush::install::composer
#
define drush::install::composer(
  $version,
  $install_path,
  $install_type,
) {

  #private()
  if $caller_module_name != $module_name {
    warning("${name} is not part of the public API of the ${module_name} \
module and should not be directly included in the manifest.")
  }

  # If version is 'master' or a single major release number,
  # transform into something composer understands.
  $real_version = $version ? {
    /\./     => $version,
    'master' => 'dev-master',
    default  => "${version}.*",
  }

  file { $install_path:
    ensure => directory,
    mode   => '0755',
    owner  => "$drush::user",
  }

  $base_path = dirname($install_path)
  $composer_home = "${base_path}/.composer"
  $prefer = "--prefer-${install_type}"
  $cmd = "${drush::composer_path} require drush/drush:${real_version} ${prefer}"

  if ( $drush::http_proxy == undef ){
      $environment = ["COMPOSER_HOME=${composer_home}"]
  } else {
      $environment = ["COMPOSER_HOME=${composer_home}", "http_proxy=$drush::http_proxy"]
  }
  exec { $cmd:
    cwd         => $install_path,
    environment => $environment,
    require     => File[$install_path],
    onlyif      => "test ! -f composer.json || test \"$(grep drush/drush composer.json | cut -d\\\" -f 4)\" != '${real_version}'",
    path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    umask       => '0022',
    user        => $drush::user,
  }
}
