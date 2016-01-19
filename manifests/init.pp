#
# Class: cvmfs
#
# manages install and configuration of CVMFS
#
class cvmfs (
    $cvmfs_http_proxy_list = [ ],
    $local_site_name = '',
    $local_se_name = '',
    $fallback_site_name = '',
    $fallback_se_name = '',
    $fallbac_lfn_prefix = '',
    $xrootd = '',
    $xrootdalt = '',
    $srmv2 = '',
    $backupproxy_list = [ ],
){

    include cvmfs::params
    #include autofs

    package { "osg-oasis":
        name    => "osg-oasis",
        ensure  => present,
        notify  => Service["autofs"],
    }

    package { "cvmfs":
        name    => "${cvmfs::params::cvmfs_package_name}",
        ensure  => present,
        require => User["cvmfs"],
        notify  => Service["autofs"],
    }

    package { "cvmfs-config-osg":
        name    => "cvmfs-config-osg",
        ensure  => present,
        require => Package["cvmfs"],
    }

    package { "fuse":
        name   => "fuse.x86_64",
        ensure => present,
    }

    package { 'redhat-lsb-core':
        ensure => present,
    }

    # we run cvmfs as a dedicated user
    group { "cvmfs":
        name   => "${cvmfs::params::cvmfs_group}",
        ensure => present,
        system => true,
    }

    user { "cvmfs":
        name       => "${cvmfs::params::cvmfs_user}",
        ensure     => present,
        system     => true,
        gid        => "${cvmfs::params::cvmfs_group}",
        groups     => ["fuse"],
        require    => [Group["cvmfs"], Package["fuse"]],
        managehome => false,
        shell      => '/sbin/nologin',
    }

    file { "/scratch/cvmfs2":
        path    => "/scratch/cvmfs2",
        mode    => "0755",
        owner   => "root",
        group   => "root",
        ensure  => directory,
    }

## Files for talking to UW's CVMFS.
##
    file { "wisc_pubkey":
        path    => "/etc/cvmfs/keys/cms.hep.wisc.edu.pub",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/cvmfs/cms.hep.wisc.edu.pub",
        ensure  => present,
        require => Package["cvmfs"],
    }

    file { "wisc_conf":
        path    => "/etc/cvmfs/config.d/cms.hep.wisc.edu.conf",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/cvmfs/cms.hep.wisc.edu.conf",
        ensure  => present,
        require => Package["cvmfs"],
    }

## Files for talking to OSG's CVMFS.
##
    file { "osg_pubkey":
        path    => "/etc/cvmfs/keys/oasis.opensciencegrid.org.pub",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/cvmfs/oasis.opensciencegrid.org.pub",
        ensure  => present,
        require => Package["cvmfs"],
    }

    file { "osg_conf":
        path    => "/etc/cvmfs/config.d/oasis.opensciencegrid.org.conf",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/cvmfs/oasis.opensciencegrid.org.conf",
        ensure  => present,
        require => Package["cvmfs"],
    }

    file { "darkside_conf":
        path    => "/etc/cvmfs/config.d/darkside.opensciencegrid.org.conf",
        ensure  => "link",
        target  => "oasis.opensciencegrid.org.conf",
        require => File["osg_conf"],
    }

    file { "fermilab_conf":
        path    => "/etc/cvmfs/config.d/fermilab.opensciencegrid.org.conf",
        ensure  => "link",
        target  => "oasis.opensciencegrid.org.conf",
        require => File["osg_conf"],
    }

    file { "icecube_conf":
        path    => "/etc/cvmfs/config.d/icecube.opensciencegrid.org.conf",
        ensure  => "link",
        target  => "oasis.opensciencegrid.org.conf",
        require => File["osg_conf"],
    }

    file { "lsst_conf":
        path    => "/etc/cvmfs/config.d/lsst.opensciencegrid.org.conf",
        ensure  => "link",
        target  => "oasis.opensciencegrid.org.conf",
        require => File["osg_conf"],
    }

    file { "mu2e_conf":
        path    => "/etc/cvmfs/config.d/mu2e.opensciencegrid.org.conf",
        ensure  => "link",
        target  => "oasis.opensciencegrid.org.conf",
        require => File["osg_conf"],
    }

    file { "usatlast3_conf":
        path    => "/etc/cvmfs/config.d/usatlast3.opensciencegrid.org.conf",
        ensure  => "link",
        target  => "oasis.opensciencegrid.org.conf",
        require => File["osg_conf"],
    }

    file { "default.local":
        path    => "${cvmfs::params::cvmfs_config_file}",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        content => template('cvmfs/default.local.erb'),
        require => Package["cvmfs"],
        ensure  => present,
    }

## Files for making CMS CVMFS work.
##
    file { "SITECONF_dir":
        path    => "/etc/cvmfs/SITECONF",
        mode    => "0644", owner => "root", group => "root",
        recurse => true,
        ensure  => directory,
        require => Package["cvmfs"],
    }

    file { "JobConfig_dir":
        path    => "/etc/cvmfs/SITECONF/JobConfig",
        mode    => "0644", owner => "root", group => "root",
        recurse => true,
        ensure  => directory,
        require => File["SITECONF_dir"],
    }

    file { "site-local-config.xml":
        path    => "/etc/cvmfs/SITECONF/JobConfig/site-local-config.xml",
        content  => template('cvmfs/site-local-config.xml.erb'),
        mode    => "0644", owner => "root", group => "root",
        ensure  => present,
        require => File["JobConfig_dir"],
    }

    file { "PhEDEx_dir":
        path    => "/etc/cvmfs/SITECONF/PhEDEx",
        mode    => "0644", owner => "root", group => "root",
        ensure  => directory,
        require => File["SITECONF_dir"],
    }

    file { "storage.xml":
        path    => "/etc/cvmfs/SITECONF/PhEDEx/storage.xml",
        content  => template('cvmfs/storage.xml.erb'),
        mode    => "0644", owner => "root", group => "root",
        ensure  => present,
        require => File["PhEDEx_dir"],
    }

## Use FNAL stratum one
##
   file { "FNAL_stratum_one":
          path    => "/etc/cvmfs/domain.d/cern.ch.local",
          source  => "puppet:///modules/cvmfs/cern.ch.local",
          mode    => "0644", owner => "root", group => "root",
          ensure  => present,
          require => Package["cvmfs"],
   }

## FNAL testing nova data flux files
##
    file { "fnaldata.gov.pub":
        path    => "/etc/cvmfs/keys/fnaldata.gov.pub",
        source  => "puppet:///modules/cvmfs/fnaldata.gov.pub",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        ensure  => present,
        require => Package["cvmfs"],
    }

    file { "fnaldata.gov.local":
        path    => "/etc/cvmfs/domain.d/fnaldata.gov.local",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/cvmfs/fnaldata.gov.local",
        ensure  => present,
        require => Package["cvmfs"],
    }

    file { "fuse.conf":
        path    => "/etc/fuse.conf",
        mode    => "0644",
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/cvmfs/fuse.conf",
        ensure  => present,
    }

    file { "cvmfs_cache":
        path    => "/var/cache/cvmfs2",
        ensure  => directory,
        owner   => "cvmfs",
        group   => "cvmfs",
        mode    => "0700",
        require => [User["cvmfs"], Group["cvmfs"], Package["cvmfs"]],
    }

    service { "cvmfs":
        name       => "${cvmfs::params::cvmfs_service_name}",
        #ensure     => running,
        #enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => [Package["cvmfs"], File["default.local"], File["fuse.conf"], File["cvmfs_cache"]],
        subscribe  => File["${cvmfs::params::cvmfs_config_file}"],
    }

}
