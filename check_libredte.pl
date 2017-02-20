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
# @version 2017-02-20
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

# entregar mensaje con resultado
my $msg = 'contribuyentes: '.format_number($stats->{contribuyentes_sii}).
          ' / usuarios: '.format_number($stats->{usuarios_registrados}).
          ' / empresas: '.format_number($stats->{empresas_registradas}).
          ' / emitidos: '.format_number($stats->{documentos_emitidos}).
          ($certificacion?' [C]':' [P]');
$np->plugin_exit(OK, $msg);
