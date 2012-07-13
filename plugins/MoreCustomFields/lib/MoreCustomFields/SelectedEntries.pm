package MoreCustomFields::SelectedEntries;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);
use MoreCustomFields::SelectedObject;

sub _options_field {
    MoreCustomFields::SelectedObject::options_field({
        type => 'entries',
    });
}

# The SelectedEntries tag will let you intelligently output the links you
# selected. Use:
# <mt:SelectedEntries basename="selected_entries">
#   <mt:If name="__first__">
#     <ul>
#   </mt:If>
#     <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></li>
#   <mt:If name="__last__">
#     </ul>
#   </mt:If>
# </mt:SelectedEntries>
sub tag_selected_entries {
    my ($ctx, $args, $cond) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error(
            'The SelectedEntries block tag requires the basename argument. '
            . 'The basename should be the Selected Entries Custom Fields '
            . 'field basename.'
        );
    }

    # Grab the field name with the collected data from above. The basename
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load( { type     => 'selected_entries',
                                             basename => $cf_basename, } );
    if (!$field) { 
        return $ctx->error(
            'A Selected Entries Custom Field with this basename could not be '
            . 'found.'
        );
    }

    my $basename = 'field.'.$field->basename;

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type(
            $ctx, $field->obj_type
        )
    };
    return $ctx->error($@) if $@;

    # Create an array of the entry IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @entryids = split(/,\s?/, $object->$basename)
      if ($object && $object->$basename);
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    foreach my $entryid (@entryids) {
        # Verify that $entryid is a number. If no Selected Entries are found,
        # it's possible $entryid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid entry ID.
        if ($entryid =~ m/\d+/) {
            # Assign the meta vars
            local $vars->{__first__} = !$i;
            local $vars->{__last__} = !defined $entryids[$i + 1];
            local $vars->{__odd__} = ($i % 2) == 0; # 0-based $i
            local $vars->{__even__} = ($i % 2) == 1;
            local $vars->{__counter__} = $i + 1;
            # Assign the selected entry
            my $entry = MT::Entry->load( { id => $entryid, } );
            local $ctx->{__stash}{entry} = $entry;

            my $out = $builder->build($ctx, $tokens);
            if (!defined $out) {
                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++; # Increment for the meta vars.
        }
    }
    return $res;
}

# The popup dialog entry chooser.
sub list_entries {
    my $app = shift;
    MoreCustomFields::SelectedObject::list_objects({
        app        => $app,
        blog_id    => $app->param('blog_id'),
        blog_ids   => $app->param('blog_ids'),
        type       => 'entry',
        edit_field => $app->param('edit_field'),
        search     => $app->param('search') || '',
    });
}

1;

__END__
