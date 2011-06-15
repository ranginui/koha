package C4::Templates;

use strict;
use warnings;
use Carp;
use CGI;

# Copyright 2009 Chris Cormack and The Koha Dev Team
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

=head1 NAME 

    Koha::Templates - Object for manipulating templates for use with Koha

=cut

use base qw(Class::Accessor);
use Template;
use Template::Constants qw( :debug );

use C4::Context;

__PACKAGE__->mk_accessors(qw( theme lang filename htdocs interface vars));

sub new {
    my $class     = shift;
    my $interface = shift;
    my $filename  = shift;
    my $tmplbase  = shift;
    my $htdocs;
    if ( $interface ne "intranet" ) {
        $htdocs = C4::Context->config('opachtdocs');
    }
    else {
        $htdocs = C4::Context->config('intrahtdocs');
    }

    my ( $theme, $lang ) = themelanguage( $htdocs, $tmplbase, $interface );
    my $template = Template->new(
        {
            EVAL_PERL    => 1,
            ABSOLUTE     => 1,
            INCLUDE_PATH => "$htdocs/$theme/$lang/includes",
            FILTERS      => {},

        }
    ) or die Template->error();
    my $self = {
        TEMPLATE => $template,
        VARS     => {},
    };
    bless $self, $class;
    $self->theme($theme);
    $self->lang($lang);
    $self->filename($filename);
    $self->htdocs($htdocs);
    $self->interface($interface);
    $self->{VARS}->{"test"} = "value";
    return $self;

}

sub output {
    my $self = shift;
    my $vars = shift;

#    my $file = $self->htdocs . '/' . $self->theme .'/'.$self->lang.'/'.$self->filename;
    my $template = $self->{TEMPLATE};
    if ( $self->interface eq 'intranet' ) {
        $vars->{themelang} = '/intranet-tmpl';
    }
    else {
        $vars->{themelang} = '/opac-tmpl';
    }
    $vars->{lang} = $self->lang;
    $vars->{themelang} .= '/' . $self->theme . '/' . $self->lang;
    $vars->{yuipath} =
      ( C4::Context->preference("yuipath") eq "local"
        ? $vars->{themelang} . "/lib/yui"
        : C4::Context->preference("yuipath") );
    $vars->{interface} =
      ( $self->{interface} ne 'intranet' ? '/opac-tmpl' : '/intranet-tmpl' );
    $vars->{theme} = $self->theme;
    $vars->{opaccolorstylesheet} =
      C4::Context->preference('opaccolorstylesheet');
    $vars->{opacsmallimage} = C4::Context->preference('opacsmallimage');
    $vars->{opacstylesheet} = C4::Context->preference('opacstylesheet');

    # add variables set via param to $vars for processing
    # and clean any utf8 mess
    for my $k ( keys %{ $self->{VARS} } ) {
        $vars->{$k} = $self->{VARS}->{$k};
        if (ref($vars->{$k}) eq 'ARRAY'){
            utf8_arrayref($vars->{$k});
        }
        elsif (ref($vars->{$k}) eq 'HASH'){
            utf8_hashref($vars->{$k});
        }
        else {
            utf8::encode($vars->{$k}) if utf8::is_utf8($vars->{$k});
        }
    }
    my $data;
#    binmode( STDOUT, ":utf8" );
    $template->process( $self->filename, $vars, \$data )
      || die "Template process failed: ", $template->error();
    return $data;
}

sub utf8_arrayref {
    my $arrayref = shift;
    foreach my $element (@$arrayref){
        if (ref($element) eq 'ARRAY'){
            utf8_arrayref($element);
            next;
        }
        if (ref($element) eq 'HASH'){
            utf8_hashref($element);
            next;
        }
        utf8::encode($element) if utf8::is_utf8($element);
    }        
}         

sub utf8_hashref {
    my $hashref = shift;
    for my $key (keys %{$hashref}){
        if (ref($hashref->{$key}) eq 'ARRAY'){
            utf8_arrayref($hashref->{$key});
            next;
        }
        if (ref($hashref->{$key}) eq 'HASH'){
            utf8_hashref($hashref->{$key});
            next;
        }
        utf8::encode($hashref->{$key}) if utf8::is_utf8($hashref->{$key});
    }
}
        
        
# FIXME - this is a horrible hack to cache
# the current known-good language, temporarily
# put in place to resolve bug 4403.  It is
# used only by C4::XSLT::XSLTParse4Display;
# the language is set via the usual call
# to themelanguage.
my $_current_language = 'en';

sub _current_language {
    return $_current_language;
}

sub themelanguage {
    my ( $htdocs, $tmpl, $interface ) = @_;
    my $query = new CGI;

    # Set some defaults for language and theme
    # First, check the user's preferences
    my $lang;

    # But, if there's a cookie set, obey it
    $lang = $query->cookie('KohaOpacLanguage')
      if ( defined $query and $query->cookie('KohaOpacLanguage') );

    # Fall back to English
    my @languages;
    if ( $interface eq 'intranet' ) {
        @languages = split ",", C4::Context->preference("language");
    }
    else {
        @languages = split ",", C4::Context->preference("opaclanguages");
    }
    if ($lang) {
        @languages = ( $lang, @languages );
    }
    else {
        $lang = $languages[0] || 'en';
    }
    my $theme = 'prog'; # in the event of theme failure default to 'prog' -fbcit
    my @themes;
    if ( $interface eq "intranet" ) {
        @themes = split " ", C4::Context->preference("template");
    }
    else {
        @themes = split " ", C4::Context->preference("opacthemes");
    }

 # searches through the themes and languages. First template it find it returns.
 # Priority is for getting the theme right.
  THEME:
    foreach my $th (@themes) {
        foreach my $la (@languages) {
            if ( -e "$htdocs/$th/$la/modules/$tmpl" ) {
                $theme = $th;
                $lang  = $la;
                last THEME;
            }
            last unless $la =~ /[-_]/;
        }
    }
    $_current_language = $lang;  # FIXME part of bad hack to paper over bug 4403
    return ( $theme, $lang );
}

# wrapper method to allow easier transition from HTML template pro to Template Toolkit
sub param {
    my $self = shift;
    while (@_) {
        my $key = shift;
        my $val = shift;
        if    ( ref($val) eq 'ARRAY' && !scalar @$val ) { $val = undef; }
        elsif ( ref($val) eq 'HASH'  && !scalar %$val ) { $val = undef; }
        $self->{VARS}->{$key} = $val;
    }
}

1;

