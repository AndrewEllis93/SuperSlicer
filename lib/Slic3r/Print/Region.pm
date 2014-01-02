package Slic3r::Print::Region;
use Moo;

use Slic3r::Extruder ':roles';
use Slic3r::Flow ':roles';

# A Print::Region object represents a group of volumes to print
# sharing the same config (including the same assigned extruder(s))

has 'print'             => (is => 'ro', required => 1, weak_ref => 1);
has 'config'            => (is => 'ro', default => sub { Slic3r::Config::PrintRegion->new});

sub flow {
    my ($self, $role, $layer_height, $bridge, $first_layer, $width) = @_;
    
    $bridge         //= 0;
    $first_layer    //= 0;
    
    # use the supplied custom width, if any
    my $config_width = $width;
    if (!defined $config_width) {
        # get extrusion width from configuration
        # (might be an absolute value, or a percent value, or zero for auto)
        if ($first_layer && $self->config->first_layer_extrusion_width ne '0') {
            $config_width = $self->config->first_layer_extrusion_width;
        } elsif ($role == FLOW_ROLE_PERIMETER) {
            $config_width = $self->config->perimeter_extrusion_width;
        } elsif ($role == FLOW_ROLE_INFILL) {
            $config_width = $self->config->infill_extrusion_width;
        } elsif ($role == FLOW_ROLE_SOLID_INFILL) {
            $config_width = $self->config->solid_infill_extrusion_width;
        } elsif ($role == FLOW_ROLE_TOP_SOLID_INFILL) {
            $config_width = $self->config->top_infill_extrusion_width;
        } else {
            die "Unknown role $role";
        }
    }
    
    # get the configured nozzle_diameter for the extruder associated
    # to the flow role requested
    my $extruder;  # 1-based
    if ($role == FLOW_ROLE_PERIMETER) {
        $extruder = $self->config->perimeter_extruder;
    } elsif ($role == FLOW_ROLE_INFILL || $role == FLOW_ROLE_SOLID_INFILL || $role == FLOW_ROLE_TOP_SOLID_INFILL) {
        $extruder = $self->config->infill_extruder;
    } else {
        die "Unknown role $role";
    }
    my $nozzle_diameter = $self->print->config->nozzle_diameter->[$extruder-1];
    
    return Slic3r::Flow->new(
        width               => $config_width,
        role                => $role,
        nozzle_diameter     => $nozzle_diameter,
        layer_height        => $layer_height,
        bridge_flow_ratio   => ($bridge ? $self->config->bridge_flow_ratio : 0),
    );
}

1;
