package WormBase::GMapView;

# $Id: GMapView.pm,v 1.1.1.1 2010-01-25 15:36:06 tharris Exp $

=head1 NAME

WormBase::GMapView - WormBase-specific subclass of HTML::GMap

=head1 DESCRIPTION

Panzea-specific subclass of HTML::GMap.

=cut

use warnings;
use strict;

use base qw(HTML::GMap);

sub generate_hires_details_html {
    my ($self, $key_ref) = @_;

    my $data_ref = $key_ref->{rows};

    my $legend_field1 = $self->legend_field1;
    my $legend_field2 = $self->legend_field2;
    my $session       = $self->session;
    my $temp_dir_eq   = $self->temp_dir_eq;

    my @data_points;

    my $total_count = 0;

    foreach my $row_ref (@$data_ref) {
        my $icon_url            = $row_ref->{icon_url};
        my $legend_field1_value = $row_ref->{$legend_field1};
        my $legend_field2_value = $row_ref->{$legend_field2};

        my $name        = $row_ref->{name} || "";
        my $person_id   = $row_ref->{person_id};
        $person_id      =~ s/^Person://;
        my $address     = $row_ref->{address} || "";
        my $papers      = $row_ref->{papers};
        my $supervised  = $row_ref->{supervised};
        
        my @additional_info;
        push @additional_info, "publications: $papers" if $papers;
        push @additional_info, "supervised: $supervised" if $supervised;
        my $additional_info = @additional_info ? "(" . join(", ", @additional_info) . ")" : "";

        my $url = "/db/misc/person?name=$person_id;class=Person";

        my $text = join('<br/>', 
                        qq[<a href="$url" target="_blank"><b>$name</b></a>], 
                        $address, $additional_info);
        push @data_points, [$icon_url, $text];
                                        
        $total_count++;
    }

    my $html;

    $html .= qq[<table>\n];
    $html .= qq[<tr>\n];
    $html .= qq[<th align="left" width="50%">Total Count</th>
                <th align="left">: $total_count</th>\n];
    $html .= qq[</tr>\n];
    $html .= qq[</table>\n];

    $html .= qq[<table>\n];

    foreach my $data_point (@data_points) {
         my $icon_url = $data_point->[0];
         my $text     = $data_point->[1];
         
        $html .= qq[<tr>\n];
        $html .= qq[<td align="left">
                    <img src="$icon_url"/> $text
                    </td>\n];
        $html .= qq[</tr>\n];
    }
    $html .= qq[</table>\n];

    return $html;
}

sub generate_hires_legend_html {
    my ($self, $rows_ref, $type) = @_;

    my $html;

    my $legend_field1 = $self->legend_field1;
    my $legend_field2 = $self->legend_field2;

    my $temp_dir_eq = $self->temp_dir_eq;
    my $session_id  = $self->session_id;

#    my $multiples_icon_url =
#      "$temp_dir_eq/Multiple-icon-$session_id-0-0-0.png";

    my $legend_info;
    my @legend_markers;

    if ($type eq 'hires') {

        $html .= qq[<br/>];
        $html .= qq[<u>Mentor/Student</u>:<br/>];
        $html .= qq[<br/>];
        $html .= qq[<table>];
        $html .= qq[<tr><td><img src="/geo_map/legend_square.png"/></td><td>Mentor</td></tr>];
        $html .= qq[<tr><td><img src="/geo_map/legend_diamond.png"/></td><td>Student</td></tr>];
        $html .= qq[</table>];
        $html .= qq[<br/>];
        $html .= qq[<br/>];
        $html .= qq[<u>Number of publications</u>:<br/>];
        $html .= qq[<br/>];
        $html .= qq[<table>];
        $html .= qq[<tr><td><img src="/geo_map/legend_color_chart_0.png"/></td><td>None</td></tr>];
        $html .= qq[<tr><td><img src="/geo_map/legend_color_chart_1.png"/></td><td>1-5</td></tr>];
        $html .= qq[<tr><td><img src="/geo_map/legend_color_chart_2.png"/></td><td>6-25</td></tr>];
        $html .= qq[<tr><td><img src="/geo_map/legend_color_chart_3.png"/></td><td>26-125</td></tr>];
        $html .= qq[<tr><td><img src="/geo_map/legend_color_chart_4.png"/></td><td>126+</td></tr>];
        $html .= qq[</table>];
        $html .= qq[<br/>];
        $html .= qq[<br/>];
        $html .= qq[<u>Other</u>:<br/>];
        $html .= qq[<br/>];
        $html .= qq[<table>];
        $html .= qq[<tr><td><img src="/geo_map/legend_multiples.png"/> indicates multiple
                    persons mapped to the same coordinate. You can zoom in to display individual icons.</td></tr>];
        $html .= qq[</table>];
        $html .= qq[<br/>];
        }

    else {
        $legend_info = qq[];

        @legend_markers = @$rows_ref;

        $html .= qq[<table>\n];

        $html .= qq[<tr>\n];
        $html .= qq[<td colspan="2">
                    $legend_info<br/>
                    </td>\n];
        $html .= qq[</tr>\n];

        foreach my $legend_marker (@legend_markers) {
            my $icon_url  = $legend_marker->{icon_url};
            my $icon_size = $legend_marker->{icon_size};
            my $text      = $legend_marker->{text};
            $html .= qq[<tr>\n];
            $html .= qq[<td align="left">
                     <img height="$icon_size" src="$icon_url"/> $text
                     </td>\n];
            $html .= qq[</tr>\n];
        }
        $html .= qq[</table>\n];
    }

    return $html;
}
=head1 AUTHOR

Payan Canaran <canaran@cshl.edu>

=head1 BUGS

=head1 VERSION

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

1;

