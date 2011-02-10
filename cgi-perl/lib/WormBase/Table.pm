package WormBase::Table;

our $VERSION = '0.01';

# $Id: Table.pm,v 1.1.1.1 2010-01-25 15:36:06 tharris Exp $

#use warnings;
use strict;

use Carp;
use GD;
use List::Util qw(max);
use Data::Dumper;

###############
# CONSTRUCTOR #
###############

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    my $x_pos = $params{x_pos} || 0;
    $self->x_pos($x_pos);

    my $y_pos = $params{y_pos} || 0;
    $self->y_pos($y_pos);

    my $x_labels = $params{x_labels} || [];
    $self->x_labels($x_labels);

    my $y_labels = $params{y_labels} || [];
    $self->y_labels($y_labels);

    my $x_label_info = $params{x_label_info} || {};
    $self->x_label_info($x_label_info);

    my $y_label_info = $params{y_label_info} || {};
    $self->y_label_info($y_label_info);

    my $cell_side = $params{cell_side} || 20;
    $self->cell_side($cell_side);

    my $image_map_name = $params{image_map_name} || '';
    $self->image_map_name($image_map_name);

    $self->font(gdMediumBoldFont);

    my $data_content = $params{data_content} || {};
    $self->data_content($data_content);

    my $data_info = $params{data_info} || {};
    $self->data_info($data_info);

    # Rotate if necessary
    my $rotate = $params{rotate} || 0;
    if ($rotate) {
        my $rotated_data_content = {};
        foreach my $x_label (keys %{$data_content}) {
            foreach my $y_label (keys %{$data_content->{$x_label}}) {
                $rotated_data_content->{$y_label}->{$x_label} =
                  $data_content->{$x_label}->{$y_label};
            }
        }

        my $rotated_data_info = {};
        foreach my $x_label (keys %{$data_info}) {
            foreach my $y_label (keys %{$data_info->{$x_label}}) {
                $rotated_data_info->{$y_label}->{$x_label} =
                  $data_info->{$x_label}->{$y_label};
            }
        }

        $self->x_pos($y_pos);
        $self->y_pos($x_pos);
        $self->x_labels($y_labels);
        $self->y_labels($x_labels);
        $self->x_label_info($y_label_info);
        $self->y_label_info($x_label_info);
        $self->data_content($rotated_data_content);
        $self->data_info($rotated_data_info);
    }

    return $self;
}

##################
# PUBLIC METHODS #
##################

sub render_image {
    my ($self, $file) = @_;

    croak("A file name is required!") unless $file;

    if (!$self->image_map) {
        my ($image_map_name) = $file =~ /([^\/]+)$/;
        $self->image_map_name($image_map_name);
    }

    $self->_render_table unless $self->image;

    my $image = $self->image;

    open(PNG, ">$file") or croak("Cannot write file ($file): $!");
    binmode PNG;

    print PNG $image->png;

    return 1;
}

sub render_image_map {
    my ($self) = @_;

    $self->_render_table unless $self->image_map;

    my $image_map      = $self->image_map;
    my $image_map_name = $self->image_map_name;

    my @x_labels = @{$self->x_labels};
    my @y_labels = @{$self->y_labels};

    my %x_label_index = map { $x_labels[$_] => $_ } (0 .. $#x_labels);
    my %y_label_index = map { $y_labels[$_] => $_ } (0 .. $#y_labels);

    my $x_label_info = $self->x_label_info;
    my $y_label_info = $self->y_label_info;
    my $data_info    = $self->data_info;

    my $html = qq[<map name="$image_map_name">\n];

    foreach my $x_label (keys %{$image_map->{x_label}}) {
        next unless exists $x_label_index{$x_label};
        my $info = $x_label_info->{$x_label};
        $html .=
            qq[<area shape="rect" coords="]
          . join(',', @{$image_map->{x_label}->{$x_label}})
          . qq[" $info>\n]
          if $info;
    }

    foreach my $y_label (keys %{$image_map->{y_label}}) {
        next unless exists $y_label_index{$y_label};
        my $info = $y_label_info->{$y_label};
        $html .=
            qq[<area shape="rect" coords="]
          . join(',', @{$image_map->{y_label}->{$y_label}})
          . qq[" $info>\n]
          if $info;
    }

    foreach my $x_label (keys %{$data_info}) {
        next unless exists $x_label_index{$x_label};
        foreach my $y_label (keys %{$data_info->{$x_label}}) {
            next unless exists $y_label_index{$y_label};
            my $info   = $data_info->{$x_label}->{$y_label};
            my @coords = @{$image_map->{content}->{$x_label}->{$y_label}};
            $html .=
                qq[<area shape="rect" coords="]
              . join(',', @coords)
              . qq[" $info">\n];
        }
    }
    $html .= qq[</map>\n];

    return $html;
}

sub render_html {
    my ($self) = @_;

    my @x_labels = @{$self->x_labels};
    my @y_labels = @{$self->y_labels};

    my %x_label_index = map { $x_labels[$_] => $_ } (0 .. $#x_labels);
    my %y_label_index = map { $y_labels[$_] => $_ } (0 .. $#y_labels);

    my $x_label_info = $self->x_label_info;
    my $y_label_info = $self->y_label_info;
    my $data_content = $self->data_content;
    my $data_info    = $self->data_info;

    # Start html
    my $html = qq[<table class="interaction_matrix">\n];

    # Add label
    my @x_label_pieces =
      map { $x_label_info->{$_} ? "<a $x_label_info->{$_}>$_</a>" : $_ }
      @{$self->x_labels};
    $html .= '<tr><td>'
      . join('</td><td class="header">', '', @x_label_pieces)
      . '</td></tr>' . "\n";

    # Add data
    foreach my $y_label (@{$self->y_labels}) {
        my $y_label_piece =
          $y_label_info->{$y_label}
          ? "<a $y_label_info->{$y_label}>$y_label</a>"
          : $y_label;
        my @value_pieces;
        foreach my $x_label (@{$self->x_labels}) {
            my $content = $data_content->{$x_label}->{$y_label};
            my $info    = $data_info->{$x_label}->{$y_label};
            push @value_pieces, $info ? "<a $info>$content</a>" : $content;
        }
        $html .=
            qq[<tr><td class="header">$y_label_piece</td><td>]
          . join('</td><td>', @value_pieces)
          . '</td></tr>' . "\n";
    }

    $html .= qq[</table>\n];

    return $html;
}

###################
# PRIVATE METHODS #
###################

sub _render_table {
    my ($self) = @_;

    my $x_pos = $self->x_pos;
    my $y_pos = $self->y_pos;

    my @x_labels = @{$self->x_labels};
    my @y_labels = @{$self->y_labels};

    my %x_label_index = map { $x_labels[$_] => $_ } (0 .. $#x_labels);
    my %y_label_index = map { $y_labels[$_] => $_ } (0 .. $#y_labels);

    my $data_content = $self->data_content;
    my $data_info    = $self->data_info;

    my $cell_side = $self->cell_side;
    my $font      = $self->font;

    my $x_label_width = max(map { length($_) } @x_labels);
    my $y_label_width = max(map { length($_) } @y_labels);

    my $x_label_area = $x_label_width * $font->width + 4;
    my $y_label_area = $y_label_width * $font->width + 4;

    my $label_corr = ($cell_side - $font->height) / 2;

    my $image_width  = $y_label_area + @x_labels * $cell_side + 4;
    my $image_height = $x_label_area + @y_labels * $cell_side + 4;

    my $image = GD::Image->new($image_width, $image_height);

    my $white = $image->colorAllocate(255, 255, 255);
    my $black = $image->colorAllocate(0,   0,   0);
    my $red   = $image->colorAllocate(255, 0,   0);
    my $blue  = $image->colorAllocate(0,   0,   255);

    # Keep track of image map
    my $image_map = {};

    # Draw horizontal lines & labels
    foreach my $i (0 .. @y_labels - 1) {
        my $y_label = $y_labels[$i];
        $image->string(
            $font,    2, $x_label_area + $i * $cell_side + $label_corr,
            $y_label, $black
        );

        $image_map->{y_label}->{$y_label} = [
            2,
            int($x_label_area + $i * $cell_side + $label_corr),
            int(2 + length($y_label) * $font->width),
            int($x_label_area + ($i + 1) * $cell_side - $label_corr),
        ];

        $image->line(
            $y_label_area, $x_label_area + $i * $cell_side,
            $y_label_area + @x_labels * $cell_side,
            $x_label_area + $i * $cell_side, $black
        );
    }

    $image->line(
        $y_label_area, $x_label_area + @y_labels * $cell_side,
        $y_label_area + @x_labels * $cell_side,
        $x_label_area + @y_labels * $cell_side, $black
    );

    # Draw vertical lines & labels
    foreach my $i (0 .. @x_labels - 1) {
        my $x_label = $x_labels[$i];
        $image->stringUp(
            $font, $y_label_area + $i * $cell_side + $label_corr,
            $x_label_area - 2, $x_label, $black
        );

        $image_map->{x_label}->{$x_label} = [
            int($y_label_area + $i * $cell_side + $label_corr),
            int($x_label_area - 2),
            int($y_label_area + $i * $cell_side + $font->height),
            2,
        ];

        $image->line(
            $y_label_area + $i * $cell_side, $x_label_area,
            $y_label_area + $i * $cell_side,
            $x_label_area + @y_labels * $cell_side, $black
        );
    }

    $image->line(
        $y_label_area + @x_labels * $cell_side, $x_label_area,
        $y_label_area + @x_labels * $cell_side,
        $x_label_area + @y_labels * $cell_side, $black
    );

    # Draw data points
    foreach my $x_label (keys %{$data_content}) {
        next unless exists $x_label_index{$x_label};

        foreach my $y_label (keys %{$data_content->{$x_label}}) {
            next unless exists $y_label_index{$y_label};

            my $x_index = $x_label_index{$x_label};
            my $y_index = $y_label_index{$y_label};

            my $content = $data_content->{$x_label}->{$y_label};

            my $x_center =
              $x_label_area + $y_index * $cell_side + $cell_side / 2;
            my $y_center =
              $y_label_area + $x_index * $cell_side + $cell_side / 2;

            $image->string(
                $font,
                int($y_center - length($content) * $font->width / 2),
                int($x_center - $font->height / 2),
                $content, $red
            );

            $image_map->{content}->{$x_label}->{$y_label} = [
                int($y_center - length($content) * $font->width / 2),
                int($x_center - $font->height / 2),
                int($y_center + length($content) * $font->width / 2),
                int($x_center + $font->height / 2),
            ];

        }
    }

    $self->image($image);
    $self->image_map($image_map);

    return 1;
}

###################
# GET/SET METHODS #
###################

sub cell_side {
    my ($self, $value) = @_;
    $self->{cell_side} = $value if @_ > 1;
    return $self->{cell_side};
}

sub data_content {
    my ($self, $value) = @_;
    $self->{data_content} = $value if @_ > 1;
    return $self->{data_content};
}

sub data_info {
    my ($self, $value) = @_;
    $self->{data_info} = $value if @_ > 1;
    return $self->{data_info};
}

sub font {
    my ($self, $value) = @_;
    $self->{font} = $value if @_ > 1;
    return $self->{font};
}

sub image {
    my ($self, $value) = @_;
    $self->{image} = $value if @_ > 1;
    return $self->{image};
}

sub image_map {
    my ($self, $value) = @_;
    $self->{image_map} = $value if @_ > 1;
    return $self->{image_map};
}

sub image_map_name {
    my ($self, $value) = @_;
    $self->{image_map_name} = $value if @_ > 1;
    return $self->{image_map_name};
}

sub rotate {
    my ($self, $value) = @_;
    $self->{rotate} = $value if @_ > 1;
    return $self->{rotate};
}

sub x_label_info {
    my ($self, $value) = @_;
    $self->{x_label_info} = $value if @_ > 1;
    return $self->{x_label_info};
}

sub x_labels {
    my ($self, $value) = @_;
    $self->{x_labels} = $value if @_ > 1;
    return $self->{x_labels};
}

sub x_pos {
    my ($self, $value) = @_;
    $self->{x_pos} = $value if @_ > 1;
    return $self->{x_pos};
}

sub y_label_info {
    my ($self, $value) = @_;
    $self->{y_label_info} = $value if @_ > 1;
    return $self->{y_label_info};
}

sub y_labels {
    my ($self, $value) = @_;
    $self->{y_labels} = $value if @_ > 1;
    return $self->{y_labels};
}

sub y_pos {
    my ($self, $value) = @_;
    $self->{y_pos} = $value if @_ > 1;
    return $self->{y_pos};
}

1;

__END__

=head1 NAME

WormBase::Table - Utility for generating a png or html table matrix 

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 USAGE

=head1 QUICK REFERENCE

...

=head1 AUTHOR

Payan Canaran <canaran@cshl.edu>

=head1 BUGS

=head1 VERSION

Version 0.01

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut
