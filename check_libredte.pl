#!/usr/bin/perl

#
# LibreDTE
# Copyright (C) SASCO SpA (https://sasco.cl)
#
# Este programa es software libre: usted puede redistribuirlo y/o
# modificarlo bajo los términos de la Licencia Pública General Affero de GNU
# publicada por la Fundación para el Software Libre, ya sea la versión
# 3 de la Licencia, o (a su elección) cualquier versión posterior de la
# misma.
#
# Este programa se distribuye con la esperanza de que sea útil, pero
# SIN GARANTÍA ALGUNA; ni siquiera la garantía implícita
# MERCANTIL o de APTITUD PARA UN PROPÓSITO DETERMINADO.
# Consulte los detalles de la Licencia Pública General Affero de GNU para
# obtener una información más detallada.
#
# Debería haber recibido una copia de la Licencia Pública General Affero de GNU
# junto a este programa.
# En caso contrario, consulte <http://www.gnu.org/licenses/agpl.html>.
#

#
# Comando para monitorear LibreDTE (estadísticas) usando Nagios
# @author Esteban De La Fuente Rubio, DeLaF (esteban[at]sasco.cl)
# @version 2017-12-18
#

use strict;
use warnings;
use Monitoring::Plugin;
use REST::Client;
use JSON;
use Number::Format qw(:subs);

# crear constructor y recuperar parámetros pasados al comando
my $np = Monitoring::Plugin->new(
    usage => "Modo de uso: %s --url <url>"
);
$np->add_arg(
    spec => 'url=s',
    help => '--url=STRING'
);
$np->add_arg(
    spec => 'certificacion=s',
    help => '--certificacion=INTEGER'
);
$np->getopts();

# crear url que se consultará
$np->plugin_die('Debe especificar --url') if not defined $np->opts->url;
my $url;
my $certificacion;
if (defined $np->opts->certificacion and $np->opts->certificacion) {
    $url = $np->opts->url.'/api/estadisticas/certificacion';
    $certificacion = 1;
} else {
    $url = $np->opts->url.'/api/estadisticas/produccion';
    $certificacion = 0;
}

# obtener estadísticas
my $rest = REST::Client->new();
$rest->setFollow(1);
my $result = $rest->GET($url);
$np->plugin_exit(CRITICAL, $result->responseContent()) if $result->responseCode() != 200;
my $stats = decode_json($result->responseContent());

# armar mensaje con resultado de estadística
my $status = OK;
my $msg = 'contribuyentes: '.format_number($stats->{contribuyentes_sii}).
          ' / usuarios: '.format_number($stats->{usuarios_registrados}).
          ' / empresas: '.format_number($stats->{empresas_registradas}).
          ' / emitidos: '.format_number($stats->{documentos_emitidos}).
          ($certificacion?' [C]':' [P]');

# comparar version
if ($stats->{version}) {
    my $version = $stats->{version}->{libredte};
    if ($version != 0) {
        # obtener commits de la aplicación web (para comparar con versión)
        $result = $rest->GET('https://api.github.com/repos/LibreDTE/libredte-webapp/commits');
        $np->plugin_exit(CRITICAL, $result->responseContent()) if $result->responseCode() != 200;
        my @commits = decode_json($result->responseContent());
        my $last_commit = $commits[0][0]->{sha};
        # verificar si la versión corresponde a la última disponible en el repositorio de GitHUB
        my $version_id = $version->{id};
        if ($version_id ne $last_commit) {
            $status = WARNING;
            my $version_id_short = substr($version_id, 0, 7);
            my $version_date = substr($version->{date}, 0, 10);
            my $last_commit_short = substr($last_commit, 0, 7);
            my $last_commit_date = substr($commits[0][0]->{commit}->{author}->{date}, 0, 10);
            $msg .= ' / version: '.$version_id_short.' ('.$version_date.') != '.$last_commit_short.' ('.$last_commit_date.')';
        }
    }
} else {
    $status = WARNING;
    $msg .= ' / version: no disponible';
}

# entregar mensaje con resultado
$np->plugin_exit($status, $msg);
