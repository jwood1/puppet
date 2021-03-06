# jdk7::urandomfix
#
# On Linux low entropy can cause certain operations to be very slow.
# Encryption operations need entropy to ensure randomness. Entropy is
# generated by the OS when you use the keyboard, the mouse or the disk.
#
# If an encryption operation is missing entropy it will wait until
# enough is generated.
#
# three options
#  use rngd service (this class)
#  set java.security in JDK ( jre/lib/security )
#  set -Djava.security.egd=file:/dev/./urandom param
#
class jdk7::urandomfix () {

  case $::kernel {
    'Linux': { $path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:' }
    default : { fail('Unrecognized operating system') }
  }

  package { 'rng-tools':
    ensure => present,
  }

  case $::osfamily {
    'RedHat': {
      if ( $::operatingsystemmajrelease == '7') {
        exec { 'set urandom /lib/systemd/system/rngd.service':
          command => "sed -i -e's/ExecStart=\\/sbin\\/rngd -f/ExecStart=\\/sbin\\/rngd -r \\/dev\\/urandom -o \\/dev\\/random -f/g' /lib/systemd/system/rngd.service;systemctl daemon-reload;systemctl restart rngd.service",
          unless  => "/bin/grep 'ExecStart=/sbin/rngd -r /dev/urandom -o /dev/random -f' /lib/systemd/system/rngd.service",
          require => Package['rng-tools'],
          user    => 'root',
          path    => $path,
        }
      } else {
        exec { 'set urandom /etc/sysconfig/rngd':
          command   => "sed -i -e's/EXTRAOPTIONS=\"\"/EXTRAOPTIONS=\"-r \\/dev\\/urandom -o \\/dev\\/random -b\"/g' /etc/sysconfig/rngd",
          unless    => "/bin/grep '^EXTRAOPTIONS=\"-r /dev/urandom -o /dev/random -b\"' /etc/sysconfig/rngd",
          require   => Package['rng-tools'],
          path      => $path,
          logoutput => true,
          user      => 'root',
        }

        service { 'start rngd service':
          ensure  => true,
          name    => 'rngd',
          enable  => true,
          require => Exec['set urandom /etc/sysconfig/rngd'],
        }

        exec { 'chkconfig rngd':
          command   => 'chkconfig --add rngd',
          require   => Service['start rngd service'],
          unless    => "chkconfig | /bin/grep 'rngd'",
          path      => $path,
          logoutput => true,
          user      => 'root',
        }
      }
    }
    'Debian','Suse' : {
      exec { 'set urandom /etc/default/rng-tools':
        command   => "sed -i -e's/#HRNGDEVICE=\\/dev\\/null/HRNGDEVICE=\\/dev\\/urandom/g' /etc/default/rng-tools",
        unless    => "/bin/grep '^HRNGDEVICE=/dev/urandom' /etc/default/rng-tools",
        require   => Package['rng-tools'],
        path      => $path,
        logoutput => true,
        user      => 'root',
      }

      service { 'start rng-tools service':
        ensure  => true,
        name    => 'rng-tools',
        enable  => true,
        require => Exec['set urandom /etc/default/rng-tools'],
      }
    }
    default: {
      fail("Unrecognized osfamily ${::osfamily}, please use it on a Linux host")
    }

  }
}
