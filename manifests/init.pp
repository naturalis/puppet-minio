# Class: minio
# ===========================
#
class minio(
        $access_key,
        $secret_key,
        $ssl_public_cert,
        $ssl_private_key,
        $minio_data_dir = '/minio-data'
){

  $image_name='minio/minio'
  $container_name='minio-server'
  $diffcmd = "/usr/bin/diff <(docker image inspect --format='{{.Id}}' ${image_name}) <(docker inspect --format='{{.Image}}' ${container_name})"

  include 'docker'

  file { ['/etc/minio','/etc/minio/certs',$minio_data_dir] :
    ensure => directory,
  }

  file { '/etc/minio/certs/public.crt' :
    content => $ssl_public_cert,
    require => File['/etc/minio/certs'],
    mode    => '0600',
  }

  file { '/etc/minio/certs/private.key' :
    content => $ssl_private_key,
    require => File['/etc/minio/certs'],
    mode    => '0600',
  }

  docker::run { $container_name :
    image   => $image_name,
    ports   => ['443:9000'],
    env     => ["MINIO_ACCESS_KEY=${access_key}",
                "MINIO_SECRET_KEY=${secret_key}"],
    volumes => ["${minio_data_dir}:/export",
                  '/etc/minio:/root/.minio'],
    command => 'server /export',
    require => [File['/etc/minio/certs/public.crt'],
                File['/etc/minio/certs/private.key'],
                File[$minio_data_dir]
    ]
  }

  exec { "/bin/systemctl restart docker-${container_name}" :
    onlyif  => $diffcmd,
    require => [Exec["/usr/bin/docker pull ${image_name}"],Docker::Run[$container_name]]
  }

  exec {"/usr/bin/docker pull ${image_name}" :
    schedule => 'everyday',
  }

  schedule { 'everyday':
    period => daily,
    repeat => 1,
    range  => '7-9',
  }

}
