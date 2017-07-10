LibreDTE Nagios Plugin
======================

Comando para monitorear LibreDTE (estadísticas) desde Nagios.

Comando bajo licencia AGPL.

Instalar dependencias:

    # cpan Monitoring::Plugin REST::Client JSON Number::Format

Copiar el comando en el directorio de comandos de nagios ($USER1$).

Agregar el comando en nagios:

    define command {
        command_name    check_libredte
        command_line    $USER1$/check_libredte.pl --url $ARG1$
    }

Agregar servicio al host en nagios:

    define service {
        use                     generic-service
        host_name               dte.example.com
        service_description     LibreDTE
        check_command           check_libredte!https:\/\/dte.example.com
    }
