package MoreCustomFields::SelectedEntriesOrPages;

use strict;

use MT 4.2;
use base qw(MT::Plugin);

sub _options_field {
    MoreCustomFields::SelectedObject::options_field({
        type => 'content',
    });
}

# The SelectedEntriesOrPages tag will let you intelligently output the links
# you selected. Use:
# <mt:SelectedEntries basename="selected_content">
#   <mt:If name="__first__">
#     <ul>
#   </mt:If>
#     <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></li>
#   <mt:If name="__last__">
#     </ul>
#   </mt:If>
# </mt:SelectedEntries>
sub tag_selected_content {
    my ( $ctx, $args, $cond ) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if ( !$cf_basename ) {
        return $ctx->error(
            'The SelectedEntriesOrPages block tag requires the basename '
            . 'argument. The basename should be the Selected Content Custom '
            . 'Fields field basename.'
        );
    }

    # Grab the field name with the collected data from above. The basename
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load({
        type     => 'selected_content',
        basename => $cf_basename,
    });
    if ( !$field ) {
        return $ctx->error(
            'A Selected Entries Custom Field with this basename could not be '
            . 'found.'
        );
    }
    my $basename = 'field.' . $field->basename;
    my $obj_type = $field->obj_type;

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type( $ctx,
            $field->obj_type );
    };
    return $ctx->error($@) if $@;

    # Create an array of the entry IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @itemids = split( /,\s?/, $object->$basename );
    my $i       = 0;
    my $vars    = $ctx->{__stash}{vars} ||= {};
    foreach my $itemid (@itemids) {

        # Verify that $itemid is a number. If no Selected Entries are found,
        # it's possible $itemid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid item ID.
        if ( $itemid =~ m/\d+/ ) {

            # Assign the meta vars
            local $vars->{__first__}   = !$i;
            local $vars->{__last__}    = !defined $itemids[ $i + 1 ];
            local $vars->{__odd__}     = ( $i % 2 ) == 0;    # 0-based $i
            local $vars->{__even__}    = ( $i % 2 ) == 1;
            local $vars->{__counter__} = $i + 1;

            # Assign the selected item
            my $item = MT::Entry->load( { id => $itemid, } );
            local $ctx->{__stash}{entry} = $item;

            my $out = $builder->build( $ctx, $tokens );
            if ( !defined $out ) {

                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++;    # Increment for the meta vars.
        }
    }
    return $res;
}

# The popup dialog entry chooser.
sub list_content {
    my $app = shift;
    MoreCustomFields::SelectedObject::list_objects({
        app        => $app,
        blog_id    => $app->param('blog_id'),
        blog_ids   => $app->param('blog_ids') || $app->param('blog_id'),
        type       => 'entries_or_pages',
        edit_field => $app->param('edit_field'),
        search     => $app->param('search') || '',
    });
}

# When searching in the popup entry/page list, both Entries and Pages should
# be searched.
# ... this is not even needed with MT5 -- search works just fine with MT5,
# with no extra effort required.
sub search_api_prep {
    my $terms   = shift;
    my $args    = shift;
    my $blog_id = shift;

    # Arguments need to be specified because using `setup_terms_args` means
    # all of the query needs to be built here. Start with the generic values
    # used to build any search.
    $terms->{blog_id}  = $blog_id;
    $args->{sort}      = 'created_on';
    $args->{direction} = 'descend';

    # If this isn't an MCF-initiated search, exit now. Because the basic terms
    # and arguments were already built above, we can quit now and the search
    # will still execute in the expected manner. But, if this *is* an
    # MCF-initiated search then we can apply the final parameters to get the
    # desired results.
    my $app = MT->instance;
    return unless $app->mode eq 'mcf_list_content';

    # Search the current blog, and search both Entries and Pages for the term.
    $terms->{class}   = '*';
}

1;

__END__
