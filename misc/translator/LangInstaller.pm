package LangInstaller;

use strict;
use warnings;

use C4::Context;
use YAML::Syck qw( Dump LoadFile );
use Locale::PO;


sub set_lang {
    my ($self, $lang) = @_;

    $self->{lang} = $lang;
    $self->{po_path_lang} = $self->{context}->config('intrahtdocs') .
                            "/prog/$lang/modules/admin/preferences";
}


sub new {
    my ($class, $lang, $pref_only) = @_;

    my $self                 = { };

    my $context              = C4::Context->new();
    $self->{context}         = $context;
    $self->{path_pref_en}    = $context->config('intrahtdocs') .
                               '/prog/en/modules/admin/preferences';
    set_lang( $self, $lang ) if $lang;
    $self->{pref_only}       = $pref_only;
    $self->{translator_path} = $context->config('intranetdir') . "/misc/translator";
    $self->{path_po}         = $self->{translator_path} . "/po";
    $self->{po}              = {};

    # Get all .pref file names
    opendir my $fh, $self->{path_pref_en};
    my @pref_files = grep { /.pref/ } readdir($fh);
    close $fh;
    $self->{pref_files} = \@pref_files;

    # Get all available language codes
    opendir $fh, $self->{path_po};
    my @langs =  map { ($_) =~ /(.*)-i-opac/ } 
        grep { $_ =~ /.*-opac-/ } readdir($fh);
    closedir $fh;
    $self->{langs} = \@langs;

    # Map for both interfaces opac/intranet
    $self->{interface} = {
        opac => {
            dir    => $context->config('opachtdocs') . '/prog',
            suffix => '-i-opac-t-prog-v-3002000.po',
        },
        intranet => {
            dir    => $context->config('intrahtdocs') . '/prog',
            suffix => '-i-staff-t-prog-v-3002000.po',
        }
    };

    bless $self, $class;
}


sub po_filename {
    my $self = shift;

    my $context    = C4::Context->new;
    my $trans_path = $context->config('intranetdir') . '/misc/translator/po';
    my $trans_file = "$trans_path/" . $self->{lang} . "-pref.po";
    return $trans_file;
}


sub po_append {
    my ($self, $id, $comment) = @_;
    my $po = $self->{po};
    my $p = $po->{$id};
    if ( $p ) {
        $p->comment( $p->comment . "\n" . $comment );
    }
    else {
        $po->{$id} = Locale::PO->new(
            -comment => $comment,
            -msgid   => $id,
            -msgstr  => ''
        );
    }
}


sub add_prefs {
    my ($self, $comment, $prefs) = @_;

    for my $pref ( @$prefs ) {
        my $pref_name = '';
        for my $element ( @$pref ) {
            if ( ref( $element) eq 'HASH' ) {
                $pref_name = $element->{pref};
                last;
            }
        }
        for my $element ( @$pref ) {
            if ( ref( $element) eq 'HASH' ) {
                while ( my ($key, $value) = each(%$element) ) {
                    next unless $key eq 'choices';
                    next unless ref($value) eq 'HASH';
                    for my $ckey ( keys %$value ) {
                        my $id = $self->{file} . "#$pref_name# " . $value->{$ckey};
                        $self->po_append( $id, $comment );
                    }
                }
            }
            elsif ( $element ) {
                $self->po_append( $self->{file} . "#$pref_name# $element", $comment );
            }
        }
    }
}


sub get_trans_text {
    my ($self, $id) = @_;

    my $po = $self->{po}->{$id};
    return unless $po;
    return Locale::PO->dequote($po->msgstr);
}


sub update_tab_prefs {
    my ($self, $pref, $prefs) = @_;

    for my $p ( @$prefs ) {
        my $pref_name = '';
        next unless $p;
        for my $element ( @$p ) {
            if ( ref( $element) eq 'HASH' ) {
                $pref_name = $element->{pref};
                last;
            }
        }
        for my $i ( 0..@$p-1 ) {
            my $element = $p->[$i];
            if ( ref( $element) eq 'HASH' ) {
                while ( my ($key, $value) = each(%$element) ) {
                    next unless $key eq 'choices';
                    next unless ref($value) eq 'HASH';
                    for my $ckey ( keys %$value ) {
                        my $id = $self->{file} . "#$pref_name# " . $value->{$ckey};
                        my $text = $self->get_trans_text( $id );
                        $value->{$ckey} = $text if $text;
                    }
                }
            }
            elsif ( $element ) {
                my $text = $self->get_trans_text( $self->{file} . "#$pref_name# $element" );
                $p->[$i] = $text if $text;
            }
        }
    }
}


sub get_po_from_prefs {
    my $self = shift;

    for my $file ( @{$self->{pref_files}} ) {
        my $pref = LoadFile( $self->{path_pref_en} . "/$file" );
        $self->{file} = $file;
        #print Dump($pref), "\n";
        while ( my ($tab, $tab_content) = each %$pref ) {
            if ( ref($tab_content) eq 'ARRAY' ) {
                $self->add_prefs( $tab, $tab_content );
                next;
            }
            while ( my ($section, $sysprefs) = each %$tab_content ) {
                my $comment = "$tab > $section";
                $self->po_append( $self->{file} . " " . $section, $comment );
                $self->add_prefs( $comment, $sysprefs );
            }
        }
    }
}


sub save_po {
    my $self = shift;
    # Write .po entries into a file put in Koha standard po directory
    Locale::PO->save_file_fromhash( $self->po_filename, $self->{po} );
    print "Saved in file: ", $self->po_filename, "\n";
}


sub update_prefs {
    my $self = shift;

    print "Update '", $self->{lang}, "' preferences .po file from 'en' .pref files\n";
    # Get po from current 'en' .pref files
    $self->get_po_from_prefs();
    my $po_current = $self->{po};

    # Get po from previous generation
    my $po_previous = Locale::PO->load_file_ashash( $self->po_filename );

    for my $id ( keys %$po_current ) {
        my $po =  $po_previous->{'"'.$id.'"'};
        next unless $po;
        my $text = Locale::PO->dequote( $po->msgstr );
        $po_current->{$id}->msgstr( $text );
    }

    $self->save_po();
}


sub install_prefs {
    my $self = shift;

    unless ( -r $self->{po_path_lang} ) {
        print "Koha directories hierarchy for ", $self->{lang}, " must be created first\n";
        exit;
    }

    # Update the language .po file with last modified 'en' preferences
    # and load it.
    $self->update_prefs();

    for my $file ( @{$self->{pref_files}} ) {
        my $pref = LoadFile( $self->{path_pref_en} . "/$file" );
        $self->{file} = $file;
        while ( my ($tab, $tab_content) = each %$pref ) {
            if ( ref($tab_content) eq 'ARRAY' ) {
                $self->update_tab_prefs( $pref, $tab_content );
                next;
            }
            while ( my ($section, $sysprefs) = each %$tab_content ) {
                $self->update_tab_prefs( $pref, $sysprefs );
            }
            my $ntab = {};
            for my $section ( keys %$tab_content ) {
                my $text = $self->get_trans_text($self->{file} . " $section");
                my $nsection = $text ? $text : $section;
                $ntab->{$nsection} = $tab_content->{$section};
            }
            $pref->{$tab} = $ntab;
        }
        my $file_trans = $self->{po_path_lang} . "/$file";
        print "Write $file\n";
        open my $fh, ">", $file_trans;
        print $fh Dump($pref);
    }
}


sub install_tmpl {
    my $self = shift;

    print
        "Install templates\n";
    while ( my ($interface, $tmpl) = each %{$self->{interface}} ) {
        print
            "  Install templates '$interface\n",
            "    From: $tmpl->{dir}/en/\n",
            "    To  : $tmpl->{dir}/$self->{lang}\n",
            "    With: $self->{path_po}/$self->{lang}$tmpl->{suffix}\n";
        my $lang_dir = "$tmpl->{dir}/$self->{lang}";
        mkdir $lang_dir unless -d $lang_dir;
        system
            "$self->{translator_path}/tmpl_process3.pl install " .
            "-i $tmpl->{dir}/en/ " .
            "-o $tmpl->{dir}/$self->{lang} ".
            "-s $self->{path_po}/$self->{lang}$tmpl->{suffix} -r"
    }
}


sub update_tmpl {
    my $self = shift;

    print
        "Update templates\n";
    while ( my ($interface, $tmpl) = each %{$self->{interface}} ) {
        print
            "  Update templates '$interface'\n",
            "    From: $tmpl->{dir}/en/\n",
            "    To  : $self->{path_po}/$self->{lang}$tmpl->{suffix}\n";
        my $lang_dir = "$tmpl->{dir}/$self->{lang}";
        mkdir $lang_dir unless -d $lang_dir;
        system
            "$self->{translator_path}/tmpl_process3.pl update " .
            "-i $tmpl->{dir}/en/ " .
            "-s $self->{path_po}/$self->{lang}$tmpl->{suffix} -r"
    }
}


sub create_prefs {
    my $self = shift;

    $self->get_po_from_prefs();
    $self->save_po();
}


sub create_tmpl {
    my $self = shift;

    print
        "Create templates\n";
    while ( my ($interface, $tmpl) = each %{$self->{interface}} ) {
        print
            "  Create templates .po files for '$interface'\n",
            "    From: $tmpl->{dir}/en/\n",
            "    To  : $self->{path_po}/$self->{lang}$tmpl->{suffix}\n";
        system
            "$self->{translator_path}/tmpl_process3.pl create " .
            "-i $tmpl->{dir}/en/ " .
            "-s $self->{path_po}/$self->{lang}$tmpl->{suffix} -r"
    }
}


sub install {
    my $self = shift;
    return unless $self->{lang};
    $self->install_tmpl() unless $self->{pref_only};
    $self->install_prefs();
}


sub update {
    my $self = shift;
    return unless $self->{lang};
    $self->update_tmpl() unless $self->{pref_only};
    $self->update_prefs();
}


sub create {
    my $self = shift;
    return unless $self->{lang};
    $self->create_tmpl() unless $self->{pref_only};
    $self->create_prefs();
}



1;


=head1 NAME

LangInstaller.pm - Handle templates and preferences translation

=head1 SYNOPSYS

  my $installer = LangInstaller->new( 'fr-FR' );
  $installer->create();
  $installer->update();
  $installer->install();
  for my $lang ( @{$installer->{langs} ) {
    $installer->set_lang( $lan );
    $installer->install();
  }

=head1 METHODS

=head2 new

Create a new instance of the installer object. 

=head2 create

For the current language, create .po files for templates and preferences based
of the english ('en') version.

=head2 update

For the current language, update .po files.

=head2 install

For the current langage C<$self->{lang}, use .po files to translate the english
version of templates and preferences files and copy those files in the
appropriate directory.

=over

=item translate create F<lang>

Create 3 .po files in F<po> subdirectory: (1) from opac pages templates, (2)
intranet templates, and (3) from preferences.

=over

=item F<lang>-opac.po

Contains extracted text from english (en) OPAC templates found in
<KOHA_ROOT>/koha-tmpl/opac-tmpl/prog/en/ directory.

=item F<lang>-intranet.po

Contains extracted text from english (en) intranet templates found in
<KOHA_ROOT>/koha-tmpl/intranet-tmpl/prog/en/ directory.

=item F<lang>-pref.po

Contains extracted text from english (en) preferences. They are found in files
located in <KOHA_ROOT>/koha-tmpl/intranet-tmpl/prog/en/admin/preferences
directory.

=back

=item pref-trans update F<lang>

Update .po files in F<po> directory, named F<lang>-*.po.

=item pref-trans install F<lang>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Tamil, s.a.r.l.

L<http://www.tamil.fr>

This script is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License, version 2.1.

=cut

