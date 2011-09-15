#
#   Run pkg.depotd servers for
#   mirrors.jenkins-ci.org
#
# TODO: /var/www/ips.jenkins-ci.org and its contents
# TODO: a2enmod proxy_http
# TODO: splitting off the ProxyPass in the config file as a separate file so that it can be folded into ips::repository
# TODO: restart services

class ips::repository($name,$port) {
    # empty place holder for the repository
    file { "/srv/ips/ips$name":
        ensure => directory;
        mode => 755;
        owner  => "ips";
    }

    # upstart script
    file { "/etc/init/pkg.depotd$name":
        owner => "root";
        group => "root";
        content = template("ips/pkg.depotd.conf.erb")
    }
}

class ips {
    # this service uses Apache as a frontend
    include pkg-apache2
    Class["pkg-apache2"] -> Class["ips"]

    package {
        "ips" :
            ensure => installed,
            source => "puppet:///modules/ips/ips_2.3.54-0_all.deb";
    }

    group {
        "ips" :
            ensure  => present;
    }

    # ips repositories run in a separate user
    user {
        "ips" :
            shell   => "/usr/bin/zsh",
            home    => "/srv/ips",
            ensure  => present,
            require => [
                Package["zsh"]
            ];
    }

    file {
        "/srv/ips/.ssh" :
            ensure      => directory;
            recurse     => true
            owner       => "ips",
            group       => "ips";

        "/var/log/apache2/ips.jenkins-ci.org":
            ensure      => directory;
            owner       => "root";
            group       => "root";

        "/etc/apache2/sites-available/ips.jenkins-ci.org":
            ensure      => directory;
            owner       => "root";
            group       => "root";
            source      => "puppet:///modules/ips/ips.jenkins-ci.org";

        "/etc/apache2/sites-enabled/ips.jenkins-ci.org":
            ensure      => "../sites-available/ips.jenkins-ci.org"
    }

    ssh_authorized_key {
        "ips" :
            user        => "ips",
            ensure      => present,
            require     => File["/srv/ips/.ssh"],
            key         => "AAAAB3NzaC1yc2EAAAABIwAAAQEArSave9EBJ2rP3Hm5PFyiOpfGsPhJwjqdyaVEwQruM0Fa8nWstla7cdSTSs/ClHn7I1uUzQvX+/+6m/HTVy/WIr0cIIxLDm8hXVLfCLddtvxnXx47fJY3ongasYJ4TarIGkMMX/Vg1JpP7XIkMczUSNRyeHg/bGfV+YCPFuSW+cj2M5yMOE1KyIVQQL/JZu7lu80Ara5+RWSITObdiHRpnNzvBdIyhkSCrG0N7QStIBnEaLU//K2AB5GbK/65+k7sklutcH18wSGridQCNJm4ODUxov+vVr2OH3oiv7gyHEE9TypRI9vS0HUmsD+moPq3O8y0xyP8xaJWkz2LKe8/5Q==",
            type        => "rsa",
            name        => "kohsuke@unicore.2010";
    }

    # repository definitions
    class { ips::repository:
        name => "";
        port => 8060;
    }
    class { ips::repository:
        name => "-stable";
        port => 8061;
    }
    class { ips::repository:
        name => "-rc";
        port => 8062;
    }
    class { ips::repository:
        name => "-stable-rc";
        port => 8063;
    }
}