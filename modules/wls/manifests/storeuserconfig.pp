# == Define: wls::storeuserconfig
#
# generic storeuserconfig wlst script  
#
#
# === Examples
#  
#
#  wls::storeuserconfig{
#   'adminServer':
#    wlHome        => "/opt/oracle/wls/wls11g/wlserver_10.3",
#    fullJDKName   => $jdkWls11gJDK,
#    domain        => 'osbSoaDomain', 
#    address       => "localhost",
#    wlsUser       => "weblogic",
#    password      => "weblogic1",
#    port          => "7001",
#    user          => 'oracle',
#    group         => 'dba',
#    userConfigDir => '/home/oracle', 
#    downloadDir   => "/install/",
#  }
#
#
# 

define wls::storeuserconfig( $wlHome        = undef, 
                             $fullJDKName   = undef, 
                             $domain        = undef, 
                             $address       = "localhost",
                             $port          = '7001',
                             $wlsUser       = "weblogic",
                             $password      = "weblogic1",
                             $user          = 'oracle', 
                             $group         = 'dba',
                             $userConfigDir = '/home/oracle',
                             $downloadDir   = '/install/',
                            ) {


   $javaCommand    = "java -Dweblogic.management.confirmKeyfileCreation=true -Dweblogic.security.SSL.ignoreHostnameVerification=true weblogic.WLST -skipWLSModuleScanning "

   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: { 

        $execPath         = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path             = $downloadDir
        $JAVA_HOME        = "/usr/java/${fullJDKName}"

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               replace => 'yes',
               mode    => 0555,
               owner   => $user,
               group   => $group,
             }     
     }
     Solaris: { 

        $execPath         = "/usr/jdk/${fullJDKName}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path             = $downloadDir
        $JAVA_HOME        = "/usr/jdk/${fullJDKName}"


        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               replace => 'yes',
               mode    => 0555,
               owner   => $user,
               group   => $group,
             }  
     
     }
     windows: { 

        $execPath         = "C:\\oracle\\${fullJDKName}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $path             = $downloadDir 

        $JAVA_HOME        = "c:\\oracle\\${fullJDKName}"

        Exec { path      => $execPath,
               logoutput => true,
             }
        File { ensure  => present,
               replace => 'yes',
               mode    => 0777,
             }     
     }
   }
    
   # the py script used by the wlst
   file { "${path}/${title}storeUserConfig.py":
      path    => "${path}/${title}storeUserConfig.py",
      content => template("wls/wlst/storeUserConfig.py.erb"),
   }
     
   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: { 

        exec { "execwlst ${title}storeUserConfig.py":
          command     => "${javaCommand} ${path}/${title}storeUserConfig.py",
          environment => ["CLASSPATH=${wlHome}/server/lib/weblogic.jar",
                          "JAVA_HOME=${JAVA_HOME}",
                          "CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom"],
          unless      => "ls -l ${userConfigDir}/${user}-${$domain}-WebLogicConfig.properties",
          require     => File["${path}/${title}storeUserConfig.py"],
        }    

        case $operatingsystem {
           CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: { 

              exec { "rm ${path}/${title}storeUserConfig.py":
                command => "rm -I ${path}/${title}storeUserConfig.py",
                require => Exec["execwlst ${title}storeUserConfig.py"],
              }
           }
           Solaris: { 

             exec { "rm ${path}/${title}storeUserConfig.py":
               command => "rm ${path}/${title}storeUserConfig.py",
               require => Exec["execwlst ${title}storeUserConfig.py"],
             }           
           }
        }     

     }
     windows: { 

        exec { "execwlst ${title}storeUserConfig.py":
          command     => "C:\\Windows\\System32\\cmd.exe /c ${javaCommand} ${path}/${title}storeUserConfig.py",
          unless      => "C:\\Windows\\System32\\cmd.exe /c dir ${userConfigDir}/${user}-${domain}-WebLogicConfig.properties",
          require     => File["${path}/${title}storeUserConfig.py"],
          environment => ["CLASSPATH=${wlHome}\\server\\lib\\weblogic.jar",
                          "JAVA_HOME=${JAVA_HOME}"],
        }    


        exec { "rm ${path}/${title}storeUserConfig.py":
           command => "C:\\Windows\\System32\\cmd.exe /c rm ${path}/${title}storeUserConfig.py",
           require => Exec["execwlst ${title}storeUserConfig.py"],
        }
     }
   }



}

