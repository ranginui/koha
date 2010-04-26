package TmplTokenType;

use strict;
#use warnings; FIXME - Bug 2505
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

###############################################################################

=head1 NAME

TmplTokenType.pm - Types of TmplToken objects

=head1 DESCRIPTION

This is a Java-style "safe enum" singleton class for types of TmplToken objects.
The predefined constants are

=cut

###############################################################################

$VERSION = 0.01;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    &TEXT
    &TEXT_PARAMETRIZED
    &CDATA
    &TAG
    &DECL
    &PI
    &DIRECTIVE
    &COMMENT
    &UNKNOWN
);

###############################################################################

use vars qw( $_text $_text_parametrized $_cdata
    $_tag $_decl $_pi $_directive $_comment $_null $_unknown );

BEGIN {
    my $new = sub {
	my $this = 'TmplTokenType';#shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	($self->{'id'}, $self->{'name'}, $self->{'desc'}) = @_;
	return $self;
    };
    $_text		= &$new(0, 'TEXT');
    $_text_parametrized	= &$new(8, 'TEXT-PARAMETRIZED');
    $_cdata		= &$new(1, 'CDATA');
    $_tag		= &$new(2, 'TAG');
    $_decl		= &$new(3, 'DECL');
    $_pi		= &$new(4, 'PI');
    $_directive		= &$new(5, 'DIRECTIVE');
    $_comment		= &$new(6, 'COMMENT');
    $_unknown		= &$new(7, 'UNKNOWN');
}

sub to_string {
    my $this = shift;
    return $this->{'name'}
}

sub TEXT		() { $_text }
sub TEXT_PARAMETRIZED	() { $_text_parametrized }
sub CDATA		() { $_cdata }
sub TAG			() { $_tag }
sub DECL		() { $_decl }
sub PI			() { $_pi }
sub DIRECTIVE		() { $_directive }
sub COMMENT		() { $_comment }
sub UNKNOWN		() { $_unknown }

###############################################################################

=over

=item TEXT

normal text (#text in the DTD)

=item TEXT_PARAMETRIZED

parametrized normal text
(result of simple recognition of text interspersed with <TMPL_VAR> directives;
this has to be explicitly enabled in the scanner)

=item CDATA

normal text (CDATA in the DTD)

=item TAG

something that has the form of an HTML tag

=item DECL

something that has the form of an SGML declaration

=item PI

something that has the form of an SGML processing instruction

=item DIRECTIVE

a HTML::Template directive (whether or not embedded in an SGML comment)

=item COMMENT

something that has the form of an HTML comment
(and is not recognized as an HTML::Template directive)

=item UNKNOWN

something that is not recognized at all by the scanner

=back

Note that end of file is currently represented by undef,
instead of a constant predefined by this module.

=cut

1;
