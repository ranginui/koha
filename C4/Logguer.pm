package C4::Logguer;

# Copyright 2009 Biblibre SARL
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use base 'Exporter';
our @EXPORT    = qw();
our @EXPORT_OK = qw($log_opac $log_koha);

use C4::Context;
use Log::LogLite;
my $LOG_DIR = C4::Context->config('logdir');

my $KOHA_LOG_FILE = $LOG_DIR . "/koha.log";
my $OPAC_LOG_FILE = $LOG_DIR . "/opac.log";
my $CRITICAL_LOG_LEVEL = 2;
my $ERROR_LOG_LEVEL    = 3;
my $WARNING_LOG_LEVEL  = 4;
my $NORMAL_LOG_LEVEL   = 5;
my $INFO_LOG_LEVEL     = 6;
my $DEBUG_LOG_LEVEL    = 7;

our $log_koha = C4::Logguer->new($KOHA_LOG_FILE, 7);
our $log_opac = C4::Logguer->new($OPAC_LOG_FILE, 7);

use Data::Dumper;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{FILE_PATH} = shift;
    $self->{LEVEL} = shift || $NORMAL_LOG_LEVEL;
    $self->{LOGGER} = Log::LogLite->new($self->{FILE_PATH}, $self->{LEVEL});
    return bless( $self );

}

sub write {
    my ($self, $msg, $level_str, $log_level, $dump, $cb) = @_;

    my $template = "[<date>] $level_str: <message>";
    $template .= " (caller: $cb)" if $cb;
    $template .= "\n";
    $self->{LOGGER}->template($template);
    $msg = "\n" . Dumper $msg if $dump;
    $self->{LOGGER}->write($msg, $log_level);
}

sub critical {
    my ($self, $msg, $dump) = @_;
    my $cb = $self->called_by();
    $self->write($msg, 'CRIT  ', $CRITICAL_LOG_LEVEL, $dump, $cb);

}

sub error {
    my ($self, $msg, $dump) = @_;
    my $cb = $self->called_by();
    $self->write($msg, 'ERROR ', $ERROR_LOG_LEVEL, $dump, $cb);
}

sub warning {
    my ($self, $msg, $dump) = @_;
    my $cb = $self->called_by();
    $self->write($msg, 'WARN  ', $WARNING_LOG_LEVEL, $dump, $cb);
}

sub log {
    my ($self, $msg, $dump) = @_;
    $self->write($msg, 'NORMAL', $NORMAL_LOG_LEVEL, $dump);
}

sub normal {
    my ($self, $msg, $dump) = @_;
    $self->write($msg, 'NORMAL', $NORMAL_LOG_LEVEL, $dump);
}

sub info {
    my ($self, $msg, $dump) = @_;
    $self->write($msg, 'INFO  ', $INFO_LOG_LEVEL, $dump);
}

sub debug {
    my ($self, $msg, $dump) = @_;
    $self->write($msg, 'DEBUG ', $DEBUG_LOG_LEVEL, $dump);
}


sub called_by {
    my $self = shift;
    my $depth = 2;
    my $args; 
    my $pack; 
    my $file; 
    my $line; 
    my $subr; 
    my $has_args;
    my $wantarray;
    my $evaltext;
    my $is_require;
    my $hints;
    my $bitmask;
    my @subr;
    my $str = "";
    while (1) {
        ($pack, $file, $line, $subr, $has_args, $wantarray, $evaltext, 
         $is_require, $hints, $bitmask) = caller($depth);
        unless (defined($subr)) {
            last;
        }
        $depth++;	
        $line = (3) ? "$file:".$line."-->" : "";
        push(@subr, $line.$subr);
    }
    @subr = reverse(@subr);
    foreach $subr (@subr) {
        $str .= $subr;
        $str .= " > ";
    }
    $str =~ s/ > $/: /;
    return $str;
} # of called_by

