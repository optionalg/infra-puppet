
class nagios-server {
    group {
        "nagios" :
            ensure  => present;
    }

    user {
        "nagios" :
            ensure  => present,
            require => [
                        File["/etc/nagios"],
                        Group["nagios"]
                       ];
    }


    file {
        "/etc/nagios" :
            ensure  => directory,
            require => [
                        Group["nagios"],
                        Package["nagios"],
                        Package["nagios-plugins"],
                        Package["nagios-nrpe"]
                       ]
    }


    # I think it's safe to assume that if we're not on CentOS, we're running on
    # Ubuntu
    if $operatingsystem == "CentOS" {
        include  nagios-server::centos
    }
    else {
        include  nagios-server::ubuntu
    }
}
