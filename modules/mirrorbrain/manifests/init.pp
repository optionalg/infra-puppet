#
#   Manifest responsible for driving a the MirrorBrain installation behind
#   mirrors.jenkins-ci.org

class mirrorbrain {
    if $operatingsystem != "Ubuntu" {
        err("The mirrorbrain module is currently only functional for Ubuntu hosts")
    }

    include mirrorbrain::ubuntu
    include apache2
    Class["apache2"] -> Class["mirrorbrain::ubuntu"]
}

class mirrorbrain::ubuntu {
    include mirrorbrain::cron
    include mirrorbrain::files
    include mirrorbrain::tree
    include mirrorbrain::repos
    include mirrorbrain::packages

    Class["mirrorbrain::repos"] ->
        Class["mirrorbrain::packages"] ->
            Class["mirrorbrain::tree"] ->
                Class["mirrorbrain::files"] ->
                    Class["mirrorbrain::cron"]


    enable-apache-mod {
        "mirrorbrain":
            name => "mirrorbrain",
            require => Class["mirrorbrain::packages"];

        "geoip" :
            name => "geoip",
            require => [
                        Class["mirrorbrain::packages"],
                        Class["mirrorbrain::files"],
                        ];

        # Required for mirrorbrain to access postgresql
        "dbd" :
            name => "dbd",
            require => Package["apache2"];
    }
}


class mirrorbrain::repos {
    file {
        "/etc/apt/sources.list.d" :
            ensure => directory;

        "/etc/apt/sources.list.d/mirrorbrain.list" :
            ensure => present,
            notify => [
                        Exec["install-key"],
                        Exec["refresh-apt"],
                      ],
            source => "puppet:///modules/mirrorbrain/apt.list",
    }

    file {
        "/root/mirrorbrain.key" :
            source => "puppet:///modules/mirrorbrain/Release.key",
            ensure => present;
    }

    exec {
        "refresh-apt" :
            refreshonly => true,
            require => [
                        File["/etc/apt/sources.list.d/mirrorbrain.list"],
                        Exec["install-key"],
                       ],
            command => "apt-get update";

        "install-key" :
            notify => Exec["refresh-apt"],
            require => [
                        File["/etc/apt/sources.list.d/mirrorbrain.list"],
                        File["/root/mirrorbrain.key"],
                       ],
            command => "/usr/bin/apt-key add /root/mirrorbrain.key";
    }
}

class mirrorbrain::packages {
    package {
        "libapache2-mod-geoip" :
            ensure => installed,
            require => Package["apache2"];

        "libapache2-mod-mirrorbrain" :
            ensure => installed,
            require => Package["apache2"];

        "mirrorbrain" :
            ensure => installed;

        "mirrorbrain-scanner" :
            ensure => installed;

        "mirrorbrain-tools" :
            ensure => installed;

        "postgresql-server-dev-8.4" :
            ensure => installed;

        "mirmon" :
            ensure => installed;

        # Python dependencies

        # Needed to build the stupid mb tools
        "python-dev" :
            ensure => installed;

        "python-psycopg2" :
            require => Package["postgresql-server-dev-8.4"],
            ensure => installed;
        "python-sqlobject" :
            ensure => installed;
        "python-cmdln" :
            ensure => installed;
    }
}

class mirrorbrain::tree {
    file {
        "/etc/httpd" :
            ensure  => directory,
            require => Class["apache2"];

        "/etc/httpd/conf.d" :
            ensure  => directory,
            require => [
                        Class["apache2"],
                        File["/etc/httpd"]
                       ];
    }
}

class mirrorbrain::files {
    file {
        "/etc/httpd/conf.d/mirrors.conf" :
            ensure  => present,
            require => Class["apache2"],
            source  => "puppet:///modules/mirrorbrain/virtualhost.conf";

        "/etc/httpd/conf.d/geoip.conf" :
            ensure  => present,
            require => [
                        Class["apache2"]
                       ],
            source  => "puppet:///modules/mirrorbrain/geoip.conf";


        "/etc/mirmon.conf" :
            ensure  => present,
            source  => "puppet:///modules/mirrorbrain/mirmon.conf";

        "/etc/mirrorbrain.conf" :
            ensure  => present,
            source  => "puppet:///modules/mirrorbrain/mirrorbrain.conf";
    }
}
